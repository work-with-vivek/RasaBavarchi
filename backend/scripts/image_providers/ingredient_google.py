from __future__ import annotations

from typing import Any

import requests

from ..ingredient_image_config import (
    ALLOWED_MIME_TYPES,
    SEARCH_TIMEOUT,
    USER_AGENT,
)
from .base import ImageProvider, ImageResult


class GoogleImageProviderError(Exception):
    """Raised for Google Images provider failures."""


class IngredientGoogleProvider(ImageProvider):
    """
    Google Custom Search JSON API provider for ingredient images.

    The provider returns candidate image URLs. The existing
    ingredient-quality/scoring pipeline remains responsible for
    deciding whether a candidate is actually suitable.
    """

    API_URL = "https://www.googleapis.com/customsearch/v1"

    def __init__(
        self,
        api_key: str,
        search_engine_id: str,
    ) -> None:

        self.api_key = api_key.strip()
        self.search_engine_id = (
            search_engine_id.strip()
        )

        self.session = requests.Session()

        self.session.headers.update(
            {
                "User-Agent": USER_AGENT,
                "Accept": "application/json",
            }
        )

    # =========================================================
    # SEARCH
    # =========================================================

    def search(
        self,
        ingredient_name: str,
    ) -> ImageResult | None:
        """
        Search Google Images for one ingredient.

        Returns the highest-priority usable image candidate,
        or None when no usable result is available.
        """

        ingredient_name = (
            ingredient_name or ""
        ).strip()

        if not ingredient_name:
            return None

        if not self.api_key:
            raise GoogleImageProviderError(
                "Google API key is not configured."
            )

        if not self.search_engine_id:
            raise GoogleImageProviderError(
                "Google Custom Search Engine ID "
                "is not configured."
            )

        queries = self._build_queries(
            ingredient_name
        )

        for query in queries:

            result = self._search_query(
                query
            )

            if result is not None:
                return result

        return None

    # =========================================================
    # QUERY BUILDER
    # =========================================================

    @staticmethod
    def _build_queries(
        ingredient_name: str,
    ) -> list[str]:
        """
        Build a very small set of image-focused queries.

        Keep this deliberately conservative because the downstream
        quality pipeline performs the actual semantic validation.
        """

        visual = (
            ingredient_name.strip()
        )

        queries = [
            f"{visual} ingredient",
            visual,
        ]

        return list(
            dict.fromkeys(
                queries
            )
        )[:2]

    # =========================================================
    # GOOGLE REQUEST
    # =========================================================

    def _search_query(
        self,
        query: str,
    ) -> ImageResult | None:

        params = {
            "key": self.api_key,
            "cx": self.search_engine_id,
            "q": query,
            "searchType": "image",
            "num": 10,
            "safe": "active",
        }

        try:

            response = self.session.get(
                self.API_URL,
                params=params,
                timeout=SEARCH_TIMEOUT,
            )

        except requests.Timeout as exc:

            raise GoogleImageProviderError(
                "Google Images request timed out."
            ) from exc

        except requests.RequestException as exc:

            raise GoogleImageProviderError(
                f"Google Images request failed: {exc}"
            ) from exc

        # =====================================================
        # HTTP ERRORS
        # =====================================================

        if response.status_code == 429:

            raise GoogleImageProviderError(
                "Google Custom Search API rate limit reached."
            )

        if response.status_code == 401:

            raise GoogleImageProviderError(
                "Google API authentication failed."
            )

        if response.status_code == 403:

            raise GoogleImageProviderError(
                "Google API request forbidden. "
                "Check API key, Custom Search configuration, "
                "billing/quota, and permissions."
            )

        try:

            response.raise_for_status()

        except requests.RequestException as exc:

            raise GoogleImageProviderError(
                f"Google API returned HTTP "
                f"{response.status_code}."
            ) from exc

        # =====================================================
        # JSON
        # =====================================================

        try:

            data: dict[str, Any] = (
                response.json()
            )

        except ValueError as exc:

            raise GoogleImageProviderError(
                "Google API returned invalid JSON."
            ) from exc

        # =====================================================
        # RESULTS
        # =====================================================

        items = data.get(
            "items",
            [],
        )

        if not isinstance(
            items,
            list,
        ):
            return None

        for item in items:

            if not isinstance(
                item,
                dict,
            ):
                continue

            image = item.get(
                "image",
                {},
            )

            if not isinstance(
                image,
                dict,
            ):
                image = {}

            mime_type = (
                image.get(
                    "mime",
                    "",
                )
                or ""
            ).strip().lower()

            if mime_type not in (
                ALLOWED_MIME_TYPES
            ):
                continue

            image_url = (
                image.get(
                    "thumbnailLink"
                )
                or image.get(
                    "contextLink"
                )
            )

            # Prefer the actual image URL from the result
            # metadata when available.
            image_url = (
                item.get(
                    "link"
                )
                or image_url
            )

            if not image_url:
                continue

            return ImageResult(
                url=image_url,
                mime_type=mime_type,
            )

        return None