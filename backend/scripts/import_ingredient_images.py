from __future__ import annotations

import argparse
import csv
import json
import sys
import time
from collections import defaultdict
from pathlib import Path
from typing import Any

from sqlalchemy import text


# =============================================================
# PATHS
# =============================================================

BACKEND_ROOT = Path(__file__).resolve().parent.parent

if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))


# =============================================================
# PROJECT IMPORTS
# =============================================================

from app.core.config import settings
from app.dependencies.database import SessionLocal

from scripts.ingredient_image_config import IMPORT_LIMIT
from scripts.ingredient_image_downloader import (
    IngredientImageDownloadRateLimitError,
    IngredientImageDownloader,
)
from scripts.ingredient_image_name import get_visual_ingredient_name
from scripts.image_providers.ingredient_pexels import (
    IngredientPexelsProvider,
    PexelsRateLimitError,
)
from scripts.image_providers.ingredient_wikimedia import (
    IngredientWikimediaProvider,
    WikimediaRateLimitError,
)


# =============================================================
# DATA DIRECTORIES
# =============================================================

DATA_DIR = BACKEND_ROOT / "data"
REPORT_DIR = DATA_DIR / "image_reports"
CACHE_DIR = DATA_DIR / "image_cache"

REPORT_DIR.mkdir(parents=True, exist_ok=True)
CACHE_DIR.mkdir(parents=True, exist_ok=True)


# =============================================================
# FILES
# =============================================================

CACHE_FILE = CACHE_DIR / "ingredient_image_cache.json"
REPORT_FILE = REPORT_DIR / "ingredient_image_import_report.csv"


# =============================================================
# CACHE STATUSES
# =============================================================

CACHE_SUCCESS = "SUCCESS"
CACHE_NO_IMAGE = "NO_IMAGE"
CACHE_RETRY = "RETRY"


# =============================================================
# DATABASE SETTINGS
# =============================================================

DATABASE_PAGE_SIZE = 500


# =============================================================
# PROVIDER SETTINGS
# =============================================================

DEFAULT_PROVIDER_COOLDOWN_SECONDS = 60.0
MAX_PROVIDER_COOLDOWN_SECONDS = 300.0

# When all providers are cooling down, wait only up to this amount
# before checking again. This prevents busy looping.
MAX_WAIT_SECONDS = 60.0


# =============================================================
# CACHE
# =============================================================

def load_cache() -> dict[str, dict[str, Any]]:
    """Load the persistent canonical ingredient image cache."""

    if not CACHE_FILE.exists():
        return {}

    try:
        with CACHE_FILE.open("r", encoding="utf-8") as file:
            data = json.load(file)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"WARNING: cache could not be loaded: {exc}")
        return {}

    if not isinstance(data, dict):
        print("WARNING: invalid cache structure.")
        return {}

    return data


def save_cache(cache: dict[str, dict[str, Any]]) -> None:
    """Atomically save the cache."""

    temporary_file = CACHE_FILE.with_suffix(".tmp")

    with temporary_file.open("w", encoding="utf-8") as file:
        json.dump(
            cache,
            file,
            indent=2,
            ensure_ascii=False,
            sort_keys=True,
        )

    temporary_file.replace(CACHE_FILE)


# =============================================================
# DATABASE LOAD
# =============================================================

def load_ingredients(
    db,
    limit: int,
    force: bool,
    cache: dict[str, dict[str, Any]],
    retry_no_image: bool,
) -> list[dict[str, Any]]:
    """Load database ingredients eligible for processing."""

    selected: list[dict[str, Any]] = []
    offset = 0

    while len(selected) < limit:
        if force:
            query = text(
                """
                SELECT
                    id,
                    name,
                    image_url
                FROM ingredients
                ORDER BY name
                OFFSET :offset
                LIMIT :page_size
                """
            )
        else:
            query = text(
                """
                SELECT
                    id,
                    name,
                    image_url
                FROM ingredients
                WHERE image_url IS NULL
                ORDER BY name
                OFFSET :offset
                LIMIT :page_size
                """
            )

        rows = (
            db.execute(
                query,
                {
                    "offset": offset,
                    "page_size": DATABASE_PAGE_SIZE,
                },
            )
            .mappings()
            .all()
        )

        if not rows:
            break

        offset += len(rows)

        for row in rows:
            ingredient = dict(row)
            visual_name = get_visual_ingredient_name(
                ingredient["name"]
            )

            if (
                visual_name
                and not force
            ):
                cached = cache.get(visual_name)

                if (
                    cached
                    and cached.get("status") == CACHE_NO_IMAGE
                    and not retry_no_image
                ):
                    continue

            selected.append(ingredient)

            if len(selected) >= limit:
                break

        if len(rows) < DATABASE_PAGE_SIZE:
            break

    return selected


# =============================================================
# DATABASE UPDATE
# =============================================================

def update_image_url(
    db,
    ingredient_id,
    image_url: str,
) -> None:
    """Update one ingredient row with its local image path."""

    db.execute(
        text(
            """
            UPDATE ingredients
            SET
                image_url = :image_url,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = :ingredient_id
            """
        ),
        {
            "ingredient_id": ingredient_id,
            "image_url": image_url,
        },
    )


# =============================================================
# REPORT
# =============================================================

def write_report(rows: list[dict[str, Any]]) -> None:
    """Write the current CSV report."""

    with REPORT_FILE.open(
        "w",
        encoding="utf-8",
        newline="",
    ) as file:
        writer = csv.DictWriter(
            file,
            fieldnames=[
                "ingredient_id",
                "ingredient_name",
                "visual_name",
                "status",
                "image_url",
                "source",
                "error",
            ],
        )

        writer.writeheader()
        writer.writerows(rows)


# =============================================================
# LOCAL CACHE FILE
# =============================================================

def cached_file_exists(relative_image_path: str) -> bool:
    """Check whether a cached local image file exists."""

    if not relative_image_path:
        return False

    return (
        BACKEND_ROOT / "media" / relative_image_path
    ).is_file()


# =============================================================
# RATE-LIMIT HELPERS
# =============================================================

def parse_retry_after(
    message: str,
    default: float = DEFAULT_PROVIDER_COOLDOWN_SECONDS,
) -> float:
    """
    Parse Retry-After seconds from a provider exception message.

    Falls back safely when the exception does not contain a numeric
    Retry-After value.
    """

    if not message:
        return default

    marker = "Retry-After:"

    if marker not in message:
        return default

    raw_value = (
        message.split(
            marker,
            1,
        )[1]
        .strip()
        .split()[0]
    )

    try:
        seconds = float(raw_value)
    except (TypeError, ValueError):
        return default

    if seconds <= 0:
        return default

    return min(
        seconds,
        MAX_PROVIDER_COOLDOWN_SECONDS,
    )


def set_provider_cooldown(
    provider_cooldowns: dict[str, float],
    source: str,
    exception: Exception,
) -> float:
    """Set a provider cooldown and return its duration."""

    seconds = parse_retry_after(
        str(exception)
    )

    provider_cooldowns[source] = (
        time.monotonic() + seconds
    )

    return seconds


def provider_is_available(
    provider_cooldowns: dict[str, float],
    source: str,
) -> bool:
    """Return whether a provider's cooldown has expired."""

    return (
        time.monotonic()
        >= provider_cooldowns.get(
            source,
            0.0,
        )
    )


def wait_for_provider_if_needed(
    providers: list[tuple[str, Any]],
    provider_cooldowns: dict[str, float],
) -> None:
    """
    When every provider is cooling down, wait until the earliest
    provider becomes available.

    This avoids falsely reporting NO_IMAGE just because providers
    were temporarily rate-limited.
    """

    available = [
        source
        for source, _provider in providers
        if provider_is_available(
            provider_cooldowns,
            source,
        )
    ]

    if available:
        return

    now = time.monotonic()

    remaining = [
        cooldown - now
        for cooldown in provider_cooldowns.values()
        if cooldown > now
    ]

    if not remaining:
        return

    wait_seconds = min(
        min(remaining),
        MAX_WAIT_SECONDS,
    )

    print(
        "  All providers are temporarily "
        "rate-limited."
    )
    print(
        f"  Waiting {wait_seconds:.1f} seconds..."
    )

    time.sleep(wait_seconds)


# =============================================================
# PROVIDER SEARCH
# =============================================================

def search_with_providers(
    visual_name: str,
    providers: list[tuple[str, Any]],
    provider_cooldowns: dict[str, float],
) -> tuple[Any | None, str, str, str]:
    """
    Search providers in order.

    A 429 disables only that provider until its cooldown expires.
    A rate-limited result becomes RETRY, never NO_IMAGE.

    If all providers are temporarily unavailable, wait for the
    earliest cooldown and retry the same ingredient.
    """

    while True:
        tried_available_provider = False
        errors: list[str] = []
        rate_limited = False

        for source, provider in providers:
            provider_name = provider.__class__.__name__

            if not provider_is_available(
                provider_cooldowns,
                source,
            ):
                remaining = (
                    provider_cooldowns[source]
                    - time.monotonic()
                )

                print(
                    f"  Skipping {provider_name}: "
                    f"cooldown {remaining:.1f}s remaining."
                )

                continue

            tried_available_provider = True

            print(
                f"  Searching {source.title()} "
                f"for: {visual_name}"
            )

            try:
                result = provider.search(
                    visual_name
                )

            except (
                PexelsRateLimitError,
                WikimediaRateLimitError,
            ) as exc:
                cooldown = set_provider_cooldown(
                    provider_cooldowns,
                    source,
                    exc,
                )

                print(
                    f"  {provider_name} rate limited."
                )
                print(
                    f"  {source.title()} cooldown: "
                    f"{cooldown:.1f}s"
                )

                rate_limited = True
                errors.append(
                    f"{source}: {exc}"
                )

                continue

            except Exception as exc:
                print(
                    f"  {provider_name} failed: "
                    f"{exc}"
                )

                errors.append(
                    f"{source}: {exc}"
                )

                continue

            if result is not None:
                print(
                    f"  {provider_name} found "
                    "a suitable image."
                )

                return (
                    result,
                    source,
                    "",
                    "SUCCESS",
                )

            print(
                f"  {provider_name}: "
                "no suitable image."
            )

        # -----------------------------------------------------
        # Both/all providers are temporarily unavailable.
        # -----------------------------------------------------

        if rate_limited:
            wait_for_provider_if_needed(
                providers,
                provider_cooldowns,
            )

            # Re-check. If at least one provider becomes available,
            # retry the same ingredient.
            if any(
                provider_is_available(
                    provider_cooldowns,
                    source,
                )
                for source, _provider in providers
            ):
                print(
                    "  Retrying providers after cooldown."
                )
                continue

        # -----------------------------------------------------
        # No provider was available to make a valid conclusion.
        # -----------------------------------------------------

        if not tried_available_provider and any(
            provider_is_available(
                provider_cooldowns,
                source,
            )
            for source, _provider in providers
        ):
            continue

        if errors:
            return (
                None,
                "",
                " | ".join(errors),
                "PROVIDER_ERROR",
            )

        return (
            None,
            "",
            "",
            "NO_IMAGE",
        )


# =============================================================
# PROCESS ONE VISUAL GROUP
# =============================================================

def process_visual_name(
    visual_name: str,
    representative_id,
    providers: list[tuple[str, Any]],
    provider_cooldowns: dict[str, float],
    downloader: IngredientImageDownloader,
    cache: dict[str, dict[str, Any]],
    retry_no_image: bool = False,
) -> tuple[str, str, str, str]:
    """Resolve one canonical visual ingredient."""

    cached = cache.get(visual_name)

    # =========================================================
    # SUCCESS CACHE
    # =========================================================

    if cached:
        cached_status = cached.get("status")
        cached_path = cached.get("image_url", "")
        cached_source = cached.get("source", "cache")
        cached_error = cached.get("error", "")

        if (
            cached_status == CACHE_SUCCESS
            and cached_path
            and cached_file_exists(cached_path)
        ):
            print(
                f"  CACHE HIT: {visual_name}"
            )

            return (
                "CACHE_HIT",
                cached_path,
                cached_source,
                "",
            )

        if (
            cached_status == CACHE_SUCCESS
            and not cached_file_exists(cached_path)
        ):
            print(
                "  Removing stale cache: "
                f"{visual_name}"
            )
            cache.pop(
                visual_name,
                None,
            )

        elif (
            cached_status == CACHE_NO_IMAGE
            and not retry_no_image
        ):
            print(
                f"  CACHE HIT: {visual_name}"
            )
            print(
                "  Previously resolved as "
                "NO_IMAGE."
            )

            return (
                "NO_IMAGE",
                "",
                cached_source,
                cached_error or (
                    "No acceptable image found."
                ),
            )

        elif cached_status == CACHE_RETRY:
            print(
                "  Retrying previous failure: "
                f"{visual_name}"
            )

    # =========================================================
    # PROVIDERS
    # =========================================================

    (
        result,
        source,
        provider_error,
        search_status,
    ) = search_with_providers(
        visual_name=visual_name,
        providers=providers,
        provider_cooldowns=provider_cooldowns,
    )

    # =========================================================
    # NO RESULT
    # =========================================================

    if result is None:
        if search_status in {
            "RETRY",
            "PROVIDER_ERROR",
        }:
            error = (
                provider_error
                or "Provider temporarily unavailable."
            )

            print(
                "  Provider failure recorded as RETRY."
            )

            cache[visual_name] = {
                "status": CACHE_RETRY,
                "image_url": "",
                "source": source or "provider",
                "error": error,
            }

            save_cache(cache)

            return (
                CACHE_RETRY,
                "",
                source or "provider",
                error,
            )

        error = (
            "No acceptable image found."
        )

        print(
            "  No acceptable image."
        )

        cache[visual_name] = {
            "status": CACHE_NO_IMAGE,
            "image_url": "",
            "source": "none",
            "error": error,
        }

        save_cache(cache)

        return (
            CACHE_NO_IMAGE,
            "",
            "none",
            error,
        )

    # =========================================================
    # DOWNLOAD
    # =========================================================

    print(
        f"  Downloading: {visual_name}"
    )
    print(
        f"  Source: {source}"
    )

    try:
        local_path = downloader.download(
            ingredient_id=str(representative_id),
            image_url=result.url,
            mime_type=result.mime_type,
            canonical_name=visual_name,
        )

    except IngredientImageDownloadRateLimitError as exc:
        error = str(exc)

        print(
            "  Image downloader rate-limited."
        )

        cache[visual_name] = {
            "status": CACHE_RETRY,
            "image_url": "",
            "source": source,
            "error": error,
        }

        save_cache(cache)

        raise

    except Exception as exc:
        error = str(exc)

        print(
            f"  Download failed: {error}"
        )

        cache[visual_name] = {
            "status": CACHE_RETRY,
            "image_url": "",
            "source": source,
            "error": error,
        }

        save_cache(cache)

        return (
            "DOWNLOAD_FAILED",
            "",
            source,
            error,
        )

    if not local_path:
        error = (
            "Downloader returned no path."
        )

        print(
            f"  {error}"
        )

        cache[visual_name] = {
            "status": CACHE_RETRY,
            "image_url": "",
            "source": source,
            "error": error,
        }

        save_cache(cache)

        return (
            "DOWNLOAD_FAILED",
            "",
            source,
            error,
        )

    # =========================================================
    # SUCCESS
    # =========================================================

    cache[visual_name] = {
        "status": CACHE_SUCCESS,
        "image_url": local_path,
        "source": source,
        "error": "",
    }

    save_cache(cache)

    print(
        "  Canonical image saved: "
        f"{local_path}"
    )

    return (
        "SUCCESS",
        local_path,
        source,
        "",
    )


# =============================================================
# MAIN
# =============================================================

def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Import ingredient images using Pexels first "
            "and Wikimedia fallback."
        )
    )

    parser.add_argument(
        "--limit",
        type=int,
        default=IMPORT_LIMIT,
    )

    parser.add_argument(
        "--force",
        action="store_true",
        help=(
            "Process rows even when image_url exists."
        ),
    )

    parser.add_argument(
        "--retry-no-image",
        action="store_true",
        help=(
            "Retry ingredients previously cached "
            "as NO_IMAGE."
        ),
    )

    args = parser.parse_args()

    if args.limit <= 0:
        raise ValueError(
            "--limit must be greater than zero."
        )

    print()
    print("=" * 80)
    print(
        "RasaBavarchi - INGREDIENT IMAGE IMPORT"
    )
    print("=" * 80)
    print()

    print(
        f"LIMIT: {args.limit}"
    )
    print(
        "FORCE: "
        + ("YES" if args.force else "NO")
    )
    print(
        "RETRY NO IMAGE: "
        + (
            "YES"
            if args.retry_no_image
            else "NO"
        )
    )
    print(
        f"CACHE: {CACHE_FILE}"
    )
    print(
        "PROVIDERS: Pexels -> Wikimedia"
    )
    print()

    db = SessionLocal()

    providers = [
        (
            "pexels",
            IngredientPexelsProvider(
                settings.pexels_api_key
            ),
        ),
        (
            "wikimedia",
            IngredientWikimediaProvider(),
        ),
    ]

    provider_cooldowns: dict[str, float] = {}

    downloader = IngredientImageDownloader()
    cache = load_cache()
    report_rows: list[dict[str, Any]] = []

    processed = 0
    successful = 0
    cache_hits = 0
    no_image = 0
    retry_count = 0
    download_failed = 0
    provider_failed = 0
    skipped = 0

    try:
        ingredients = load_ingredients(
            db=db,
            limit=args.limit,
            force=args.force,
            cache=cache,
            retry_no_image=args.retry_no_image,
        )

        print(
            f"Ingredients selected: "
            f"{len(ingredients)}"
        )
        print()

        if not ingredients:
            print(
                "No ingredients require image import."
            )
            return

        grouped: dict[
            str,
            list[dict[str, Any]],
        ] = defaultdict(list)

        for ingredient in ingredients:
            visual_name = get_visual_ingredient_name(
                ingredient["name"]
            )

            if visual_name:
                grouped[visual_name].append(
                    ingredient
                )
            else:
                grouped[
                    "__EMPTY_VISUAL_NAME__"
                ].append(ingredient)

        print(
            "Database rows    : "
            f"{len(ingredients)}"
        )
        print(
            "Visual groups    : "
            f"{len(grouped)}"
        )
        print(
            "Duplicate savings: "
            f"{len(ingredients) - len(grouped)}"
        )
        print()

        group_number = 0

        for visual_name, group in grouped.items():
            group_number += 1

            # -------------------------------------------------
            # No canonical name
            # -------------------------------------------------

            if visual_name == "__EMPTY_VISUAL_NAME__":
                for ingredient in group:
                    processed += 1
                    no_image += 1

                    report_rows.append(
                        {
                            "ingredient_id": str(
                                ingredient["id"]
                            ),
                            "ingredient_name": (
                                ingredient["name"]
                            ),
                            "visual_name": "",
                            "status": "NO_VISUAL_NAME",
                            "image_url": "",
                            "source": "",
                            "error": (
                                "Visual name resolver "
                                "returned empty value."
                            ),
                        }
                    )

                continue

            representative = group[0]

            print()
            print("=" * 80)
            print(
                f"GROUP "
                f"[{group_number}/{len(grouped)}]"
            )
            print(
                f"Visual name : {visual_name}"
            )
            print(
                f"DB variants : {len(group)}"
            )

            for item in group:
                print(
                    f"  - {item['name']}"
                )

            print("=" * 80)

            (
                status,
                local_path,
                source,
                error,
            ) = process_visual_name(
                visual_name=visual_name,
                representative_id=(
                    representative["id"]
                ),
                providers=providers,
                provider_cooldowns=(
                    provider_cooldowns
                ),
                downloader=downloader,
                cache=cache,
                retry_no_image=(
                    args.retry_no_image
                ),
            )

            # -------------------------------------------------
            # No image
            # -------------------------------------------------

            if not local_path:
                for ingredient in group:
                    processed += 1

                    if status == CACHE_RETRY:
                        retry_count += 1

                    elif status == "DOWNLOAD_FAILED":
                        download_failed += 1

                    elif status == "NO_IMAGE":
                        no_image += 1

                    elif status == "PROVIDER_ERROR":
                        provider_failed += 1

                    else:
                        skipped += 1

                    report_rows.append(
                        {
                            "ingredient_id": str(
                                ingredient["id"]
                            ),
                            "ingredient_name": (
                                ingredient["name"]
                            ),
                            "visual_name": (
                                visual_name
                            ),
                            "status": status,
                            "image_url": "",
                            "source": source,
                            "error": error,
                        }
                    )

                continue

            # -------------------------------------------------
            # Apply image to every DB variant
            # -------------------------------------------------

            for ingredient in group:
                processed += 1

                if status == "CACHE_HIT":
                    cache_hits += 1
                else:
                    successful += 1

                print()
                print(
                    "  Applying image to: "
                    f"{ingredient['name']}"
                )

                try:
                    update_image_url(
                        db=db,
                        ingredient_id=(
                            ingredient["id"]
                        ),
                        image_url=local_path,
                    )

                    db.commit()

                except Exception:
                    db.rollback()
                    raise

                print(
                    "  DATABASE UPDATED."
                )

                report_rows.append(
                    {
                        "ingredient_id": str(
                            ingredient["id"]
                        ),
                        "ingredient_name": (
                            ingredient["name"]
                        ),
                        "visual_name": visual_name,
                        "status": status,
                        "image_url": local_path,
                        "source": source,
                        "error": "",
                    }
                )

        save_cache(cache)
        write_report(report_rows)

        print()
        print("=" * 80)
        print("IMPORT COMPLETE")
        print("=" * 80)
        print(
            f"Processed       : {processed}"
        )
        print(
            f"Successful      : {successful}"
        )
        print(
            f"Cache hits      : {cache_hits}"
        )
        print(
            f"No image        : {no_image}"
        )
        print(
            f"Retry later     : {retry_count}"
        )
        print(
            f"Download failed : {download_failed}"
        )
        print(
            f"Provider failed : {provider_failed}"
        )
        print(
            f"Skipped         : {skipped}"
        )
        print()
        print(
            f"Cache  : {CACHE_FILE}"
        )
        print(
            f"Report : {REPORT_FILE}"
        )
        print("=" * 80)

    except KeyboardInterrupt:
        db.rollback()
        save_cache(cache)
        write_report(report_rows)

        print()
        print("=" * 80)
        print("IMPORT INTERRUPTED")
        print("=" * 80)
        print(
            "Previously committed database "
            "changes remain safe."
        )
        print(
            f"Cache saved: {CACHE_FILE}"
        )
        print(
            f"Report saved: {REPORT_FILE}"
        )

        raise

    except IngredientImageDownloadRateLimitError as exc:
        db.rollback()
        save_cache(cache)
        write_report(report_rows)

        print()
        print("=" * 80)
        print(
            "IMPORT PAUSED - IMAGE DOWNLOAD "
            "RATE LIMIT"
        )
        print("=" * 80)
        print(
            f"Reason: {exc}"
        )
        print(
            "Previously committed database "
            "changes remain safe."
        )
        print(
            f"Cache saved: {CACHE_FILE}"
        )
        print(
            f"Report saved: {REPORT_FILE}"
        )

        return

    except Exception:
        db.rollback()
        save_cache(cache)
        write_report(report_rows)

        print()
        print("=" * 80)
        print("IMPORT FAILED")
        print("=" * 80)

        raise

    finally:
        db.close()


if __name__ == "__main__":
    main()
