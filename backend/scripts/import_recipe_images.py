from __future__ import annotations

import csv
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import requests

# =============================================================
# ENSURE BACKEND ROOT IS IMPORTABLE
# =============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))


# =============================================================
# APPLICATION IMPORTS
# =============================================================

from app.dependencies.database import SessionLocal
from app.models.recipe import Recipe


# =============================================================
# CONFIG
# =============================================================

from scripts.image_import_config import (
    ALLOWED_MIME_TYPES,
    IMPORT_LIMIT,
    MEDIA_DIR,
    USER_AGENT,
)


# =============================================================
# PROVIDERS
# =============================================================

from scripts.image_providers import (
    ImageProviderManager,
    ImageResult,
    OpenverseProvider,
    TheMealDBProvider,
)


# =============================================================
# MANUAL FALLBACKS
# =============================================================

from scripts.image_fallbacks import (
    FALLBACK_IMAGES,
)


# =============================================================
# IMPORT SETTINGS
# =============================================================

BATCH_SIZE = 20

DOWNLOAD_RETRIES = 3

DOWNLOAD_TIMEOUT = 15

PROGRESS_EVERY = 10

FAILURE_LOG = (
    BASE_DIR
    / "logs"
    / "recipe_image_failures.csv"
)


# =============================================================
# MIME TYPE -> EXTENSION
# =============================================================

def get_extension(
    mime_type: str,
) -> str:
    """
    Convert MIME type into a safe file extension.
    """

    mime_type = (
        mime_type
        .split(";")[0]
        .strip()
        .lower()
    )

    return ALLOWED_MIME_TYPES.get(
        mime_type,
        ".jpg",
    )


# =============================================================
# FALLBACK LOOKUP
# =============================================================

def get_fallback_image(
    recipe_title: str,
) -> str | None:
    """
    Find a manually configured fallback image.
    """

    normalized_title = (
        " ".join(
            recipe_title.lower().split()
        )
    )

    for title, image_url in (
        FALLBACK_IMAGES.items()
    ):

        normalized_fallback = (
            " ".join(
                title.lower().split()
            )
        )

        if (
            normalized_title
            == normalized_fallback
        ):
            return image_url

    return None


# =============================================================
# PROVIDER MANAGER
# =============================================================

def create_provider_manager() -> ImageProviderManager:
    """
    Create the image provider chain.

    Priority:

    1. Openverse
    2. TheMealDB
    """

    return ImageProviderManager(
        [
            OpenverseProvider(),
            TheMealDBProvider(),
        ]
    )


# =============================================================
# DOWNLOAD IMAGE
# =============================================================

def download_image(
    image_url: str,
) -> tuple[bytes | None, str | None]:
    """
    Download an image with retries.

    Returns:

        image bytes
        actual MIME type
    """

    for attempt in range(
        1,
        DOWNLOAD_RETRIES + 1,
    ):

        try:

            print(
                f"  Download attempt "
                f"{attempt}/{DOWNLOAD_RETRIES}..."
            )

            response = requests.get(
                image_url,
                headers={
                    "User-Agent": USER_AGENT,
                    "Accept": (
                        "image/avif,"
                        "image/webp,"
                        "image/apng,"
                        "image/jpeg,"
                        "image/png,"
                        "*/*"
                    ),
                },
                timeout=DOWNLOAD_TIMEOUT,
            )

            print(
                f"  HTTP status: "
                f"{response.status_code}"
            )

            response.raise_for_status()

            content_type = (
                response.headers
                .get(
                    "content-type",
                    "",
                )
                .split(";")[0]
                .strip()
                .lower()
            )

            print(
                f"  Actual MIME: "
                f"{content_type}"
            )

            # -------------------------------------------------
            # MIME validation
            # -------------------------------------------------

            if (
                content_type
                not in ALLOWED_MIME_TYPES
            ):

                print(
                    "  Download rejected: "
                    f"unsupported MIME "
                    f"{content_type}"
                )

                return None, None

            # -------------------------------------------------
            # Empty response
            # -------------------------------------------------

            if not response.content:

                print(
                    "  Download rejected: "
                    "empty response."
                )

                return None, None

            print(
                f"  Downloaded: "
                f"{len(response.content):,} bytes"
            )

            return (
                response.content,
                content_type,
            )

        except requests.Timeout as exc:

            print(
                f"  Download timeout: "
                f"{exc}"
            )

        except requests.RequestException as exc:

            print(
                f"  Download failed: "
                f"{exc}"
            )

        if attempt < DOWNLOAD_RETRIES:

            wait_seconds = 2 ** attempt

            print(
                f"  Retrying in "
                f"{wait_seconds}s..."
            )

            time.sleep(
                wait_seconds
            )

    print(
        "  Download abandoned."
    )

    return None, None


# =============================================================
# FAILURE LOG
# =============================================================

def ensure_failure_log() -> None:
    """
    Create the failure CSV if it doesn't exist.
    """

    FAILURE_LOG.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    if FAILURE_LOG.exists():
        return

    with FAILURE_LOG.open(
        "w",
        newline="",
        encoding="utf-8",
    ) as file:

        writer = csv.writer(file)

        writer.writerow(
            [
                "timestamp",
                "recipe_id",
                "recipe_title",
                "reason",
            ]
        )


def log_failure(
    recipe_id: str,
    recipe_title: str,
    reason: str,
) -> None:
    """
    Append a failed recipe to the CSV log.
    """

    ensure_failure_log()

    with FAILURE_LOG.open(
        "a",
        newline="",
        encoding="utf-8",
    ) as file:

        writer = csv.writer(file)

        writer.writerow(
            [
                datetime.now(
                    timezone.utc
                ).isoformat(),
                recipe_id,
                recipe_title,
                reason,
            ]
        )


# =============================================================
# SAVE IMAGE
# =============================================================

def save_image(
    image_bytes: bytes,
    mime_type: str,
    recipe_id: str,
) -> tuple[Path | None, str | None]:
    """
    Save an image using the actual MIME type.

    Returns:

        output path
        filename
    """

    extension = get_extension(
        mime_type
    )

    filename = (
        f"recipe_{recipe_id}"
        f"{extension}"
    )

    output_path = (
        MEDIA_DIR / filename
    )

    try:

        output_path.write_bytes(
            image_bytes
        )

        print(
            f"  Saved file: "
            f"{output_path}"
        )

        return (
            output_path,
            filename,
        )

    except OSError as exc:

        print(
            f"  File save failed: "
            f"{exc}"
        )

        return None, None


# =============================================================
# PROCESS ONE RECIPE
# =============================================================

def process_recipe(
    db,
    recipe: Recipe,
    provider_manager: ImageProviderManager,
) -> tuple[str, bool]:
    """
    Process one recipe.

    Returns:

        status
        success
    """

    print(
        f"Recipe: "
        f"{recipe.title}"
    )

    # ---------------------------------------------------------
    # Provider search
    # ---------------------------------------------------------

    result = provider_manager.search(
        recipe.title
    )

    # ---------------------------------------------------------
    # Manual fallback
    # ---------------------------------------------------------

    if result is None:

        fallback_url = (
            get_fallback_image(
                recipe.title
            )
        )

        if fallback_url:

            print(
                "  Using manual "
                "fallback image."
            )

            result = ImageResult(
                url=fallback_url,
                mime_type="image/jpeg",
            )

        else:

            print(
                "  No suitable image "
                "found."
            )

            return (
                "no_image",
                False,
            )

    # ---------------------------------------------------------
    # Download
    # ---------------------------------------------------------

    print(
        f"  Source: "
        f"{result.url}"
    )

    image_bytes, actual_mime = (
        download_image(
            result.url
        )
    )

    if (
        image_bytes is None
        or actual_mime is None
    ):

        return (
            "download_failed",
            False,
        )

    # ---------------------------------------------------------
    # Save
    # ---------------------------------------------------------

    output_path, filename = (
        save_image(
            image_bytes,
            actual_mime,
            str(recipe.id),
        )
    )

    if (
        output_path is None
        or filename is None
    ):

        return (
            "save_failed",
            False,
        )

    # ---------------------------------------------------------
    # Database update
    # ---------------------------------------------------------

    recipe.image_url = (
        f"media/images/{filename}"
    )

    db.add(recipe)

    try:

        db.commit()

    except Exception:

        db.rollback()

        # Remove image if DB update failed.

        try:

            if output_path.exists():

                output_path.unlink()

        except OSError:
            pass

        raise

    print(
        f"  Database image_url: "
        f"{recipe.image_url}"
    )

    return (
        "success",
        True,
    )


# =============================================================
# MAIN
# =============================================================

def main() -> None:

    print("=" * 60)
    print(
        "RasaBavarchi Recipe Image Importer"
    )
    print("=" * 60)

    print(
        f"Batch size:       {BATCH_SIZE}"
    )

    print(
        f"Import limit:     {IMPORT_LIMIT}"
    )

    print(
        f"Media directory:  {MEDIA_DIR}"
    )

    print(
        f"Failure log:      {FAILURE_LOG}"
    )

    print()

    # ---------------------------------------------------------
    # Prepare directories
    # ---------------------------------------------------------

    MEDIA_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    ensure_failure_log()

    # ---------------------------------------------------------
    # Provider manager
    # ---------------------------------------------------------

    provider_manager = (
        create_provider_manager()
    )

    # ---------------------------------------------------------
    # Database
    # ---------------------------------------------------------

    db = SessionLocal()

    processed = 0
    successful = 0
    failed = 0
    fallback_used = 0

    try:

        # =====================================================
        # BATCH LOOP
        # =====================================================

        while True:

            # -------------------------------------------------
            # Remaining limit
            # -------------------------------------------------

            if IMPORT_LIMIT is not None:

                remaining = (
                    IMPORT_LIMIT
                    - processed
                )

                if remaining <= 0:
                    break

                current_batch_size = min(
                    BATCH_SIZE,
                    remaining,
                )

            else:

                current_batch_size = (
                    BATCH_SIZE
                )

            # -------------------------------------------------
            # Fetch one batch only
            # -------------------------------------------------

            recipes = (
                db.query(Recipe)
                .filter(
                    (Recipe.image_url.is_(None))
                    | (Recipe.image_url == "")
                )
                .order_by(
                    Recipe.id
                )
                .limit(
                    current_batch_size
                )
                .all()
            )

            # -------------------------------------------------
            # Finished
            # -------------------------------------------------

            if not recipes:

                print()
                print(
                    "No recipes without "
                    "images remain."
                )

                break

            print()
            print(
                "=" * 60
            )

            print(
                f"Processing batch of "
                f"{len(recipes)} recipes"
            )

            print(
                "=" * 60
            )

            # =================================================
            # PROCESS BATCH
            # =================================================

            for recipe in recipes:

                processed += 1

                print()
                print(
                    f"[{processed}"
                    f"{'/' + str(IMPORT_LIMIT) if IMPORT_LIMIT is not None else ''}]"
                )

                try:

                    status, success = (
                        process_recipe(
                            db,
                            recipe,
                            provider_manager,
                        )
                    )

                    if success:

                        successful += 1

                    else:

                        failed += 1

                        log_failure(
                            str(recipe.id),
                            recipe.title,
                            status,
                        )

                except Exception as exc:

                    failed += 1

                    print(
                        f"  Unexpected error: "
                        f"{exc}"
                    )

                    db.rollback()

                    log_failure(
                        str(recipe.id),
                        recipe.title,
                        f"exception: {exc}",
                    )

                # -------------------------------------------------
                # Progress
                # -------------------------------------------------

                if (
                    processed
                    % PROGRESS_EVERY
                    == 0
                ):

                    print()
                    print(
                        "--- PROGRESS ---"
                    )

                    print(
                        f"Processed:  "
                        f"{processed}"
                    )

                    print(
                        f"Successful: "
                        f"{successful}"
                    )

                    print(
                        f"Failed:     "
                        f"{failed}"
                    )

            # -------------------------------------------------
            # Small pause between batches
            # -------------------------------------------------

            time.sleep(1)

        # =====================================================
        # SUMMARY
        # =====================================================

        print()
        print("=" * 60)
        print(
            "IMAGE IMPORT COMPLETE"
        )
        print("=" * 60)

        print(
            f"Processed:      "
            f"{processed}"
        )

        print(
            f"Successful:     "
            f"{successful}"
        )

        print(
            f"Failed:         "
            f"{failed}"
        )

        print(
            f"Fallback used:  "
            f"{fallback_used}"
        )

        if processed:

            success_rate = (
                successful
                / processed
                * 100
            )

            print(
                f"Success rate:   "
                f"{success_rate:.1f}%"
            )

        print(
            f"Failure log:    "
            f"{FAILURE_LOG}"
        )

    except KeyboardInterrupt:

        print()
        print(
            "Importer stopped by user."
        )

        print(
            "Already committed images "
            "are preserved."
        )

    except Exception:

        db.rollback()

        raise

    finally:

        db.close()


# =============================================================
# ENTRY POINT
# =============================================================

if __name__ == "__main__":
    main()