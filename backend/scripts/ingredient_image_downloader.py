from __future__ import annotations

import hashlib
import re
from pathlib import Path
from urllib.parse import unquote, urlparse

import requests

from .ingredient_image_config import (
    ALLOWED_MIME_TYPES,
    DOWNLOAD_TIMEOUT,
    INGREDIENT_IMAGE_DIR,
    USER_AGENT,
)


# =============================================================
# DOWNLOAD RATE LIMIT
# =============================================================


class IngredientImageDownloadRateLimitError(Exception):
    """
    Raised when an image provider still returns HTTP 429 after
    all supported fallback download attempts.
    """

    pass


# =============================================================
# DOWNLOADER
# =============================================================


class IngredientImageDownloader:
    """
    Download ingredient images and store them locally.

    Preferred filename:
        ingredient_<canonical_name>_<hash>.<ext>

    Fallback filename:
        ingredient_<uuid>.<ext>
    """

    MINIMUM_FILE_SIZE = 1024

    # Wikimedia thumbnail width used when the original upload
    # endpoint is rate-limited.
    WIKIMEDIA_THUMBNAIL_WIDTH = 1280

    # =========================================================
    # INIT
    # =========================================================

    def __init__(self) -> None:
        self.session = requests.Session()

        self.session.headers.update(
            {
                "User-Agent": USER_AGENT,
                "Accept": "image/*",
            }
        )

        INGREDIENT_IMAGE_DIR.mkdir(
            parents=True,
            exist_ok=True,
        )

    # =========================================================
    # NORMALIZE CANONICAL NAME
    # =========================================================

    @staticmethod
    def _normalize_canonical_name(
        canonical_name: str,
    ) -> str:
        """
        Convert canonical ingredient name into a safe filename.

        Example:
            Extra Virgin Olive Oil
            ->
            extra_virgin_olive_oil
        """

        value = (
            canonical_name or ""
        ).strip().lower()

        value = re.sub(
            r"[^a-z0-9]+",
            "_",
            value,
        )

        value = re.sub(
            r"_+",
            "_",
            value,
        )

        return value.strip("_")

    # =========================================================
    # CANONICAL HASH
    # =========================================================

    @staticmethod
    def _canonical_hash(
        canonical_name: str,
    ) -> str:
        """
        Generate stable short hash.
        """

        return hashlib.sha256(
            canonical_name.strip()
            .lower()
            .encode("utf-8")
        ).hexdigest()[:12]

    # =========================================================
    # UUID FILENAME
    # =========================================================

    @staticmethod
    def _filename(
        ingredient_id: str,
        extension: str,
    ) -> str:
        """
        Generate UUID-based filename.
        """

        return (
            f"ingredient_"
            f"{ingredient_id}"
            f"{extension}"
        )

    # =========================================================
    # CANONICAL FILENAME
    # =========================================================

    @classmethod
    def _canonical_filename(
        cls,
        canonical_name: str,
        extension: str,
    ) -> str:
        """
        Generate canonical filename.
        """

        safe_name = cls._normalize_canonical_name(
            canonical_name
        )

        if not safe_name:
            safe_name = "unknown_ingredient"

        name_hash = cls._canonical_hash(
            canonical_name
        )

        return (
            f"ingredient_"
            f"{safe_name}_"
            f"{name_hash}"
            f"{extension}"
        )

    # =========================================================
    # WIKIMEDIA DETECTION
    # =========================================================

    @staticmethod
    def _is_wikimedia_url(
        image_url: str,
    ) -> bool:
        """
        Detect Wikimedia image URLs.
        """

        try:
            parsed = urlparse(
                image_url
            )
        except ValueError:
            return False

        hostname = (
            parsed.hostname or ""
        ).lower()

        return hostname in {
            "upload.wikimedia.org",
            "thumb.wikimedia.org",
        }

    # =========================================================
    # WIKIMEDIA THUMBNAIL URL
    # =========================================================

    @classmethod
    def _wikimedia_thumbnail_url(
        cls,
        image_url: str,
    ) -> str | None:
        """
        Convert a Wikimedia Commons original image URL into a
        thumbnail URL.

        Supported source:

            https://upload.wikimedia.org/wikipedia/commons/a/ab/File.jpg

        Result:

            https://thumb.wikimedia.org/wikipedia/commons/thumb/
            a/ab/File.jpg/1280px-File.jpg

        Returns None for URLs that cannot be converted safely.
        """

        try:
            parsed = urlparse(
                image_url
            )
        except ValueError:
            return None

        hostname = (
            parsed.hostname or ""
        ).lower()

        if hostname not in {
            "upload.wikimedia.org",
            "thumb.wikimedia.org",
        }:
            return None

        path = unquote(
            parsed.path or ""
        )

        marker = "/wikipedia/commons/"

        marker_index = path.find(
            marker
        )

        if marker_index < 0:
            return None

        relative_path = path[
            marker_index
            + len(marker) :
        ].lstrip("/")

        if not relative_path:
            return None

        # Already a thumbnail URL.
        if "/thumb/" in path:
            return image_url

        filename = Path(
            relative_path
        ).name

        if not filename:
            return None

        return (
            "https://thumb.wikimedia.org/"
            "wikipedia/commons/thumb/"
            f"{relative_path}/"
            f"{cls.WIKIMEDIA_THUMBNAIL_WIDTH}px-"
            f"{filename}"
        )

    # =========================================================
    # HTTP DOWNLOAD
    # =========================================================

    def _request_image(
        self,
        image_url: str,
    ) -> tuple[
        requests.Response | None,
        str | None,
    ]:
        """
        Download an image.

        Returns:
            response, rate_limit_message

        rate_limit_message is populated only when HTTP 429
        remains unresolved.
        """

        try:
            response = self.session.get(
                image_url,
                timeout=DOWNLOAD_TIMEOUT,
                stream=True,
            )
        except requests.RequestException as exc:
            print(
                f"  Image download failed: {exc}"
            )

            return None, None

        # -----------------------------------------------------
        # Normal success
        # -----------------------------------------------------

        if response.status_code != 429:
            return response, None

        retry_after = (
            response.headers.get(
                "Retry-After"
            )
        )

        message = (
            "Image download returned HTTP 429."
        )

        if retry_after:
            message += (
                f" Retry-After: {retry_after}"
            )

        print(
            f"  Download rate limit: {message}"
        )

        # -----------------------------------------------------
        # Wikimedia thumbnail fallback
        # -----------------------------------------------------

        thumbnail_url = (
            self._wikimedia_thumbnail_url(
                image_url
            )
        )

        if thumbnail_url is None:
            response.close()

            return (
                None,
                message,
            )

        if thumbnail_url == image_url:
            response.close()

            return (
                None,
                message,
            )

        print(
            "  Trying Wikimedia thumbnail fallback:"
        )
        print(
            f"  {thumbnail_url}"
        )

        response.close()

        try:
            thumbnail_response = (
                self.session.get(
                    thumbnail_url,
                    timeout=DOWNLOAD_TIMEOUT,
                    stream=True,
                )
            )
        except requests.RequestException as exc:
            print(
                "  Thumbnail download failed: "
                f"{exc}"
            )

            return (
                None,
                message,
            )

        if (
            thumbnail_response.status_code
            == 429
        ):
            thumbnail_retry_after = (
                thumbnail_response.headers.get(
                    "Retry-After"
                )
            )

            thumbnail_message = (
                "Wikimedia thumbnail download "
                "returned HTTP 429."
            )

            if thumbnail_retry_after:
                thumbnail_message += (
                    f" Retry-After: "
                    f"{thumbnail_retry_after}"
                )

            print(
                "  Thumbnail rate limit: "
                f"{thumbnail_message}"
            )

            thumbnail_response.close()

            return (
                None,
                thumbnail_message,
            )

        if (
            thumbnail_response.status_code
            >= 400
        ):
            print(
                "  Wikimedia thumbnail returned "
                f"HTTP {thumbnail_response.status_code}."
            )

            thumbnail_response.close()

            return (
                None,
                message,
            )

        print(
            "  Wikimedia thumbnail download succeeded."
        )

        return (
            thumbnail_response,
            None,
        )

    # =========================================================
    # DOWNLOAD
    # =========================================================

    def download(
        self,
        ingredient_id: str | None,
        image_url: str,
        mime_type: str,
        canonical_name: str | None = None,
    ) -> str | None:
        """
        Download an ingredient image.

        Wikimedia original-image 429 responses automatically
        attempt a thumbnail fallback before failing.
        """

        # =====================================================
        # MIME TYPE
        # =====================================================

        extension = ALLOWED_MIME_TYPES.get(
            mime_type
        )

        if extension is None:
            print(
                "  Download rejected: "
                "unsupported MIME type "
                f"{mime_type}"
            )

            return None

        # =====================================================
        # URL
        # =====================================================

        image_url = (
            image_url or ""
        ).strip()

        if not image_url:
            print(
                "  Download rejected: "
                "empty image URL."
            )

            return None

        # =====================================================
        # FILENAME
        # =====================================================

        if canonical_name:
            filename = (
                self._canonical_filename(
                    canonical_name,
                    extension,
                )
            )
        elif ingredient_id:
            filename = (
                self._filename(
                    str(ingredient_id),
                    extension,
                )
            )
        else:
            print(
                "  Download rejected: "
                "no ingredient_id or "
                "canonical_name."
            )

            return None

        destination = (
            INGREDIENT_IMAGE_DIR
            / filename
        )

        # =====================================================
        # EXISTING FILE
        # =====================================================

        if destination.exists():
            try:
                if (
                    destination.stat().st_size
                    >= self.MINIMUM_FILE_SIZE
                ):
                    print(
                        "  Local image already exists: "
                        f"{filename}"
                    )

                    return self._relative_path(
                        destination
                    )
            except OSError:
                pass

        # =====================================================
        # TEMP FILE
        # =====================================================

        temporary_destination = (
            destination.with_suffix(
                destination.suffix
                + ".tmp"
            )
        )

        temporary_destination.unlink(
            missing_ok=True
        )

        # =====================================================
        # REQUEST
        # =====================================================

        try:
            (
                response,
                rate_limit_message,
            ) = self._request_image(
                image_url
            )

            # -------------------------------------------------
            # Unresolved rate limit
            # -------------------------------------------------

            if response is None:
                temporary_destination.unlink(
                    missing_ok=True
                )

                if rate_limit_message:
                    raise (
                        IngredientImageDownloadRateLimitError(
                            rate_limit_message
                        )
                    )

                return None

            # =================================================
            # CONTENT TYPE
            # =================================================

            content_type = (
                response.headers.get(
                    "Content-Type",
                    "",
                )
                .split(";")[0]
                .strip()
                .lower()
            )

            if (
                content_type
                not in ALLOWED_MIME_TYPES
            ):
                print(
                    "  Download rejected: "
                    f"{content_type}"
                )

                response.close()

                return None

            # =================================================
            # MIME / EXTENSION CONSISTENCY
            # =================================================

            actual_extension = (
                ALLOWED_MIME_TYPES[
                    content_type
                ]
            )

            if actual_extension != extension:
                # Use the actual server MIME type.
                extension = actual_extension

                if canonical_name:
                    filename = (
                        self._canonical_filename(
                            canonical_name,
                            extension,
                        )
                    )
                elif ingredient_id:
                    filename = (
                        self._filename(
                            str(ingredient_id),
                            extension,
                        )
                    )

                destination = (
                    INGREDIENT_IMAGE_DIR
                    / filename
                )

                temporary_destination.unlink(
                    missing_ok=True
                )

                temporary_destination = (
                    destination.with_suffix(
                        destination.suffix
                        + ".tmp"
                    )
                )

            # =================================================
            # WRITE TEMP FILE
            # =================================================

            with temporary_destination.open(
                "wb"
            ) as file:
                for chunk in response.iter_content(
                    chunk_size=64 * 1024
                ):
                    if chunk:
                        file.write(chunk)

            response.close()

            # =================================================
            # VALIDATE TEMP FILE
            # =================================================

            if not temporary_destination.exists():
                print(
                    "  Download failed: "
                    "temporary file was not created."
                )

                return None

            file_size = (
                temporary_destination.stat().st_size
            )

            if (
                file_size
                < self.MINIMUM_FILE_SIZE
            ):
                print(
                    "  Download rejected: "
                    "image is too small "
                    f"({file_size} bytes)."
                )

                temporary_destination.unlink(
                    missing_ok=True
                )

                return None

            # =================================================
            # ATOMIC MOVE
            # =================================================

            temporary_destination.replace(
                destination
            )

            # =================================================
            # RETURN PATH
            # =================================================

            return self._relative_path(
                destination
            )

        except IngredientImageDownloadRateLimitError:
            temporary_destination.unlink(
                missing_ok=True
            )

            raise

        except requests.RequestException as exc:
            print(
                f"  Image download failed: {exc}"
            )

            destination.unlink(
                missing_ok=True
            )

            temporary_destination.unlink(
                missing_ok=True
            )

            return None

        except OSError as exc:
            print(
                f"  File error: {exc}"
            )

            destination.unlink(
                missing_ok=True
            )

            temporary_destination.unlink(
                missing_ok=True
            )

            return None

    # =========================================================
    # RELATIVE PATH
    # =========================================================

    @staticmethod
    def _relative_path(
        destination: Path,
    ) -> str:
        """
        Convert absolute media path into database/API path.

        Example:
            backend/media/images/ingredients/foo.jpg

        becomes:
            images/ingredients/foo.jpg
        """

        media_root = Path(
            INGREDIENT_IMAGE_DIR
        ).parents[1]

        return str(
            destination.relative_to(
                media_root
            )
        ).replace(
            "\\",
            "/",
        )