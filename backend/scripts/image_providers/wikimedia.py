import re
import time

import requests

from ..image_import_config import (
    ALLOWED_MIME_TYPES,
    RATE_LIMIT_BACKOFF_SECONDS,
    REQUEST_DELAY_SECONDS,
    SEARCH_RESULTS,
    SEARCH_TIMEOUT,
    THUMBNAIL_WIDTH,
    USER_AGENT,
    WIKIMEDIA_API_URL,
)

from .base import ImageProvider, ImageResult


class WikimediaProvider(ImageProvider):
    """
    Wikimedia Commons provider for recipe images.

    The provider is intentionally conservative:
    an image is accepted only when its title contains
    enough meaningful recipe-specific words.
    """

    def __init__(self) -> None:
        self.session = requests.Session()

        self.session.headers.update(
            {
                "User-Agent": USER_AGENT,
                "Accept": "application/json",
            }
        )

    # =========================================================
    # MIME
    # =========================================================

    @staticmethod
    def get_extension(
        mime_type: str,
    ) -> str | None:
        return ALLOWED_MIME_TYPES.get(mime_type)

    # =========================================================
    # NORMALIZATION
    # =========================================================

    @staticmethod
    def _normalize(
        text: str,
    ) -> list[str]:
        text = text.lower()

        text = re.sub(
            r"[^a-z0-9\s]",
            " ",
            text,
        )

        return [
            word
            for word in text.split()
            if len(word) > 2
        ]

    # =========================================================
    # WORD CATEGORIES
    # =========================================================

    @staticmethod
    def _generic_words() -> set[str]:
        return {
            "food",
            "dish",
            "recipe",
            "meal",
            "cooking",
            "cooked",
            "fresh",
            "homemade",
            "delicious",
            "easy",
            "best",
            "style",
            "type",
            "made",
            "home",
            "photo",
            "photograph",
            "image",
        }

    @staticmethod
    def _dish_words() -> set[str]:
        return {
            "cake",
            "cakes",
            "cupcake",
            "cupcakes",
            "pie",
            "pies",
            "bread",
            "breads",
            "cookie",
            "cookies",
            "brownie",
            "brownies",
            "salad",
            "soups",
            "soup",
            "stew",
            "pasta",
            "pizza",
            "sandwich",
            "sandwiches",
            "parfait",
            "parfaits",
            "raita",
            "curry",
            "rice",
            "roll",
            "rolls",
            "loaf",
            "loaves",
            "slushy",
            "smoothie",
            "pudding",
            "tart",
            "tarts",
            "muffin",
            "muffins",
        }

    @staticmethod
    def _ingredient_words() -> set[str]:
        return {
            "lemon",
            "lime",
            "orange",
            "apple",
            "banana",
            "berry",
            "berries",
            "watermelon",
            "strawberry",
            "blueberry",
            "raspberry",
            "blackberry",
            "peach",
            "mango",
            "pineapple",
            "chocolate",
            "vanilla",
            "caramel",
            "coffee",
            "coconut",
            "almond",
            "peanut",
            "walnut",
            "pecan",
            "pistachio",
            "hazelnut",
            "broccoli",
            "garlic",
            "onion",
            "tomato",
            "potato",
            "spinach",
            "watercress",
            "carrot",
            "cucumber",
            "pepper",
            "cheese",
            "cream",
            "butter",
            "yogurt",
            "milk",
            "chicken",
            "beef",
            "pork",
            "lamb",
            "turkey",
            "fish",
            "salmon",
            "tuna",
            "shrimp",
            "prawn",
            "egg",
            "eggs",
            "beans",
            "bean",
            "lentil",
            "lentils",
            "chickpea",
            "chickpeas",
        }

    # =========================================================
    # CANDIDATE VALIDATION
    # =========================================================

    @classmethod
    def _is_valid_candidate(
        cls,
        recipe_title: str,
        candidate_title: str,
    ) -> bool:
        """
        Determine whether the candidate is sufficiently
        specific to the recipe.
        """

        recipe_words = set(
            cls._normalize(recipe_title)
        )

        candidate_words = set(
            cls._normalize(candidate_title)
        )

        generic_words = cls._generic_words()
        dish_words = cls._dish_words()
        ingredient_words = cls._ingredient_words()

        # -----------------------------------------------------
        # Remove generic words
        # -----------------------------------------------------

        meaningful_recipe_words = (
            recipe_words
            - generic_words
        )

        if not meaningful_recipe_words:
            return False

        # -----------------------------------------------------
        # Ingredient validation
        # -----------------------------------------------------

        recipe_ingredients = (
            meaningful_recipe_words
            & ingredient_words
        )

        candidate_ingredients = (
            candidate_words
            & ingredient_words
        )

        if recipe_ingredients:

            matched_ingredients = (
                recipe_ingredients
                & candidate_ingredients
            )

            # Every explicit ingredient/flavor in a short
            # recipe title is important.
            #
            # Example:
            #
            # lemon cream cupcakes
            #
            # Candidate:
            # Boston Cream Cupcakes
            #
            # lemon is missing -> reject.
            #
            if (
                len(recipe_ingredients) <= 2
                and not recipe_ingredients.issubset(
                    candidate_ingredients
                )
            ):
                return False

            # For longer ingredient lists, require at least
            # half of the ingredient words.
            if len(recipe_ingredients) > 2:

                ratio = (
                    len(
                        recipe_ingredients
                        & candidate_ingredients
                    )
                    / len(recipe_ingredients)
                )

                if ratio < 0.5:
                    return False

        # -----------------------------------------------------
        # Dish validation
        # -----------------------------------------------------

        recipe_dishes = (
            meaningful_recipe_words
            & dish_words
        )

        candidate_dishes = (
            candidate_words
            & dish_words
        )

        # If recipe specifies a dish type, candidate should
        # normally contain that same dish type.
        if recipe_dishes:

            if not (
                recipe_dishes
                & candidate_dishes
            ):
                return False

        return True

    # =========================================================
    # SCORING
    # =========================================================

    @classmethod
    def _score_candidate(
        cls,
        recipe_title: str,
        candidate_title: str,
    ) -> int:
        """
        Score a candidate after validation.
        """

        if not cls._is_valid_candidate(
            recipe_title,
            candidate_title,
        ):
            return 0

        recipe_words = set(
            cls._normalize(recipe_title)
        )

        candidate_words = set(
            cls._normalize(candidate_title)
        )

        generic_words = cls._generic_words()
        dish_words = cls._dish_words()
        ingredient_words = cls._ingredient_words()

        recipe_ingredients = (
            recipe_words
            & ingredient_words
        )

        candidate_ingredients = (
            candidate_words
            & ingredient_words
        )

        recipe_dishes = (
            recipe_words
            & dish_words
        )

        candidate_dishes = (
            candidate_words
            & dish_words
        )

        recipe_other = (
            recipe_words
            - generic_words
            - ingredient_words
            - dish_words
        )

        candidate_other = (
            candidate_words
            - generic_words
            - ingredient_words
            - dish_words
        )

        ingredient_matches = (
            recipe_ingredients
            & candidate_ingredients
        )

        dish_matches = (
            recipe_dishes
            & candidate_dishes
        )

        other_matches = (
            recipe_other
            & candidate_other
        )

        score = 0

        # Strong ingredient match.
        score += (
            len(ingredient_matches)
            * 40
        )

        # Dish type.
        score += (
            len(dish_matches)
            * 15
        )

        # Other meaningful words.
        score += (
            len(other_matches)
            * 10
        )

        # Complete ingredient match.
        if recipe_ingredients:

            if recipe_ingredients.issubset(
                candidate_ingredients
            ):
                score += 30

        # Complete dish match.
        if recipe_dishes:

            if recipe_dishes.issubset(
                candidate_dishes
            ):
                score += 20

        return score

    # =========================================================
    # SEARCH
    # =========================================================

    def search(
        self,
        recipe_title: str,
    ) -> ImageResult | None:
        """
        Search Wikimedia Commons using multiple queries.
        """

        title = " ".join(
            recipe_title.split()
        )

        if not title:
            return None

        words = self._normalize(
            title
        )

        queries = [
            f"{title} food",
            f"{title} recipe",
            title,
        ]

        if len(words) >= 2:
            queries.append(
                " ".join(words)
            )

        if len(words) >= 3:
            queries.append(
                " ".join(words[-3:])
            )

        if len(words) >= 2:
            queries.append(
                " ".join(words[-2:])
            )

        queries = list(
            dict.fromkeys(queries)
        )

        candidates: list[
            tuple[int, ImageResult, str]
        ] = []

        # =====================================================
        # SEARCH
        # =====================================================

        for search_query in queries:

            params = {
                "action": "query",
                "generator": "search",
                "gsrsearch": search_query,
                "gsrnamespace": 6,
                "gsrlimit": SEARCH_RESULTS,
                "prop": "imageinfo",
                "iiprop": "url|mime|size",
                "iiurlwidth": THUMBNAIL_WIDTH,
                "format": "json",
            }

            try:

                response = self.session.get(
                    WIKIMEDIA_API_URL,
                    params=params,
                    timeout=SEARCH_TIMEOUT,
                )

                if response.status_code == 429:

                    print(
                        "  Wikimedia rate limit reached."
                    )

                    print(
                        f"  Waiting "
                        f"{RATE_LIMIT_BACKOFF_SECONDS:.0f}s..."
                    )

                    time.sleep(
                        RATE_LIMIT_BACKOFF_SECONDS
                    )

                    return None

                response.raise_for_status()

                data = response.json()

            except requests.RequestException as exc:

                print(
                    f"  Wikimedia request failed: "
                    f"{exc}"
                )

                continue

            except ValueError:

                print(
                    "  Wikimedia returned invalid JSON."
                )

                continue

            pages = (
                data
                .get("query", {})
                .get("pages", {})
            )

            # =================================================
            # CANDIDATES
            # =================================================

            for page in pages.values():

                image_info = page.get(
                    "imageinfo"
                )

                if not image_info:
                    continue

                info = image_info[0]

                mime_type = (
                    info.get("mime", "")
                    .strip()
                    .lower()
                )

                if mime_type not in ALLOWED_MIME_TYPES:
                    continue

                image_url = (
                    info.get("thumburl")
                    or info.get("url")
                )

                if not image_url:
                    continue

                candidate_title = (
                    page.get(
                        "title",
                        "",
                    )
                    .replace(
                        "File:",
                        "",
                    )
                )

                score = self._score_candidate(
                    recipe_title=title,
                    candidate_title=candidate_title,
                )

                if score <= 0:
                    continue

                candidates.append(
                    (
                        score,
                        ImageResult(
                            url=image_url,
                            mime_type=mime_type,
                        ),
                        candidate_title,
                    )
                )

        # =====================================================
        # NO VALID IMAGE
        # =====================================================

        if not candidates:
            print(
                "  No suitable image found."
            )

            return None

        # =====================================================
        # BEST IMAGE
        # =====================================================

        candidates.sort(
            key=lambda item: item[0],
            reverse=True,
        )

        best_score = candidates[0][0]
        best_result = candidates[0][1]
        best_title = candidates[0][2]

        print(
            f"  Best image score: "
            f"{best_score}"
        )

        print(
            f"  Candidate: "
            f"{best_title}"
        )

        # =====================================================
        # CONFIDENCE THRESHOLD
        # =====================================================

        minimum_score = 50

        if best_score < minimum_score:

            print(
                "  No image passed "
                "the confidence threshold."
            )

            return None

        time.sleep(
            REQUEST_DELAY_SECONDS
        )

        return best_result