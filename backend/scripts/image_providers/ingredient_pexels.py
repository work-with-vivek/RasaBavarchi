from __future__ import annotations

import re
from typing import Any

import requests

from ..ingredient_image_config import (
    MINIMUM_SCORE,
    SEARCH_TIMEOUT,
    USER_AGENT,
)
from ..image_search_aliases import (
    get_image_search_aliases,
)
from .base import ImageProvider, ImageResult


class PexelsRateLimitError(Exception):
    """Raised when Pexels returns HTTP 429."""


class IngredientPexelsProvider(ImageProvider):
    """
    Pexels provider for ingredient reference images.

    Search strategy:
        1. Expand the canonical ingredient into aliases.
        2. Search each alias with controlled queries.
        3. Score candidates against the canonical name and alias.
        4. Penalize prepared dishes and bad contexts.
        5. Apply ingredient-specific rules.
        6. Return the strongest acceptable result.
    """

    API_URL = "https://api.pexels.com/v1/search"
    RESULTS_PER_QUERY = 20

    # =========================================================
    # PREPARED-DISH TERMS
    # =========================================================

    DISH_WORDS = {
        "recipe",
        "dish",
        "meal",
        "plate",
        "platter",
        "salad",
        "soup",
        "stew",
        "curry",
        "pizza",
        "pasta",
        "sandwich",
        "burger",
        "taco",
        "tacos",
        "wrap",
        "wraps",
        "cake",
        "cakes",
        "pie",
        "pies",
        "cookie",
        "cookies",
        "brownie",
        "brownies",
        "pudding",
        "parfait",
        "raita",
        "lasagna",
        "casserole",
        "risotto",
        "biryani",
        "fried",
        "roasted",
        "grilled",
        "baked",
        "stuffed",
        "cooked",
        "cooking",
        "dinner",
        "lunch",
        "breakfast",
        "appetizer",
        "dessert",
        "served",
        "wedge",
        "wedges",
        "spiral",
        "skewer",
        "skewers",
        "snack",
        "street",
        "tray",
        "topped",
        "toast",
        "croissant",
        "biscotti",
        "pancake",
        "pancakes",
        "crepe",
        "crepes",
        "muffin",
        "muffins",
    }

    # =========================================================
    # BAD CONTEXT TERMS
    # =========================================================

    BAD_CONTEXT_WORDS = {
        "restaurant",
        "menu",
        "table",
        "dining",
        "chef",
        "kitchen",
        "bakery",
        "market",
        "supermarket",
        "store",
        "advertisement",
        "advertising",
        "package",
        "packaging",
        "bottle",
        "bottles",
        "can",
        "canned",
        "box",
        "brand",
        "logo",
        "plastic",
        "container",
        "jar",
        "bag",
        "bags",
        "commercial",
    }

    # =========================================================
    # POSITIVE REFERENCE TERMS
    # =========================================================

    POSITIVE_WORDS = {
        "ingredient",
        "food",
        "fresh",
        "raw",
        "whole",
        "natural",
        "organic",
        "grain",
        "seed",
        "seeds",
        "fruit",
        "vegetable",
        "herb",
        "spice",
    }

    # =========================================================
    # INITIALIZATION
    # =========================================================

    def __init__(
        self,
        api_key: str,
    ) -> None:
        self.api_key = (
            api_key or ""
        ).strip()

        self.session = requests.Session()

        self.session.headers.update(
            {
                "Authorization": self.api_key,
                "User-Agent": USER_AGENT,
                "Accept": "application/json",
            }
        )

    # =========================================================
    # PUBLIC SEARCH
    # =========================================================

    def search(
        self,
        ingredient_name: str,
    ) -> ImageResult | None:
        """
        Search Pexels for a suitable ingredient image.
        """

        canonical_name = self._normalize_name(
            ingredient_name
        )

        if not canonical_name:
            return None

        if not self.api_key:
            raise ValueError(
                "PEXELS_API_KEY is not configured."
            )

        aliases = get_image_search_aliases(
            canonical_name
        )

        if not aliases:
            aliases = [
                canonical_name
            ]

        best_result: ImageResult | None = None
        best_score = -10_000
        best_alias = ""
        seen_urls: set[str] = set()

        for alias in aliases:
            for query in self._build_queries(
                alias
            ):
                print(
                    f"  Pexels search: {query}"
                )

                candidates = self._search_query(
                    query
                )

                for candidate in candidates:
                    result = self._to_image_result(
                        candidate
                    )

                    if result is None:
                        continue

                    if result.url in seen_urls:
                        continue

                    seen_urls.add(
                        result.url
                    )

                    score = self._score_candidate(
                        canonical_name=canonical_name,
                        search_alias=alias,
                        candidate=candidate,
                    )

                    title = self._candidate_text(
                        candidate
                    )

                    if score < MINIMUM_SCORE:
                        print(
                            "  Pexels rejected: "
                            f"{title or 'untitled'} "
                            f"[score={score}]"
                        )
                        continue

                    print(
                        "  Pexels candidate: "
                        f"{title or 'untitled'} "
                        f"[score={score}]"
                    )

                    if score > best_score:
                        best_score = score
                        best_result = result
                        best_alias = alias

        if best_result is None:
            print(
                "  Pexels: no suitable "
                "ingredient image."
            )
            return None

        print(
            f"  Pexels best score: {best_score}"
        )
        print(
            f"  Pexels best alias: {best_alias}"
        )

        return best_result

    # =========================================================
    # NAME NORMALIZATION
    # =========================================================

    @staticmethod
    def _normalize_name(
        value: str,
    ) -> str:
        """Normalize whitespace for ingredient names."""

        return " ".join(
            (value or "").strip().split()
        ).lower()

    # =========================================================
    # QUERY BUILDER
    # =========================================================

    @staticmethod
    def _build_queries(
        alias: str,
    ) -> list[str]:
        """Build a small controlled query set."""

        name = " ".join(
            alias.split()
        ).strip()

        if not name:
            return []

        queries = [
            f"{name} ingredient",
            f"{name} food",
            name,
        ]

        return list(
            dict.fromkeys(
                queries
            )
        )

    # =========================================================
    # HTTP SEARCH
    # =========================================================

    def _search_query(
        self,
        query: str,
    ) -> list[dict[str, Any]]:
        """Execute one Pexels API search request."""

        params = {
            "query": query,
            "per_page": self.RESULTS_PER_QUERY,
            "page": 1,
        }

        try:
            response = self.session.get(
                self.API_URL,
                params=params,
                timeout=SEARCH_TIMEOUT,
            )

        except requests.Timeout as exc:
            raise RuntimeError(
                "Pexels request timed out."
            ) from exc

        except requests.RequestException as exc:
            raise RuntimeError(
                f"Pexels request failed: {exc}"
            ) from exc

        try:
            if response.status_code == 429:
                retry_after = (
                    response.headers.get(
                        "Retry-After"
                    )
                )

                message = (
                    "Pexels returned HTTP 429."
                )

                if retry_after:
                    message += (
                        f" Retry-After: {retry_after}"
                    )

                raise PexelsRateLimitError(
                    message
                )

            if response.status_code == 401:
                raise RuntimeError(
                    "Pexels API authentication failed."
                )

            if response.status_code == 403:
                raise RuntimeError(
                    "Pexels API request forbidden."
                )

            response.raise_for_status()

            data: dict[str, Any] = (
                response.json()
            )

        except PexelsRateLimitError:
            raise

        except requests.RequestException as exc:
            raise RuntimeError(
                "Pexels returned HTTP "
                f"{response.status_code}."
            ) from exc

        except ValueError as exc:
            raise RuntimeError(
                "Pexels returned invalid JSON."
            ) from exc

        photos = data.get(
            "photos",
            [],
        )

        if not isinstance(
            photos,
            list,
        ):
            return []

        return [
            photo
            for photo in photos
            if isinstance(
                photo,
                dict,
            )
        ]

    # =========================================================
    # CANDIDATE TEXT
    # =========================================================

    @staticmethod
    def _candidate_text(
        candidate: dict[str, Any],
    ) -> str:
        """Combine searchable Pexels metadata."""

        values: list[str] = []

        for key in (
            "alt",
            "url",
        ):
            value = candidate.get(
                key
            )

            if isinstance(
                value,
                str,
            ):
                values.append(
                    value
                )

        src = candidate.get(
            "src"
        )

        if isinstance(
            src,
            dict,
        ):
            for key in (
                "original",
                "large2x",
                "large",
                "medium",
            ):
                value = src.get(
                    key
                )

                if isinstance(
                    value,
                    str,
                ):
                    values.append(
                        value
                    )

        return " ".join(
            values
        ).lower()

    # =========================================================
    # TOKENIZER
    # =========================================================

    @staticmethod
    def _tokens(
        value: str,
    ) -> set[str]:
        """Convert text into normalized tokens."""

        return {
            token
            for token in re.findall(
                r"[a-z0-9]+",
                value.lower(),
            )
            if len(token) > 1
        }

    # =========================================================
    # CANDIDATE SCORING
    # =========================================================

    def _score_candidate(
        self,
        canonical_name: str,
        search_alias: str,
        candidate: dict[str, Any],
    ) -> int:
        """
        Score a candidate against both the canonical ingredient
        and the alias that produced the result.
        """

        canonical_tokens = self._tokens(
            canonical_name
        )

        alias_tokens = self._tokens(
            search_alias
        )

        candidate_text = (
            self._candidate_text(
                candidate
            )
        )

        candidate_tokens = self._tokens(
            candidate_text
        )

        if not canonical_tokens:
            return -10_000

        if not alias_tokens:
            alias_tokens = canonical_tokens

        score = 0

        normalized_candidate = (
            " ".join(
                candidate_text.split()
            )
        )

        canonical_phrase = (
            " ".join(
                canonical_name.lower().split()
            )
        )

        alias_phrase = (
            " ".join(
                search_alias.lower().split()
            )
        )

        # -----------------------------------------------------
        # Exact phrase evidence
        # -----------------------------------------------------

        if canonical_phrase in normalized_candidate:
            score += 160

        if alias_phrase in normalized_candidate:
            score += 180

        # -----------------------------------------------------
        # Alias token evidence
        # -----------------------------------------------------

        alias_matches = (
            alias_tokens
            & candidate_tokens
        )

        score += (
            len(alias_matches) * 45
        )

        if alias_tokens.issubset(
            candidate_tokens
        ):
            score += 100

        # -----------------------------------------------------
        # Canonical token evidence
        # -----------------------------------------------------

        canonical_matches = (
            canonical_tokens
            & candidate_tokens
        )

        score += (
            len(canonical_matches) * 30
        )

        if canonical_tokens.issubset(
            candidate_tokens
        ):
            score += 70

        # -----------------------------------------------------
        # Positive reference language
        # -----------------------------------------------------

        positive_hits = (
            candidate_tokens
            & self.POSITIVE_WORDS
        )

        score += (
            len(positive_hits) * 15
        )

        # -----------------------------------------------------
        # Prepared-dish penalty
        # -----------------------------------------------------

        dish_hits = (
            candidate_tokens
            & self.DISH_WORDS
        )

        score -= (
            len(dish_hits) * 85
        )

        # -----------------------------------------------------
        # Context penalty
        # -----------------------------------------------------

        context_hits = (
            candidate_tokens
            & self.BAD_CONTEXT_WORDS
        )

        score -= (
            len(context_hits) * 70
        )

        # -----------------------------------------------------
        # Ingredient-specific rules
        # -----------------------------------------------------

        score += self._ingredient_specific_score(
            canonical_name=canonical_name,
            search_alias=search_alias,
            candidate_tokens=candidate_tokens,
        )

        # -----------------------------------------------------
        # Weak-match protection
        # -----------------------------------------------------

        alias_coverage = (
            len(alias_matches)
            / max(
                len(alias_tokens),
                1,
            )
        )

        canonical_coverage = (
            len(canonical_matches)
            / max(
                len(canonical_tokens),
                1,
            )
        )

        if alias_coverage < 0.5:
            score -= 100

        if canonical_coverage == 0:
            score -= 60

        return score

    # =========================================================
    # INGREDIENT-SPECIFIC RULES
    # =========================================================

    @staticmethod
    def _ingredient_specific_score(
        canonical_name: str,
        search_alias: str,
        candidate_tokens: set[str],
    ) -> int:
        """Apply rules for ambiguous ingredient families."""

        canonical = " ".join(
            canonical_name.lower().split()
        )

        alias = " ".join(
            search_alias.lower().split()
        )

        score = 0

        # =====================================================
        # POTATO
        # =====================================================

        if canonical in {
            "potato",
            "whole potato",
            "whole potatoes",
        }:
            forbidden = {
                "sweet",
                "mashed",
                "fries",
                "chips",
                "chip",
                "tater",
                "spiral",
                "wedges",
                "wedge",
                "roasted",
                "roast",
                "grilled",
                "grill",
                "fried",
                "skewers",
                "skewer",
                "street",
                "snack",
                "served",
                "platter",
                "tray",
                "topped",
                "cheese",
                "herbs",
            }

            score -= (
                len(
                    candidate_tokens
                    & forbidden
                )
                * 180
            )

            if "raw" in candidate_tokens:
                score += 100

            if "fresh" in candidate_tokens:
                score += 50

            if "whole" in candidate_tokens:
                score += 50

        # =====================================================
        # ALMOND MEAL / POWDER
        # =====================================================

        if canonical in {
            "almond meal",
            "almond powder",
        }:
            # -------------------------------------------------
            # Reject obvious finished dishes / preparation
            # scenes. A matching keyword alone is not enough.
            # -------------------------------------------------

            hard_scene_words = {
                "cake",
                "tart",
                "croissant",
                "pancake",
                "pancakes",
                "biscotti",
                "cookies",
                "cookie",
                "dough",
                "kneading",
                "baking",
                "bakery",
                "recipe",
                "breakfast",
                "snack",
                "dessert",
            }

            if candidate_tokens & hard_scene_words:
                return -500

            # -------------------------------------------------
            # Valid processed forms for almond meal/powder.
            # -------------------------------------------------

            form_words = {
                "meal",
                "powder",
                "flour",
                "ground",
            }

            form_hits = (
                candidate_tokens
                & form_words
            )

            # -------------------------------------------------
            # Alias-specific evidence.
            # -------------------------------------------------

            if alias == "almond meal":
                if "meal" in candidate_tokens:
                    score += 160

            elif alias == "almond powder":
                if "powder" in candidate_tokens:
                    score += 160

            elif alias == "ground almonds":
                if "ground" in candidate_tokens:
                    score += 130

            elif alias == "almond flour":
                if "flour" in candidate_tokens:
                    score += 140

            # All aliases still require almond evidence.
            if "almond" in candidate_tokens:
                score += 70

            # -------------------------------------------------
            # If the metadata gives no processed-form evidence,
            # do not accept a generic whole-almond photo.
            # -------------------------------------------------

            if not form_hits:
                wrong_form_hits = (
                    candidate_tokens
                    & {
                        "whole",
                        "sliced",
                        "slices",
                        "slivered",
                        "roasted",
                    }
                )

                if wrong_form_hits:
                    return -350

                score -= 90

            # -------------------------------------------------
            # Whole/sliced/roasted almonds are not equivalent
            # to almond meal or powder.
            # -------------------------------------------------

            if "whole" in candidate_tokens:
                score -= 180

            if "sliced" in candidate_tokens:
                score -= 160

            if "slices" in candidate_tokens:
                score -= 160

            if "slivered" in candidate_tokens:
                score -= 160

            if "roasted" in candidate_tokens:
                score -= 100

            # -------------------------------------------------
            # Reject broad multi-ingredient scenes. "Flour" is
            # allowed because almond flour itself is valid.
            # -------------------------------------------------

            scene_words = {
                "sugar",
                "cinnamon",
                "egg",
                "eggs",
                "spinach",
                "scale",
                "kitchen",
                "table",
                "hands",
                "hand",
                "whisk",
                "dough",
            }

            non_flour_scene_hits = (
                candidate_tokens
                & (
                    scene_words
                    - {"flour"}
                )
            )

            if len(non_flour_scene_hits) >= 2:
                return -450

            # If the candidate says "flour" but also clearly
            # describes a baking setup, reject it.
            if (
                "flour" in candidate_tokens
                and (
                    candidate_tokens
                    & {
                        "scale",
                        "eggs",
                        "egg",
                        "spinach",
                        "kitchen",
                        "whisk",
                        "dough",
                    }
                )
            ):
                return -450

            # -------------------------------------------------
            # A clean processed-form image gets a modest bonus.
            # -------------------------------------------------

            if (
                form_hits
                and "almond" in candidate_tokens
            ):
                score += 60

        # =====================================================
        # AMCHUR / AMCHOOR
        # =====================================================

        if canonical in {
            "amchur",
            "amchur powder",
            "amchoor powder",
        }:
            if alias == "dried mango powder":
                if "mango" in candidate_tokens:
                    score += 80

                if "dried" in candidate_tokens:
                    score += 50

                if "powder" in candidate_tokens:
                    score += 50

            if "fresh" in candidate_tokens:
                score -= 100

            if "juice" in candidate_tokens:
                score -= 100

        # =====================================================
        # ANAHEIM CHILI
        # =====================================================

        if canonical in {
            "anaheim chili",
            "anaheim chilies",
        }:
            if alias in {
                "anaheim pepper",
                "anaheim peppers",
            }:
                score += (
                    len(
                        candidate_tokens
                        & {
                            "anaheim",
                            "pepper",
                            "peppers",
                            "chili",
                            "chilies",
                            "chile",
                        }
                    )
                    * 45
                )

            if "sauce" in candidate_tokens:
                score -= 120

            if "powder" in candidate_tokens:
                score -= 100

        # =====================================================
        # ANCHO CHILI
        # =====================================================

        if canonical in {
            "ancho chili",
            "ancho chilies",
        }:
            if alias in {
                "dried ancho pepper",
                "dried ancho peppers",
            }:
                if "dried" in candidate_tokens:
                    score += 50

                if "pepper" in candidate_tokens:
                    score += 60

                if "chile" in candidate_tokens:
                    score += 40

            if "sauce" in candidate_tokens:
                score -= 120

        # =====================================================
        # PITA
        # =====================================================

        if canonical in {
            "pita",
            "pita bread",
            "pita flatbread",
        }:
            if "flatbread" in candidate_tokens:
                score += 70

            if "bread" in candidate_tokens:
                score += 35

            score -= (
                len(
                    candidate_tokens
                    & {
                        "hummus",
                        "falafel",
                        "sandwich",
                        "chips",
                        "platter",
                    }
                )
                * 160
            )

        # =====================================================
        # BREAD
        # =====================================================

        if canonical == "bread":
            score -= (
                len(
                    candidate_tokens
                    & {
                        "sandwich",
                        "burger",
                        "toast",
                    }
                )
                * 140
            )

            if "loaf" in candidate_tokens:
                score += 60

        # =====================================================
        # CREAM
        # =====================================================

        if canonical in {
            "cream",
            "heavy cream",
            "table cream",
        }:
            score -= (
                len(
                    candidate_tokens
                    & {
                        "cake",
                        "pastry",
                        "ice",
                        "dessert",
                    }
                )
                * 120
            )

        # =====================================================
        # RICE
        # =====================================================

        if canonical == "rice":
            score -= (
                len(
                    candidate_tokens
                    & {
                        "biryani",
                        "fried",
                        "pilaf",
                        "pudding",
                    }
                )
                * 180
            )

            if "grain" in candidate_tokens:
                score += 50

        return score

    # =========================================================
    # RESULT CONVERSION
    # =========================================================

    @staticmethod
    def _to_image_result(
        candidate: dict[str, Any],
    ) -> ImageResult | None:
        """Convert a Pexels photo object into ImageResult."""

        src = candidate.get(
            "src",
            {},
        )

        if not isinstance(
            src,
            dict,
        ):
            return None

        image_url = (
            src.get("large2x")
            or src.get("large")
            or src.get("medium")
            or src.get("original")
        )

        if not isinstance(
            image_url,
            str,
        ):
            return None

        image_url = (
            image_url.strip()
        )

        if not image_url:
            return None

        return ImageResult(
            url=image_url,
            mime_type="image/jpeg",
        )
