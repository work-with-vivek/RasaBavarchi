from __future__ import annotations

import re
import time

import requests

from ..image_import_config import (
    SEARCH_TIMEOUT,
    USER_AGENT,
)
from ..image_search_aliases import get_search_aliases
from ..recipe_title_cleaner import (
    clean_recipe_title,
    get_clean_title_variants,
)

from .base import ImageProvider, ImageResult


class OpenverseProvider(ImageProvider):
    """
    Openverse image provider for recipe images.

    Main goals:

    1. Search recipe titles intelligently.
    2. Reject obviously unrelated/non-food results.
    3. Reject overly generic images.
    4. Support aliases and semantic title variants.
    5. Handle 401, 429, timeout and 5xx responses.
    6. Avoid using a persistent requests.Session for Openverse.
    """

    API_URL = "https://api.openverse.org/v1/images/"

    # ---------------------------------------------------------
    # SEARCH SETTINGS
    # ---------------------------------------------------------

    MIN_SCORE = 70

    MAX_RESULTS_PER_QUERY = 50

    MAX_QUERIES = 12

    RETRIES = 3

    RETRY_DELAYS = (
        2,
        4,
        8,
    )

    # Small delay between API queries.
    QUERY_DELAY = 0.35

    STOP_ON_RATE_LIMIT = True

    # ---------------------------------------------------------
    # STOP WORDS
    # ---------------------------------------------------------

    STOP_WORDS = {
        "a",
        "an",
        "and",
        "the",
        "of",
        "with",
        "for",
        "from",
        "to",
        "in",
        "on",
        "at",

        "my",
        "our",
        "s",

        "one",
        "two",
        "three",
        "four",
        "five",

        "kind",

        "grandma",
        "grandmother",
        "grandpa",
        "grandfather",

        "mrs",
        "mr",
        "miss",

        "recipe",
        "recipes",

        "food",
        "foods",

        "meal",
        "meals",

        "dish",
        "dishes",

        "photo",
        "photos",
        "image",
        "images",
        "picture",
        "pictures",

        "homemade",
        "easy",
        "quick",
        "best",
        "simple",

        "style",
        "version",
        "original",

        "stand",
        "restaurant",
        "bakery",
    }

    # ---------------------------------------------------------
    # GENERIC FOOD WORDS
    # ---------------------------------------------------------

    GENERIC_TOKENS = {
        "food",
        "foods",

        "dish",
        "dishes",

        "meal",
        "meals",

        "recipe",
        "recipes",

        "salad",
        "cake",
        "cakes",

        "soup",
        "soups",

        "bread",
        "breads",

        "cookie",
        "cookies",

        "dessert",
        "desserts",

        "drink",
        "drinks",

        "snack",
        "snacks",

        "side",
        "sides",
    }

    # ---------------------------------------------------------
    # GENERIC DISH NAMES
    # ---------------------------------------------------------

    GENERIC_ALIAS_WORDS = {
        "pizza",
        "pasta",

        "salad",
        "soup",

        "cake",
        "cakes",

        "bread",
        "breads",

        "pancake",
        "pancakes",

        "sandwich",
        "sandwiches",

        "taco",
        "tacos",

        "dip",
        "dips",

        "sauce",
        "sauces",

        "dessert",
        "desserts",

        "drink",
        "drinks",

        "smoothie",
        "smoothies",

        "shake",
        "shakes",

        "cookie",
        "cookies",
    }

    # ---------------------------------------------------------
    # DISH TYPES
    # ---------------------------------------------------------

    DISH_TYPES = {
        "salad",
        "soup",
        "soups",

        "stew",
        "stews",

        "cake",
        "cakes",

        "pie",
        "pies",

        "tart",
        "tarts",

        "pudding",
        "puddings",

        "casserole",
        "casseroles",

        "parfait",
        "parfaits",

        "pancake",
        "pancakes",

        "fritter",
        "fritters",

        "cookie",
        "cookies",

        "brownie",
        "brownies",

        "bread",
        "breads",

        "muffin",
        "muffins",

        "dip",
        "dips",

        "sauce",
        "sauces",

        "spread",
        "spreads",

        "drink",
        "drinks",

        "smoothie",
        "smoothies",

        "pasta",

        "pizza",

        "sandwich",
        "sandwiches",

        "wrap",
        "wraps",

        "taco",
        "tacos",

        "curry",
        "curries",

        "keema",

        "raita",

        "chutney",

        "dressing",
        "dressings",

        "spritzer",
        "spritzers",
    }

    # ---------------------------------------------------------
    # NON-FOOD TERMS
    # ---------------------------------------------------------

    NON_FOOD_WORDS = {
        "container",
        "containers",

        "box",
        "boxes",

        "packaging",
        "package",
        "packages",

        "bag",
        "bags",

        "basket",
        "baskets",

        "museum",
        "museums",

        "building",
        "buildings",

        "architecture",

        "church",
        "churches",

        "temple",
        "temples",

        "restaurant",
        "restaurants",

        "hotel",
        "hotels",

        "market",
        "markets",

        "store",
        "stores",

        "shop",
        "shops",

        "street",
        "streets",

        "road",
        "roads",

        "person",
        "people",

        "man",
        "men",

        "woman",
        "women",

        "child",
        "children",

        "cat",
        "cats",

        "dog",
        "dogs",

        "bird",
        "birds",

        "animal",
        "animals",

        "car",
        "cars",

        "truck",
        "trucks",

        "boat",
        "boats",

        "ship",
        "ships",

        "airplane",
        "airplanes",

        "statue",
        "statues",

        "sculpture",
        "sculptures",

        "monument",
        "monuments",

        "painting",
        "paintings",

        "portrait",
        "portraits",

        "map",
        "maps",

        "poster",
        "posters",

        "logo",
        "logos",

        "sign",
        "signs",

        "garden",
        "gardens",

        "landscape",
        "landscapes",

        "history",
        "architecture",
    }

    # =========================================================
    # INIT
    # =========================================================

    def __init__(self) -> None:
        """
        Initialize provider.

        We keep a Session available for compatibility with
        existing code, but Openverse API requests deliberately
        use requests.get() directly.
        """

        self.session = requests.Session()

        self.session.headers.update(
            {
                "User-Agent": USER_AGENT,
                "Accept": "application/json",
            }
        )

        self.rate_limited = False

    # =========================================================
    # NORMALIZE
    # =========================================================

    @staticmethod
    def _normalize(
        text: str,
    ) -> str:
        """
        Normalize text for matching/search.
        """

        text = (
            text or ""
        ).strip().lower()

        # Normalize curly apostrophe.
        text = text.replace(
            "’",
            "'",
        )

        # Possessives:
        #
        # bird's -> bird
        # grandma's -> grandma
        text = re.sub(
            r"([a-z])'s\b",
            r"\1",
            text,
        )

        # Remaining apostrophes.
        text = text.replace(
            "'",
            " ",
        )

        # Remove punctuation.
        text = re.sub(
            r"[^a-z0-9\s]",
            " ",
            text,
        )

        # Collapse whitespace.
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
        Return normalized tokens excluding stop words.
        """

        normalized = cls._normalize(
            text
        )

        return [
            token
            for token in normalized.split()
            if token
            and token not in cls.STOP_WORDS
        ]

    # =========================================================
    # CONTENT TOKENS
    # =========================================================

    @classmethod
    def _content_tokens(
        cls,
        text: str,
    ) -> list[str]:
        """
        Return meaningful recipe tokens.

        Generic words such as 'food', 'recipe' and 'salad'
        are excluded from identity scoring.
        """

        return [
            token
            for token in cls._tokens(
                text
            )
            if token
            not in cls.GENERIC_TOKENS
        ]

    # =========================================================
    # NON FOOD CANDIDATE
    # =========================================================

    @classmethod
    def _is_non_food_candidate(
        cls,
        candidate_title: str,
    ) -> bool:
        """
        Reject obvious non-food results.
        """

        normalized = cls._normalize(
            candidate_title
        )

        if not normalized:
            return True

        tokens = set(
            normalized.split()
        )

        if (
            tokens
            & cls.NON_FOOD_WORDS
        ):
            return True

        blocked_phrases = (
            "food container",
            "storage container",
            "plastic container",
            "glass container",

            "food museum",
            "food store",
            "food market",

            "restaurant menu",

            "street food market",

            "food drive",

            "food groups",

            "bird food",
            "cat food",
            "dog food",

            "food truck",
        )

        for phrase in blocked_phrases:

            if phrase in normalized:
                return True

        return False

    # =========================================================
    # GENERIC CANDIDATE
    # =========================================================

    @classmethod
    def _is_generic_candidate(
        cls,
        recipe_title: str,
        candidate_title: str,
    ) -> bool:
        """
        Reject candidates that are too generic to confidently
        represent the requested recipe.
        """

        recipe_normalized = cls._normalize(
            recipe_title
        )

        candidate_normalized = cls._normalize(
            candidate_title
        )

        if not recipe_normalized:
            return True

        if not candidate_normalized:
            return True

        # Exact title is safe.
        if (
            recipe_normalized
            == candidate_normalized
        ):
            return False

        recipe_tokens = cls._content_tokens(
            recipe_title
        )

        candidate_tokens = cls._content_tokens(
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

        matched = (
            recipe_set
            & candidate_set
        )

        # -----------------------------------------------------
        # Dish-type mismatch.
        # -----------------------------------------------------

        recipe_dish_types = {
            token
            for token in recipe_normalized.split()
            if token in cls.DISH_TYPES
        }

        candidate_normalized_tokens = set(
            candidate_normalized.split()
        )

        if recipe_dish_types:

            if not (
                recipe_dish_types
                & candidate_normalized_tokens
            ):

                return True

        # -----------------------------------------------------
        # Candidate is just a generic dish.
        # -----------------------------------------------------

        if (
            len(candidate_set)
            == 1
            and candidate_set.issubset(
                cls.GENERIC_ALIAS_WORDS
            )
        ):

            return True

        # -----------------------------------------------------
        # Recipe has multiple meaningful words but
        # candidate only matches one.
        # -----------------------------------------------------

        if (
            len(recipe_set)
            >= 2
            and len(matched)
            == 1
        ):

            return True

        return False

    # =========================================================
    # UNSAFE ALIAS
    # =========================================================

    @classmethod
    def _is_unsafe_alias(
        cls,
        recipe_title: str,
        alias: str,
    ) -> bool:
        """
        Prevent overly broad aliases.

        Example:

            pizza

        should not be used as the sole identity for:

            pizza possibilities
        """

        original_tokens = set(
            cls._content_tokens(
                recipe_title
            )
        )

        alias_tokens = set(
            cls._content_tokens(
                alias
            )
        )

        if not alias_tokens:
            return True

        if (
            len(alias_tokens)
            == 1
            and alias_tokens.issubset(
                cls.GENERIC_ALIAS_WORDS
            )
        ):

            return True

        if (
            len(alias_tokens)
            < len(original_tokens)
            and alias_tokens.issubset(
                cls.GENERIC_ALIAS_WORDS
            )
        ):

            return True

        return False

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
        Score how strongly a candidate title matches
        the recipe title.
        """

        recipe_normalized = cls._normalize(
            recipe_title
        )

        candidate_normalized = cls._normalize(
            candidate_title
        )

        if not recipe_normalized:
            return 0

        if not candidate_normalized:
            return 0

        # Exact title.
        if (
            recipe_normalized
            == candidate_normalized
        ):

            return 500

        recipe_content = cls._content_tokens(
            recipe_title
        )

        candidate_content = cls._content_tokens(
            candidate_title
        )

        if not recipe_content:
            return 0

        if not candidate_content:
            return 0

        recipe_set = set(
            recipe_content
        )

        candidate_set = set(
            candidate_content
        )

        matched = (
            recipe_set
            & candidate_set
        )

        if not matched:
            return 0

        score = 0

        # -----------------------------------------------------
        # Full recipe phrase.
        # -----------------------------------------------------

        if (
            recipe_normalized
            in candidate_normalized
        ):

            score += 180

        # -----------------------------------------------------
        # Candidate phrase inside recipe.
        # -----------------------------------------------------

        if (
            candidate_normalized
            in recipe_normalized
        ):

            score += 100

        # -----------------------------------------------------
        # Token weights.
        # -----------------------------------------------------

        for token in matched:

            if len(token) >= 9:

                score += 55

            elif len(token) >= 7:

                score += 45

            elif len(token) >= 5:

                score += 25

            else:

                score += 8

        # -----------------------------------------------------
        # Recipe coverage.
        # -----------------------------------------------------

        coverage = (
            len(matched)
            / len(recipe_set)
        )

        if coverage >= 1.0:

            score += 120

        elif coverage >= 0.75:

            score += 80

        elif coverage >= 0.50:

            score += 35

        elif coverage >= 0.33:

            score += 10

        # -----------------------------------------------------
        # Phrase matches.
        # -----------------------------------------------------

        candidate_text = " ".join(
            candidate_content
        )

        for size in (
            5,
            4,
            3,
            2,
        ):

            if (
                len(recipe_content)
                < size
            ):

                continue

            for index in range(
                len(recipe_content)
                - size
                + 1
            ):

                phrase = " ".join(
                    recipe_content[
                        index:index + size
                    ]
                )

                if phrase in candidate_text:

                    score += (
                        35
                        * size
                    )

        # -----------------------------------------------------
        # Single-token penalty.
        # -----------------------------------------------------

        if (
            len(recipe_set)
            >= 2
            and len(matched)
            == 1
        ):

            score -= 60

        return max(
            score,
            0,
        )

    # =========================================================
    # SINGULARIZE
    # =========================================================

    @staticmethod
    def _singularize_word(
        word: str,
    ) -> str:
        """
        Basic singularization for search variants.
        """

        if (
            word.endswith("ies")
            and len(word) > 4
        ):

            return (
                word[:-3]
                + "y"
            )

        if (
            word.endswith("ches")
            and len(word) > 5
        ):

            return word[:-2]

        if (
            word.endswith("shes")
            and len(word) > 5
        ):

            return word[:-2]

        if (
            word.endswith("ses")
            and len(word) > 4
        ):

            return word[:-2]

        if (
            word.endswith("s")
            and not word.endswith("ss")
            and len(word) > 3
        ):

            return word[:-1]

        return word

    # =========================================================
    # SEMANTIC VARIANTS
    # =========================================================

    def _build_semantic_variants(
        self,
        title: str,
    ) -> list[str]:
        """
        Generate useful fallback search variants.
        """

        normalized = self._normalize(
            title
        )

        tokens = self._content_tokens(
            title
        )

        variants: list[str] = []

        def add(
            value: str,
        ) -> None:

            value = self._normalize(
                value
            )

            if not value:
                return

            if value not in variants:

                variants.append(
                    value
                )

        add(
            normalized
        )

        if tokens:

            add(
                " ".join(tokens)
            )

        filtered = [
            token
            for token in tokens
            if token not in {
                "family",
                "familys",
                "grandma",
                "grandmother",
                "grandpa",
                "grandfather",
            }
        ]

        if filtered:

            add(
                " ".join(filtered)
            )

        singular_tokens = [
            self._singularize_word(
                token
            )
            for token in tokens
        ]

        if singular_tokens:

            add(
                " ".join(
                    singular_tokens
                )
            )

        # -----------------------------------------------------
        # Dish + important ingredient.
        # -----------------------------------------------------

        dish_tokens = [
            token
            for token in tokens
            if token in self.DISH_TYPES
        ]

        important_tokens = [
            token
            for token in tokens
            if token not in self.DISH_TYPES
            and len(token) >= 4
        ]

        if (
            dish_tokens
            and important_tokens
        ):

            dish = dish_tokens[-1]

            for token in important_tokens[:3]:

                add(
                    f"{token} {dish}"
                )

        # -----------------------------------------------------
        # Important ingredient pairs.
        # -----------------------------------------------------

        if len(important_tokens) >= 2:

            add(
                " ".join(
                    important_tokens[:2]
                )
            )

            add(
                " ".join(
                    important_tokens[-2:]
                )
            )

        return variants

    # =========================================================
    # BUILD QUERIES
    # =========================================================

    def _build_queries(
        self,
        recipe_title: str,
    ) -> list[str]:
        """
        Build a compact list of high-value Openverse queries.

        We deliberately limit this because Openverse requests
        are relatively slow and the database contains hundreds
        of thousands of recipes.
        """

        queries: list[str] = []

        def add_query(
            value: str,
        ) -> None:

            value = self._normalize(
                value
            )

            if not value:
                return

            if value in queries:
                return

            queries.append(
                value
            )

        # -----------------------------------------------------
        # Title variants.
        # -----------------------------------------------------

        title_variants = (
            get_clean_title_variants(
                recipe_title
            )
        )

        # Prefer title + food.
        for variant in title_variants:

            add_query(
                f"{variant} food"
            )

        # Exact title.
        for variant in title_variants:

            add_query(
                variant
            )

        # -----------------------------------------------------
        # Alias queries.
        # -----------------------------------------------------

        aliases = get_search_aliases(
            recipe_title
        )

        for alias in aliases:

            if self._is_unsafe_alias(
                recipe_title,
                alias,
            ):

                continue

            add_query(
                f"{alias} food"
            )

        # -----------------------------------------------------
        # Semantic variants.
        # -----------------------------------------------------

        for variant in self._build_semantic_variants(
            recipe_title
        ):

            add_query(
                f"{variant} food"
            )

        # -----------------------------------------------------
        # Return compact query budget.
        # -----------------------------------------------------

        return queries[
            : self.MAX_QUERIES
        ]

    # =========================================================
    # OPENVERSE HTTP REQUEST
    # =========================================================

    def _request(
        self,
        query: str,
    ) -> dict | None:
        """
        Execute one Openverse API request.

        IMPORTANT:
        We intentionally use requests.get() instead of
        self.session.get().

        Direct requests.get() was verified against the
        Openverse API and returned HTTP 200, while the
        previous persistent Session implementation was
        producing HTTP 401 responses.
        """

        params = {
            "q": query,
            "page_size": (
                self.MAX_RESULTS_PER_QUERY
            ),
            "license_type": "commercial",
        }

        headers = {
            "User-Agent": "RasaBavarchi/1.0",
            "Accept": "application/json",
        }

        for attempt in range(
            1,
            self.RETRIES + 1,
        ):

            try:

                response = requests.get(
                    self.API_URL,
                    params=params,
                    headers=headers,
                    timeout=(5, 30),
                )

                # -------------------------------------------------
                # SUCCESS
                # -------------------------------------------------

                if response.status_code == 200:

                    try:

                        return response.json()

                    except ValueError:

                        print(
                            "  Openverse returned "
                            "invalid JSON."
                        )

                        return None

                # -------------------------------------------------
                # AUTHENTICATION
                # -------------------------------------------------

                if response.status_code == 401:

                    print(
                        "  Openverse: "
                        "401 Unauthorized."
                    )

                    print(
                        "  API request rejected."
                    )

                    return None

                # -------------------------------------------------
                # RATE LIMIT
                # -------------------------------------------------

                if response.status_code == 429:

                    retry_after = (
                        response.headers.get(
                            "Retry-After"
                        )
                    )

                    try:

                        delay = float(
                            retry_after
                        )

                    except (
                        TypeError,
                        ValueError,
                    ):

                        delay = (
                            10
                            * attempt
                        )

                    if (
                        attempt
                        < self.RETRIES
                    ):

                        print(
                            "  Openverse rate "
                            "limited "
                            f"(attempt "
                            f"{attempt}/"
                            f"{self.RETRIES}). "
                            f"Waiting "
                            f"{delay:.1f}s..."
                        )

                        time.sleep(
                            delay
                        )

                        continue

                    print(
                        "  Openverse: rate "
                        "limit persisted "
                        "after retries."
                    )

                    self.rate_limited = True

                    return None

                # -------------------------------------------------
                # SERVER ERROR
                # -------------------------------------------------

                if (
                    500
                    <= response.status_code
                    <= 599
                ):

                    if (
                        attempt
                        < self.RETRIES
                    ):

                        delay = (
                            self.RETRY_DELAYS[
                                attempt - 1
                            ]
                        )

                        print(
                            "  Openverse server "
                            f"error "
                            f"{response.status_code} "
                            f"(attempt "
                            f"{attempt}/"
                            f"{self.RETRIES}). "
                            f"Retrying in "
                            f"{delay}s..."
                        )

                        time.sleep(
                            delay
                        )

                        continue

                    print(
                        "  Openverse: server "
                        "error persisted."
                    )

                    return None

                # -------------------------------------------------
                # OTHER HTTP ERROR
                # -------------------------------------------------

                print(
                    "  Openverse HTTP error: "
                    f"{response.status_code}"
                )

                return None

            # -----------------------------------------------------
            # TIMEOUT
            # -----------------------------------------------------

            except requests.Timeout:

                if (
                    attempt
                    < self.RETRIES
                ):

                    delay = (
                        self.RETRY_DELAYS[
                            attempt - 1
                        ]
                    )

                    print(
                        "  Openverse timeout "
                        f"(attempt "
                        f"{attempt}/"
                        f"{self.RETRIES}). "
                        f"Retrying in "
                        f"{delay}s..."
                    )

                    time.sleep(
                        delay
                    )

                    continue

                print(
                    "  Openverse: request "
                    "abandoned after retries."
                )

                return None

            # -----------------------------------------------------
            # CONNECTION ERROR
            # -----------------------------------------------------

            except requests.ConnectionError as exc:

                if (
                    attempt
                    < self.RETRIES
                ):

                    delay = (
                        self.RETRY_DELAYS[
                            attempt - 1
                        ]
                    )

                    print(
                        "  Openverse connection "
                        f"error "
                        f"(attempt "
                        f"{attempt}/"
                        f"{self.RETRIES}). "
                        f"Retrying in "
                        f"{delay}s..."
                    )

                    time.sleep(
                        delay
                    )

                    continue

                print(
                    "  Openverse connection "
                    f"failed: {exc}"
                )

                return None

            except requests.RequestException as exc:

                print(
                    "  Openverse request "
                    f"failed: {exc}"
                )

                return None

        return None

    # =========================================================
    # SEARCH
    # =========================================================

    def search(
        self,
        recipe_title: str,
    ) -> ImageResult | None:
        """
        Search Openverse for the best recipe image.
        """

        self.rate_limited = False

        original_title = (
            recipe_title
        )

        cleaned_title = (
            clean_recipe_title(
                recipe_title
            )
        )

        normalized_title = (
            self._normalize(
                cleaned_title
                or original_title
            )
        )

        if not normalized_title:

            return None

        print(
            "  Openverse original title: "
            f"{original_title}"
        )

        if (
            cleaned_title
            != original_title
        ):

            print(
                "  Openverse cleaned title: "
                f"{cleaned_title}"
            )

        queries = self._build_queries(
            original_title
        )

        best_score = 0

        best_candidate = None

        seen_urls: set[str] = set()

        # =====================================================
        # SEARCH QUERIES
        # =====================================================

        for query_index, query in enumerate(
            queries
        ):

            if (
                self.rate_limited
                and self.STOP_ON_RATE_LIMIT
            ):

                print(
                    "  Openverse: stopping "
                    "because API is rate limited."
                )

                break

            if query_index > 0:

                time.sleep(
                    self.QUERY_DELAY
                )

            print(
                "  Openverse query: "
                f"{query}"
            )

            data = self._request(
                query
            )

            if (
                self.rate_limited
                and self.STOP_ON_RATE_LIMIT
            ):

                break

            if not data:

                continue

            results = data.get(
                "results",
                [],
            )

            for item in results:

                candidate_title = (
                    item.get(
                        "title"
                    )
                    or ""
                ).strip()

                image_url = (
                    item.get(
                        "thumbnail"
                    )
                    or item.get(
                        "url"
                    )
                    or ""
                ).strip()

                mime_type = (
                    item.get(
                        "mimetype"
                    )
                    or "image/jpeg"
                ).strip().lower()

                if not candidate_title:

                    continue

                if not image_url:

                    continue

                if image_url in seen_urls:

                    continue

                seen_urls.add(
                    image_url
                )

                # -------------------------------------------------
                # NON FOOD
                # -------------------------------------------------

                if self._is_non_food_candidate(
                    candidate_title
                ):

                    print(
                        "  Openverse rejected "
                        "non-food candidate: "
                        f"{candidate_title}"
                    )

                    continue

                # -------------------------------------------------
                # GENERIC
                # -------------------------------------------------

                if self._is_generic_candidate(
                    original_title,
                    candidate_title,
                ):

                    print(
                        "  Openverse rejected "
                        "generic candidate: "
                        f"{candidate_title}"
                    )

                    continue

                # -------------------------------------------------
                # SCORE AGAINST ORIGINAL
                # -------------------------------------------------

                original_score = (
                    self._score_candidate(
                        original_title,
                        candidate_title,
                    )
                )

                # -------------------------------------------------
                # SCORE AGAINST CLEANED
                # -------------------------------------------------

                cleaned_score = (
                    self._score_candidate(
                        cleaned_title
                        or original_title,
                        candidate_title,
                    )
                )

                score = max(
                    original_score,
                    cleaned_score,
                )

                if score > best_score:

                    best_score = score

                    best_candidate = (
                        candidate_title,
                        image_url,
                        mime_type,
                    )

        # =====================================================
        # NO CANDIDATE
        # =====================================================

        if best_candidate is None:

            print(
                "  Openverse: no suitable "
                "image found."
            )

            return None

        (
            candidate_title,
            image_url,
            mime_type,
        ) = best_candidate

        print(
            "  Openverse best score: "
            f"{best_score}"
        )

        print(
            "  Openverse candidate: "
            f"{candidate_title}"
        )

        # =====================================================
        # ALIAS VALIDATION
        # =====================================================

        aliases = get_search_aliases(
            original_title
        )

        candidate_aliases: list[str] = []

        candidate_aliases.append(
            original_title
        )

        if (
            cleaned_title
            and cleaned_title
            != original_title
        ):

            candidate_aliases.append(
                cleaned_title
            )

        for alias in aliases:

            if (
                alias
                not in candidate_aliases
            ):

                candidate_aliases.append(
                    alias
                )

        for variant in self._build_semantic_variants(
            cleaned_title
            or original_title
        ):

            if (
                variant
                not in candidate_aliases
            ):

                candidate_aliases.append(
                    variant
                )

        best_alias_score = 0

        best_alias = (
            cleaned_title
            or original_title
        )

        best_alias_coverage = 0.0

        candidate_content = set(
            self._content_tokens(
                candidate_title
            )
        )

        # =====================================================
        # ALIAS SCORING
        # =====================================================

        for alias in candidate_aliases:

            if self._is_unsafe_alias(
                original_title,
                alias,
            ):

                print(
                    "  Openverse skipped "
                    "unsafe alias: "
                    f"{alias}"
                )

                continue

            alias_content = (
                self._content_tokens(
                    alias
                )
            )

            if not alias_content:

                continue

            if not candidate_content:

                continue

            alias_set = set(
                alias_content
            )

            matched_alias_tokens = (
                alias_set
                & candidate_content
            )

            coverage = (
                len(
                    matched_alias_tokens
                )
                / len(alias_set)
            )

            alias_score = (
                self._score_candidate(
                    alias,
                    candidate_title,
                )
            )

            if (
                alias_score
                > best_alias_score
            ):

                best_alias_score = (
                    alias_score
                )

                best_alias = alias

                best_alias_coverage = (
                    coverage
                )

        print(
            "  Openverse best alias: "
            f"{best_alias}"
        )

        print(
            "  Openverse alias score: "
            f"{best_alias_score}"
        )

        print(
            "  Openverse alias coverage: "
            f"{best_alias_coverage:.2f}"
        )

        # =====================================================
        # FINAL CONTENT SETS
        # =====================================================

        original_content = set(
            self._content_tokens(
                original_title
            )
        )

        cleaned_content = set(
            self._content_tokens(
                cleaned_title
                or original_title
            )
        )

        alias_content = set(
            self._content_tokens(
                best_alias
            )
        )

        # =====================================================
        # GENERIC FINAL GUARD
        # =====================================================

        if (
            len(candidate_content)
            == 1
            and candidate_content.issubset(
                self.GENERIC_ALIAS_WORDS
            )
            and len(cleaned_content)
            > 1
        ):

            print(
                "  Openverse rejected "
                "generic final candidate: "
                f"{candidate_title}"
            )

            return None

        # =====================================================
        # GENERIC ALIAS GUARD
        # =====================================================

        if (
            len(alias_content)
            == 1
            and alias_content.issubset(
                self.GENERIC_ALIAS_WORDS
            )
            and len(cleaned_content)
            > 1
        ):

            print(
                "  Openverse rejected "
                "generic shortened alias: "
                f"{best_alias}"
            )

            return None

        # =====================================================
        # ALIAS OVERLAP
        # =====================================================

        if alias_content:

            alias_match_count = len(
                alias_content
                & candidate_content
            )

            alias_coverage = (
                alias_match_count
                / len(alias_content)
            )

            if len(alias_content) <= 2:

                if (
                    alias_match_count
                    < 1
                ):

                    print(
                        "  Openverse rejected "
                        "candidate: no alias "
                        "overlap."
                    )

                    return None

            else:

                if (
                    alias_coverage
                    < 0.50
                ):

                    print(
                        "  Openverse rejected "
                        "candidate: insufficient "
                        "alias coverage."
                    )

                    return None

        # =====================================================
        # CLEANED TITLE COVERAGE
        # =====================================================

        if len(cleaned_content) >= 2:

            cleaned_matches = (
                cleaned_content
                & candidate_content
            )

            cleaned_coverage = (
                len(cleaned_matches)
                / len(cleaned_content)
            )

            exact_cleaned_title = (
                self._normalize(
                    cleaned_title
                    or original_title
                )
                == self._normalize(
                    candidate_title
                )
            )

            if (
                not exact_cleaned_title
                and cleaned_coverage
                < 0.50
            ):

                print(
                    "  Openverse rejected "
                    "candidate: insufficient "
                    "cleaned-title coverage."
                )

                return None

        # =====================================================
        # ORIGINAL TITLE COVERAGE
        # =====================================================

        if len(original_content) >= 2:

            original_matches = (
                original_content
                & candidate_content
            )

            original_coverage = (
                len(original_matches)
                / len(original_content)
            )

            exact_original_title = (
                self._normalize(
                    original_title
                )
                == self._normalize(
                    candidate_title
                )
            )

            if (
                not exact_original_title
                and original_coverage
                < 0.50
                and len(cleaned_content)
                >= 2
            ):

                cleaned_matches = (
                    cleaned_content
                    & candidate_content
                )

                cleaned_coverage = (
                    len(cleaned_matches)
                    / len(cleaned_content)
                )

                if (
                    cleaned_coverage
                    < 0.50
                ):

                    print(
                        "  Openverse rejected "
                        "candidate: insufficient "
                        "recipe identity."
                    )

                    return None

        # =====================================================
        # FINAL SCORE
        # =====================================================

        if (
            best_alias_score
            < self.MIN_SCORE
        ):

            print(
                "  Openverse: best result "
                "did not pass confidence "
                "threshold."
            )

            return None

        # =====================================================
        # SUCCESS
        # =====================================================

        print(
            "  Openverse: suitable "
            "image found."
        )

        return ImageResult(
            url=image_url,
            mime_type=mime_type,
        )