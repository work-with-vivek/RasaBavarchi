from __future__ import annotations

import re

import requests

from ..image_import_config import (
    SEARCH_TIMEOUT,
    USER_AGENT,
)

from .base import ImageProvider, ImageResult


class TheMealDBProvider(ImageProvider):
    """
    TheMealDB image provider.

    Searches TheMealDB using multiple progressively
    broader queries and returns only high-confidence
    image matches.

    Generic results are rejected when they do not
    sufficiently represent the original recipe title.
    """

    API_URL = (
        "https://www.themealdb.com/api/json/v1/1/search.php"
    )

    MIN_SCORE = 70

    # =========================================================
    # INITIALIZATION
    # =========================================================

    def __init__(self) -> None:
        self.session = requests.Session()

        self.session.headers.update(
            {
                "User-Agent": USER_AGENT,
                "Accept": "application/json",
            }
        )

    # =========================================================
    # NORMALIZATION
    # =========================================================

    @staticmethod
    def _normalize(
        text: str,
    ) -> str:
        """
        Normalize text for searching and comparison.
        """

        text = text.lower()

        text = re.sub(
            r"[^a-z0-9\s]",
            " ",
            text,
        )

        text = re.sub(
            r"\s+",
            " ",
            text,
        )

        return text.strip()

    # =========================================================
    # TOKENS
    # =========================================================

    @classmethod
    def _tokens(
        cls,
        text: str,
    ) -> list[str]:
        """
        Return meaningful normalized tokens.
        """

        stop_words = {
            "a",
            "an",
            "and",
            "the",
            "of",
            "with",
            "my",
            "s",
            "one",
            "kind",
            "grandma",
            "grand",
            "mrs",
            "mr",
            "recipe",
            "style",
        }

        normalized = cls._normalize(
            text
        )

        return [
            token
            for token in normalized.split()
            if token
            and token not in stop_words
        ]

    # =========================================================
    # SINGULAR / PLURAL
    # =========================================================

    @staticmethod
    def _equivalent_words(
        word: str,
    ) -> set[str]:
        """
        Return simple singular/plural equivalents.
        """

        aliases = {
            "pancake": {
                "pancake",
                "pancakes",
            },
            "pancakes": {
                "pancake",
                "pancakes",
            },
            "cookie": {
                "cookie",
                "cookies",
            },
            "cookies": {
                "cookie",
                "cookies",
            },
            "cupcake": {
                "cupcake",
                "cupcakes",
            },
            "cupcakes": {
                "cupcake",
                "cupcakes",
            },
            "brownie": {
                "brownie",
                "brownies",
            },
            "brownies": {
                "brownie",
                "brownies",
            },
            "parfait": {
                "parfait",
                "parfaits",
            },
            "parfaits": {
                "parfait",
                "parfaits",
            },
            "roll": {
                "roll",
                "rolls",
            },
            "rolls": {
                "roll",
                "rolls",
            },
            "loaf": {
                "loaf",
                "loaves",
            },
            "loaves": {
                "loaf",
                "loaves",
            },
            "cake": {
                "cake",
                "cakes",
            },
            "cakes": {
                "cake",
                "cakes",
            },
            "muffin": {
                "muffin",
                "muffins",
            },
            "muffins": {
                "muffin",
                "muffins",
            },
        }

        return aliases.get(
            word,
            {word},
        )

    # =========================================================
    # QUERY BUILDER
    # =========================================================

    @classmethod
    def _build_queries(
        cls,
        recipe_title: str,
    ) -> list[str]:
        """
        Build progressively broader TheMealDB queries.
        """

        normalized = cls._normalize(
            recipe_title
        )

        if not normalized:
            return []

        tokens = cls._tokens(
            recipe_title
        )

        queries: list[str] = []

        # -----------------------------------------------------
        # 1. Full title
        # -----------------------------------------------------

        queries.append(
            normalized
        )

        # -----------------------------------------------------
        # 2. Reduced title
        # -----------------------------------------------------

        if tokens:

            reduced = " ".join(
                tokens
            )

            if reduced not in queries:

                queries.append(
                    reduced
                )

        # -----------------------------------------------------
        # 3. Last two important words
        # -----------------------------------------------------

        if len(tokens) >= 2:

            last_two = " ".join(
                tokens[-2:]
            )

            if last_two not in queries:

                queries.append(
                    last_two
                )

        # -----------------------------------------------------
        # 4. First two important words
        # -----------------------------------------------------

        if len(tokens) >= 2:

            first_two = " ".join(
                tokens[:2]
            )

            if first_two not in queries:

                queries.append(
                    first_two
                )

        # -----------------------------------------------------
        # 5. Individual important words
        # -----------------------------------------------------

        for token in tokens:

            if len(token) < 4:
                continue

            if token not in queries:

                queries.append(
                    token
                )

        # -----------------------------------------------------
        # 6. Singular/plural variants
        # -----------------------------------------------------

        for token in tokens:

            equivalents = (
                cls._equivalent_words(
                    token
                )
            )

            for equivalent in equivalents:

                if (
                    equivalent
                    not in queries
                ):

                    queries.append(
                        equivalent
                    )

        # -----------------------------------------------------
        # Remove duplicates
        # -----------------------------------------------------

        unique_queries: list[str] = []

        seen: set[str] = set()

        for query in queries:

            query = query.strip()

            if not query:
                continue

            if query in seen:
                continue

            seen.add(
                query
            )

            unique_queries.append(
                query
            )

        return unique_queries

    # =========================================================
    # SCORE CANDIDATE
    # =========================================================

    @classmethod
    def _score_candidate(
        cls,
        recipe_title: str,
        candidate_title: str,
    ) -> int:
        """
        Calculate the relevance score.

        The score rewards:

        - exact title matches
        - title containment
        - matching ingredients/food terms
        - phrases
        - singular/plural equivalents
        """

        recipe_normalized = cls._normalize(
            recipe_title
        )

        candidate_normalized = cls._normalize(
            candidate_title
        )

        recipe_tokens = cls._tokens(
            recipe_title
        )

        candidate_tokens = cls._tokens(
            candidate_title
        )

        if not recipe_tokens:
            return 0

        if not candidate_tokens:
            return 0

        recipe_set = set(
            recipe_tokens
        )

        candidate_set = set(
            candidate_tokens
        )

        score = 0

        # -----------------------------------------------------
        # Exact normalized title
        # -----------------------------------------------------

        if (
            recipe_normalized
            == candidate_normalized
        ):

            score += 150

        # -----------------------------------------------------
        # Full recipe title contained in candidate
        # -----------------------------------------------------

        if (
            recipe_normalized
            and recipe_normalized
            in candidate_normalized
        ):

            score += 70

        # -----------------------------------------------------
        # Candidate title contained in recipe
        # -----------------------------------------------------

        if (
            candidate_normalized
            and candidate_normalized
            in recipe_normalized
        ):

            score += 50

        # -----------------------------------------------------
        # Direct token matches
        # -----------------------------------------------------

        matched = (
            recipe_set
            & candidate_set
        )

        for token in matched:

            if len(token) >= 7:

                score += 30

            elif len(token) >= 5:

                score += 20

            elif len(token) >= 3:

                score += 10

        # -----------------------------------------------------
        # Singular/plural matches
        # -----------------------------------------------------

        for recipe_token in recipe_tokens:

            equivalent_words = (
                cls._equivalent_words(
                    recipe_token
                )
            )

            if (
                candidate_set
                & equivalent_words
            ):

                if recipe_token not in matched:

                    score += 15

        # -----------------------------------------------------
        # Phrase matching
        # -----------------------------------------------------

        candidate_text = " ".join(
            candidate_tokens
        )

        if len(recipe_tokens) >= 2:

            for size in (
                3,
                2,
            ):

                if len(recipe_tokens) < size:
                    continue

                for index in range(
                    len(recipe_tokens)
                    - size
                    + 1
                ):

                    phrase = " ".join(
                        recipe_tokens[
                            index:index + size
                        ]
                    )

                    if phrase in candidate_text:

                        score += (
                            25 * size
                        )

        return score

    # =========================================================
    # GENERIC CANDIDATE CHECK
    # =========================================================

    @classmethod
    def _is_generic_candidate(
        cls,
        recipe_title: str,
        candidate_title: str,
    ) -> bool:
        """
        Determine whether a candidate is too generic.

        Example:

            Recipe:
                potato pancakes

            Candidate:
                pancakes

        This should be rejected because the candidate
        loses the important 'potato' qualifier.
        """

        recipe_tokens = cls._tokens(
            recipe_title
        )

        candidate_tokens = cls._tokens(
            candidate_title
        )

        if not recipe_tokens:
            return True

        if not candidate_tokens:
            return True

        recipe_set = set(
            recipe_tokens
        )

        candidate_set = set(
            candidate_tokens
        )

        # -----------------------------------------------------
        # Exact match is never generic
        # -----------------------------------------------------

        if (
            cls._normalize(recipe_title)
            == cls._normalize(candidate_title)
        ):
            return False

        # -----------------------------------------------------
        # If candidate has fewer tokens than recipe,
        # make sure it preserves the important information.
        # -----------------------------------------------------

        if len(candidate_tokens) < len(recipe_tokens):

            missing_tokens = []

            for token in recipe_tokens:

                equivalent = (
                    cls._equivalent_words(
                        token
                    )
                )

                if not (
                    candidate_set
                    & equivalent
                ):

                    missing_tokens.append(
                        token
                    )

            # -------------------------------------------------
            # Missing a meaningful qualifier means generic.
            # -------------------------------------------------

            if missing_tokens:

                return True

        # -----------------------------------------------------
        # Single-token candidates for multi-token recipes
        # -----------------------------------------------------

        if (
            len(recipe_tokens) >= 2
            and len(candidate_tokens) == 1
        ):

            candidate_token = (
                candidate_tokens[0]
            )

            equivalent = (
                cls._equivalent_words(
                    candidate_token
                )
            )

            # Accept only if the single candidate
            # represents the main concept and there
            # are no important missing qualifiers.
            for token in recipe_tokens:

                if (
                    equivalent
                    & cls._equivalent_words(
                        token
                    )
                ):

                    continue

                return True

        return False

    # =========================================================
    # API REQUEST
    # =========================================================

    def _search_query(
        self,
        query: str,
    ) -> list[dict]:
        """
        Execute one TheMealDB search query.
        """

        try:

            response = self.session.get(
                self.API_URL,
                params={
                    "s": query,
                },
                timeout=SEARCH_TIMEOUT,
            )

            response.raise_for_status()

            data = response.json()

        except requests.Timeout as exc:

            print(
                f"  TheMealDB timeout: "
                f"{exc}"
            )

            return []

        except requests.RequestException as exc:

            print(
                f"  TheMealDB request failed: "
                f"{exc}"
            )

            return []

        except ValueError:

            print(
                "  TheMealDB returned "
                "invalid JSON."
            )

            return []

        meals = data.get(
            "meals"
        )

        if not meals:
            return []

        return meals

    # =========================================================
    # SEARCH
    # =========================================================

    def search(
        self,
        recipe_title: str,
    ) -> ImageResult | None:
        """
        Search TheMealDB using multiple queries
        and return the best high-confidence image.
        """

        queries = self._build_queries(
            recipe_title
        )

        if not queries:

            print(
                "  TheMealDB: "
                "no valid search queries."
            )

            return None

        best_meal = None
        best_score = 0

        seen_meals: set[str] = set()

        for query in queries:

            print(
                f"  TheMealDB query: "
                f"{query}"
            )

            meals = self._search_query(
                query
            )

            for meal in meals:

                meal_name = (
                    meal.get(
                        "strMeal"
                    )
                    or ""
                ).strip()

                image_url = (
                    meal.get(
                        "strMealThumb"
                    )
                    or ""
                ).strip()

                if not meal_name:
                    continue

                if not image_url:
                    continue

                meal_key = (
                    self._normalize(
                        meal_name
                    )
                )

                if meal_key in seen_meals:
                    continue

                seen_meals.add(
                    meal_key
                )

                # -------------------------------------------------
                # Reject generic candidates
                # -------------------------------------------------

                if self._is_generic_candidate(
                    recipe_title,
                    meal_name,
                ):

                    print(
                        f"  TheMealDB rejected "
                        f"generic candidate: "
                        f"{meal_name}"
                    )

                    continue

                score = self._score_candidate(
                    recipe_title,
                    meal_name,
                )

                if score > best_score:

                    best_score = score

                    best_meal = (
                        meal_name,
                        image_url,
                    )

            # -------------------------------------------------
            # Strong match found
            # -------------------------------------------------

            if (
                best_meal is not None
                and best_score >= 120
            ):

                break

        # =====================================================
        # No candidate
        # =====================================================

        if best_meal is None:

            print(
                "  TheMealDB: "
                "no suitable image candidate."
            )

            return None

        meal_name, image_url = (
            best_meal
        )

        print(
            f"  TheMealDB best score: "
            f"{best_score}"
        )

        print(
            f"  TheMealDB candidate: "
            f"{meal_name}"
        )

        # =====================================================
        # Confidence threshold
        # =====================================================

        if best_score < self.MIN_SCORE:

            print(
                "  TheMealDB: candidate "
                "did not pass confidence "
                "threshold."
            )

            return None

        print(
            "  TheMealDB: suitable "
            "image found."
        )

        return ImageResult(
            url=image_url,
            mime_type="image/jpeg",
        )