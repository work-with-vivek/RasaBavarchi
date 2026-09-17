from __future__ import annotations

import re
import time
import requests

from ..ingredient_image_config import (
    ALLOWED_MIME_TYPES,
    MINIMUM_SCORE,
    REQUEST_DELAY_SECONDS,
    SEARCH_RESULTS,
    SEARCH_TIMEOUT,
    THUMBNAIL_WIDTH,
    USER_AGENT,
    WIKIMEDIA_API_URL,
)
from ..ingredient_image_name import get_ingredient_image_queries
from .base import ImageProvider, ImageResult


class WikimediaRateLimitError(Exception):
    """
    Raised when Wikimedia tells us to stop making requests.
    """

    pass


class IngredientWikimediaProvider(ImageProvider):
    """
    Wikimedia Commons provider for ingredient reference images.

    Goals:
        - find an image of the ingredient itself
        - reject dishes and recipes
        - reject scientific/process images
        - reject non-food objects
        - reject different compound ingredients
        - use at most two searches per canonical ingredient
        - stop immediately on Wikimedia HTTP 429
    """

    # =========================================================
    # SETTINGS
    # =========================================================

    RATE_LIMIT_COOLDOWN_SECONDS = 60

    # =========================================================
    # IN-PROCESS SUCCESS CACHE
    # =========================================================

    _image_cache: dict[str, ImageResult] = {}

    # =========================================================
    # INIT
    # =========================================================

    def __init__(self) -> None:
        self.session = requests.Session()

        self.session.headers.update(
            {
                "User-Agent": USER_AGENT,
                "Accept": "application/json",
            }
        )

        self._rate_limited_until = 0.0

    # =========================================================
    # NORMALIZATION
    # =========================================================

    @staticmethod
    def _normalize(value: str) -> str:
        """
        Normalize text for comparison.
        """

        value = (value or "").lower()

        value = re.sub(
            r"[^a-z0-9\s]",
            " ",
            value,
        )

        value = re.sub(
            r"\s+",
            " ",
            value,
        )

        return value.strip()

    @classmethod
    def _tokens(cls, value: str) -> set[str]:
        """
        Convert text into normalized tokens.
        """

        return {
            token
            for token in cls._normalize(value).split()
            if len(token) > 1
        }

    # =========================================================
    # GENERIC WORDS
    # =========================================================

    @staticmethod
    def _generic_words() -> set[str]:
        """
        Words with little ingredient-specific meaning.
        """

        return {
            "food",
            "ingredient",
            "ingredients",
            "fresh",
            "freshly",
            "raw",
            "cooked",
            "organic",
            "natural",
            "whole",
            "piece",
            "pieces",
            "photo",
            "photograph",
            "image",
            "images",
            "commons",
            "jpg",
            "jpeg",
            "png",
            "file",
        }

    # =========================================================
    # POSITIVE FOOD WORDS
    # =========================================================

    @staticmethod
    def _positive_food_words() -> set[str]:
        """
        Words that generally indicate food or ingredients.
        """

        return {
            "food",
            "ingredient",
            "ingredients",

            # Dairy
            "milk",
            "cheese",
            "butter",
            "cream",
            "yogurt",

            # Vegetables
            "garlic",
            "onion",
            "potato",
            "potatoes",
            "tomato",
            "tomatoes",
            "carrot",
            "carrots",
            "pepper",
            "peppers",

            # Fruits
            "apple",
            "banana",
            "orange",
            "lemon",
            "lime",

            # Meat
            "chicken",
            "beef",
            "pork",
            "lamb",
            "mutton",

            # Seafood
            "fish",
            "salmon",
            "shrimp",
            "prawn",

            # Eggs
            "egg",
            "eggs",

            # Grains
            "rice",
            "flour",
            "wheat",
            "corn",
            "cereal",
            "grain",
            "grains",

            # Legumes
            "bean",
            "beans",
            "lentil",
            "lentils",
            "pea",
            "peas",

            # Seasonings
            "salt",
            "sugar",
            "pepper",
            "spice",
            "spices",
            "herb",
            "herbs",

            # Oils
            "oil",
            "olive",

            # Tortillas
            "tortilla",
            "tortillas",

            # Generic categories
            "fruit",
            "vegetable",
            "vegetables",
            "nut",
            "nuts",
            "seed",
            "seeds",
        }

    # =========================================================
    # BAD CONTEXT
    # =========================================================

    @staticmethod
    def _bad_context_words() -> set[str]:
        """
        Words strongly associated with unsuitable images.
        """

        return {
            # -------------------------------------------------
            # Scientific
            # -------------------------------------------------

            "casein",
            "protein",
            "proteins",
            "precipitation",
            "laboratory",
            "lab",
            "experiment",
            "experimental",
            "chemical",
            "chemistry",
            "molecule",
            "molecular",
            "microscope",
            "microscopy",
            "microscopic",
            "cell",
            "cells",
            "tissue",
            "histology",
            "specimen",
            "sample",
            "reagent",
            "solution",
            "reaction",
            "electrophoresis",
            "chromatography",
            "centrifuge",
            "centrifugation",
            "assay",
            "culture",
            "bacteria",
            "bacterial",
            "parasitism",
            "parasite",
            "pathogen",
            "pathogens",

            # -------------------------------------------------
            # Technical / educational
            # -------------------------------------------------

            "diagram",
            "chart",
            "graph",
            "schematic",
            "illustration",
            "illustrated",
            "drawing",
            "sketch",
            "infographic",
            "flowchart",

            # -------------------------------------------------
            # Location
            # -------------------------------------------------

            "building",
            "architecture",
            "street",
            "road",
            "city",
            "town",
            "village",
            "landscape",
            "monument",
            "museum",
            "map",
            "flag",

            # -------------------------------------------------
            # People
            # -------------------------------------------------

            "portrait",
            "person",
            "people",
            "man",
            "woman",
            "child",
            "children",
            "family",
            "chef",

            # -------------------------------------------------
            # Commercial
            # -------------------------------------------------

            "logo",
            "advertisement",
            "advert",
            "poster",
            "brand",
            "branding",
            "advertising",
        }

    # =========================================================
    # NON-FOOD OBJECTS
    # =========================================================

    @staticmethod
    def _non_food_object_words() -> set[str]:
        """
        Words indicating toys, figures, objects, or other
        non-food contexts.
        """

        return {
            "toy",
            "toys",
            "head",
            "hasbro",
            "headquarters",
            "figurine",
            "figure",
            "doll",
            "statue",
            "model",
            "models",
            "plastic",
            "sculpture",
            "character",
            "mascot",
        }

    # =========================================================
    # PREPARED DISH WORDS
    # =========================================================

    @staticmethod
    def _dish_words() -> set[str]:
        """
        Words indicating a prepared dish or preparation.

        IMPORTANT:
            Do not place valid ingredient names here.
        """

        return {
            "recipe",
            "recipes",
            "dish",
            "dishes",
            "meal",
            "meals",
            "cooking",
            "restaurant",
            "plate",

            "salad",
            "soup",
            "cake",
            "pizza",
            "pasta",
            "sandwich",
            "curry",
            "stew",
            "bread",
            "parfait",
            "smoothie",
            "pudding",
            "pie",
            "cookie",
            "cookies",
            "cupcake",
            "muffin",
            "muffins",
            "burger",
            "burgers",
            "noodles",
            "casserole",
            "skillet",
            "fritter",
            "fritters",
            "balls",
            "ball",
            "punch",

            "roast",
            "roasted",
            "baked",
            "fried",
            "grilled",
            "sauteed",
            "mashed",
            "stuffed",
            "stewed",
            "boiled",
            "braised",

            "taco",
            "tacos",
            "quesadilla",
            "quesadillas",
            "enchilada",
            "enchiladas",
            "nacho",
            "nachos",
            "chip",
            "chips",

            "biryani",
            "tots",
        }

    # =========================================================
    # PRODUCTION / PROCESS WORDS
    # =========================================================

    @staticmethod
    def _production_words() -> set[str]:
        return {
            "production",
            "processing",
            "process",
            "manufacturing",
            "factory",
            "industry",
            "industrial",
            "cultivation",
            "harvesting",
            "harvest",
            "plantation",
            "field",
            "fields",
            "farm",
            "farming",
            "equipment",
            "machine",
            "machinery",
            "container",
            "containers",
            "types",
            "products",
            "product",
            "facts",
            "history",
            "uses",
            "acceptance",
        }

    # =========================================================
    # NON-FOOD PARTS
    # =========================================================

    @staticmethod
    def _non_food_words() -> set[str]:
        return {
            "flower",
            "flowers",
            "leaf",
            "leaves",
            "leaflet",
            "plant",
            "plants",
            "seedling",
            "beetle",
            "insect",
            "pest",
            "disease",
            "diseased",
            "fungus",
            "fungal",
            "stem",
            "bark",
            "soil",
        }
        # =========================================================
    # INGREDIENT-SPECIFIC NEGATIVES
    # =========================================================

    @staticmethod
    def _ingredient_negative_terms(
        ingredient_name: str,
    ) -> set[str]:

        name = (
            ingredient_name
            .lower()
            .strip()
        )

        negatives: set[str] = set()

        # =====================================================
        # RICE
        # =====================================================

        if name == "rice":

            negatives.update(
                {
                    "jollof",
                    "fried",
                    "porridge",
                    "curry",
                    "pilaf",
                    "risotto",
                    "biryani",
                    "pudding",
                    "sushi",
                    "salad",
                    "terrace",
                    "terraces",
                    "field",
                    "fields",
                    "paddy",
                    "plant",
                    "plants",
                    "cooking",
                    "ingredients",
                    "defective",
                    "defect",
                    "damaged",
                    "broken",
                    "moldy",
                    "mold",
                    "sprouted",
                    "sprout",
                }
            )

        # =====================================================
        # MILK
        # =====================================================

        elif name == "milk":

            negatives.update(
                {
                    "coconut",
                    "flax",
                    "soy",
                    "almond",
                    "oat",
                    "rice",
                    "powder",
                    "protein",
                    "punch",
                    "production",
                    "products",
                    "container",
                    "containers",
                    "facts",
                    "history",
                }
            )
        elif name == "evaporated milk":

            negatives.update(
        {
            "condensed",
            "sweetened",
            "carnation",
            "newspaper",
            "ad",
            "advertisement",
            "buffet",
            "museum",
            "street",
            "supermarket",
        }
    )
        # =====================================================
        # CREAM
        # =====================================================

        elif name == "cream":

            negatives.update(
                {
                    "ice",
                    "cake",
                    "pastry",
                    "pizza",
                    "sundae",
                    "topping",
                    "filling",
                    "dessert",
                    "sauce",
                    "chocolate",
                    "strawberry",
                    "fruit",
                }
            )

        # =====================================================
        # POTATO
        # =====================================================

        elif name == "potato":

            negatives.update(
                {
                    "balls",
                    "ball",
                    "starch",
                    "flower",
                    "flowers",
                    "beetle",
                    "insect",
                    "salad",
                    "soup",
                    "pancake",
                    "pancakes",
                    "bread",
                    "chips",
                    "chip",
                    "fries",
                    "fried",
                    "mashed",
                    "roasted",
                    "baked",
                    "production",
                    "cultivation",
                    "porridge",
                    "barley",
                    "chicken",
                    "onion",
                    "garlic",
                    "rosemary",
                    "sprout",
                    "sprouts",
                    "biryani",
                    "mutton",
                    "beef",
                    "meat",
                    "curry",
                    "tots",
                    "sweet",
                    "bacteria",
                    "bacterial",
                    "parasitism",
                    "parasite",
                    "pathogen",
                    "pathogens",
                    "cross",
                    "section",
                }
            )

        # =====================================================
        # GARLIC
        # =====================================================

        elif name == "garlic":

            negatives.update(
                {
                    "moldy",
                    "mold",
                    "roasted",
                    "fried",
                    "confit",
                    "chicken",
                    "soup",
                    "recipe",
                    "history",
                    "uses",
                    "onion",
                    "potato",
                    "rosemary",
                }
            )

        # =====================================================
        # BLACK PEPPER
        # =====================================================

        elif name == "black pepper":

            negatives.update(
                {
                    "lemon",
                    "chicken",
                    "meat",
                    "grilled",
                    "steak",
                    "sauce",
                    "recipe",
                    "dish",
                    "bell",
                    "capsicum",
                }
            )

        # =====================================================
        # CORN TORTILLA
        # =====================================================

        elif name in {
            "corn tortilla",
            "corn tortillas",
        }:

            negatives.update(
                {
                    "flour",
                    "wheat",
                    "chicken",
                    "beef",
                    "pork",
                    "fish",
                    "salmon",
                    "shrimp",
                    "taco",
                    "tacos",
                    "enchilada",
                    "enchiladas",
                    "quesadilla",
                    "quesadillas",
                    "nacho",
                    "nachos",
                    "chip",
                    "chips",
                }
            )

        # =====================================================
        # FLOUR TORTILLA
        # =====================================================

        elif name in {
            "flour tortilla",
            "flour tortillas",
        }:

            negatives.update(
                {
                    "corn",
                    "chicken",
                    "beef",
                    "pork",
                    "fish",
                    "salmon",
                    "shrimp",
                    "taco",
                    "tacos",
                    "enchilada",
                    "enchiladas",
                    "quesadilla",
                    "quesadillas",
                    "nacho",
                    "nachos",
                    "chip",
                    "chips",
                }
            )

        # =====================================================
        # WHEAT TORTILLA
        # =====================================================

        elif name in {
            "wheat tortilla",
            "wheat tortillas",
        }:

            negatives.update(
                {
                    "corn",
                    "flour",
                    "chicken",
                    "beef",
                    "pork",
                    "fish",
                    "salmon",
                    "shrimp",
                    "taco",
                    "tacos",
                    "enchilada",
                    "enchiladas",
                    "quesadilla",
                    "quesadillas",
                    "nacho",
                    "nachos",
                    "chip",
                    "chips",
                }
            )

        # =====================================================
        # TOMATO
        # =====================================================

        elif name == "tomato":

            negatives.update(
                {
                    "sauce",
                    "soup",
                    "salad",
                    "pizza",
                    "pasta",
                    "ketchup",
                    "juice",
                    "plant",
                    "flower",
                    "flowers",
                }
            )

        # =====================================================
        # BREAD
        # =====================================================

        elif name == "bread":

            negatives.update(
                {
                    "breads",
                    "assorted",
                    "russia",
                    "moskovskaya",
                    "oblast",
                    "collection",
                    "varieties",
                    "russian",
                    "bakery",
                    "baguette",
                    "baguettes",
                    "bun",
                    "buns",
                    "sourdough",
                    "sandwich",
                }
            )

        # =====================================================
        # CHICKEN BREAST
        # =====================================================

        elif name == "chicken breast":

            negatives.update(
                {
                    "recipe",
                    "dish",
                    "salad",
                    "soup",
                    "curry",
                    "sandwich",
                    "pasta",
                    "rice",
                    "potato",
                    "rosemary",
                }
            )

        # =====================================================
        # BEAN MIX
        # =====================================================

        elif name == "bean mix":

            negatives.update(
                {
                    "trail",
                    "coffee",
                    "vanilla",
                    "rusk",
                    "bread",
                    "baked",
                    "roasted",
                    "snack",
                    "soup",
                }
            )

        # =====================================================
        # BUTTERMILK
        # =====================================================

        elif name == "buttermilk":

            negatives.update(
                {
                    "cooking",
                    "dish",
                    "home",
                    "aloo",
                    "aalu",
                    "kachalu",
                    "chicken",
                    "fried",
                    "squid",
                    "biscuit",
                    "recipe",
                }
            )

        # =====================================================
        # CHEDDAR CHEESE
        # =====================================================

        elif name == "cheddar cheese":

            negatives.update(
                {
                    "rusk",
                    "bread",
                    "roll",
                    "sandwich",
                    "salad",
                    "taco",
                    "pizza",
                    "recipe",
                    "making",
                    "production",
                }
            )

        # =====================================================
        # PIE CRUST
        # =====================================================

        elif name == "pie crust":

            negatives.update(
                {
                    "graham",
                    "lattice",
                    "herringbone",
                    "decorative",
                    "apple",
                    "bacon",
                    "vegan",
                }
            )

        # =====================================================
        # PIE SHELL
        # =====================================================

        elif name == "pie shell":

            negatives.update(
                {
                    "graham",
                    "apple",
                    "pumpkin",
                    "chocolate",
                    "bacon",
                    "vegan",
                    "decorative",
                    "lattice",
                }
            )

        # =====================================================
        # PITA
        # =====================================================

        elif name in {
            "pita",
            "pita bread",
            "pita flatbread",
        }:

            negatives.update(
                {
                    "hummus",
                    "falafel",
                    "platter",
                    "plate",
                    "chips",
                    "chip",
                    "pizza",
                    "sandwich",
                    "salad",
                    "wrap",
                    "wraps",
                    "restaurant",
                    "recipe",
                    "cooking",
                    "fried",
                    "stuffed",
                    "stuffing",
                }
            )

        return negatives

    # =========================================================
    # ALLOWED COMPOUND MODIFIERS
    # =========================================================

    @staticmethod
    def _allowed_compound_modifiers(
        ingredient_name: str,
    ) -> set[str]:

        name = (
            ingredient_name
            .lower()
            .strip()
        )

        allowed: dict[
            str,
            set[str],
        ] = {
            "rice": {
                "white",
                "brown",
                "wild",
                "long",
                "short",
                "jasmine",
                "basmati",
                "arborio",
                "grain",
                "grains",
                "single",
                "whole",
            },
            "cream": {
                "heavy",
                "whipping",
                "double",
                "fresh",
            },
            "milk": {
                "whole",
                "low",
                "fat",
                "skim",
                "skimmed",
                "fresh",
                "raw",
            },
            "potato": {
                "russet",
                "red",
                "yellow",
                "white",
                "new",
                "baby",
            },
            "black pepper": {
                "ground",
                "whole",
            },
            "chicken breast": {
                "fresh",
                "boneless",
                "skinless",
                "raw",
            },
            "corn tortilla": {
                "whole",
            },
            "flour tortilla": {
                "whole",
            },
            "wheat tortilla": {
                "whole",
            },
        }

        return allowed.get(
            name,
            set(),
        )

    # =========================================================
    # MULTI-WORD INGREDIENT IDENTITY
    # =========================================================

    @classmethod
    def _has_full_ingredient_identity(
        cls,
        ingredient_name: str,
        candidate_title: str,
    ) -> tuple[bool, str]:
        """
        Protect multi-word ingredients from loose substring
        matching.

        Example:

            cheddar cheese
                -> Cheddar Cheese
                ✅

            cheddar cheese
                -> Cheddar Cheese Rusk
                ❌

            bean mix
                -> Trail Mix Walter Bean...
                ❌
        """

        ingredient = cls._normalize(
            ingredient_name
        )

        title = cls._normalize(
            candidate_title
        )

        ingredient_words = cls._tokens(
            ingredient
        )

        title_words = cls._tokens(
            title
        )

        if len(ingredient_words) <= 1:

            return True, ""

        if not ingredient_words.issubset(
            title_words
        ):

            return (
                False,
                "missing ingredient words",
            )

        ingredient_phrase = (
            " ".join(
                ingredient.split()
            )
        )

        if ingredient_phrase in title:

            extra_words = (
                title_words
                - ingredient_words
                - cls._generic_words()
            )

            allowed = (
                cls._allowed_compound_modifiers(
                    ingredient_name
                )
            )

            remaining = (
                extra_words
                - allowed
            )

            if len(remaining) <= 2:

                return True, ""

        extra_words = (
            title_words
            - ingredient_words
            - cls._generic_words()
        )

        if len(extra_words) > 2:

            return (
                False,
                "multi-word ingredient mismatch",
            )

        return True, ""

    # =========================================================
    # COMPOUND MISMATCH
    # =========================================================

    @classmethod
    def _compound_mismatch(
        cls,
        ingredient_name: str,
        candidate_title: str,
    ) -> tuple[bool, str]:
        """
        Reject a different compound ingredient.

        Examples:

            potato -> sweet potato
            milk   -> coconut milk
            pepper -> bell pepper
        """

        ingredient = cls._normalize(
            ingredient_name
        )

        title = cls._normalize(
            candidate_title
        )

        ingredient_words = cls._tokens(
            ingredient
        )

        title_words = cls._tokens(
            title
        )

        if not ingredient_words:

            return False, ""

        if not ingredient_words.issubset(
            title_words
        ):

            return False, ""

        extra_words = (
            title_words
            - ingredient_words
            - cls._generic_words()
        )

        if not extra_words:

            return False, ""

        allowed = (
            cls._allowed_compound_modifiers(
                ingredient_name
            )
        )

        remaining = (
            extra_words
            - allowed
        )

        if not remaining:

            return False, ""

        compound_modifiers = {
            "sweet",
            "coconut",
            "almond",
            "soy",
            "oat",
            "flax",
            "bell",
            "coffee",
            "chocolate",
            "vanilla",
            "strawberry",
            "banana",
            "blueberry",
            "raspberry",
            "smoked",
            "pickled",
            "dried",
            "sun",
            "spiced",
            "stuffed",
            "crushed",
        }

        matches = (
            remaining
            & compound_modifiers
        )

        if matches:

            return (
                True,
                "compound ingredient mismatch: "
                + ", ".join(
                    sorted(matches)
                ),
            )

        return False, ""

    # =========================================================
    # HARD REJECTION
    # =========================================================

    @classmethod
    def _hard_reject(
        cls,
        ingredient_name: str,
        candidate_title: str,
    ) -> tuple[bool, str]:

        words = cls._tokens(
            candidate_title
        )

        if not words:

            return True, "empty title"

        # -----------------------------------------------------
        # Bad context
        # -----------------------------------------------------

        bad_context = (
            words
            & cls._bad_context_words()
        )

        if bad_context:

            return (
                True,
                "bad context: "
                + ", ".join(
                    sorted(
                        bad_context
                    )
                ),
            )

        # -----------------------------------------------------
        # Production
        # -----------------------------------------------------

        production = (
            words
            & cls._production_words()
        )

        if production:

            return (
                True,
                "production/process result: "
                + ", ".join(
                    sorted(
                        production
                    )
                ),
            )

        # -----------------------------------------------------
        # Non-food parts
        # -----------------------------------------------------

        non_food = (
            words
            & cls._non_food_words()
        )

        if non_food:

            return (
                True,
                "non-food part/context: "
                + ", ".join(
                    sorted(
                        non_food
                    )
                ),
            )

        # -----------------------------------------------------
        # Non-food objects
        # -----------------------------------------------------

        non_food_object = (
            words
            & cls._non_food_object_words()
        )

        if non_food_object:

            return (
                True,
                "non-food object/context: "
                + ", ".join(
                    sorted(
                        non_food_object
                    )
                ),
            )

        # -----------------------------------------------------
        # Prepared dish
        # -----------------------------------------------------

        dish = (
            words
            & cls._dish_words()
        )

        if dish:

            return (
                True,
                "dish/recipe result: "
                + ", ".join(
                    sorted(
                        dish
                    )
                ),
            )

        # -----------------------------------------------------
        # Ingredient-specific
        # -----------------------------------------------------

        negatives = (
            cls._ingredient_negative_terms(
                ingredient_name
            )
        )

        matched_negative = (
            words
            & negatives
        )

        if matched_negative:

            return (
                True,
                "ingredient-specific exclusion: "
                + ", ".join(
                    sorted(
                        matched_negative
                    )
                ),
            )

        # -----------------------------------------------------
        # Multi-word identity
        # -----------------------------------------------------

        identity_ok, identity_reason = (
            cls._has_full_ingredient_identity(
                ingredient_name,
                candidate_title,
            )
        )

        if not identity_ok:

            return (
                True,
                identity_reason,
            )

        # -----------------------------------------------------
        # Compound mismatch
        # -----------------------------------------------------

        compound_rejected, compound_reason = (
            cls._compound_mismatch(
                ingredient_name,
                candidate_title,
            )
        )

        if compound_rejected:

            return (
                True,
                compound_reason,
            )

        return False, ""

    # =========================================================
    # SCORE
    # =========================================================

    @classmethod
    def _score_candidate(
        cls,
        ingredient_name: str,
        candidate_title: str,
    ) -> tuple[int, str]:

        ingredient = cls._normalize(
            ingredient_name
        )

        title = cls._normalize(
            candidate_title
        )

        ingredient_words = cls._tokens(
            ingredient_name
        )

        title_words = cls._tokens(
            candidate_title
        )

        if not ingredient_words:

            return (
                0,
                "empty ingredient",
            )

        if not title_words:

            return (
                0,
                "empty candidate",
            )

        rejected, reason = (
            cls._hard_reject(
                ingredient_name,
                candidate_title,
            )
        )

        if rejected:

            return (
                0,
                reason,
            )

        score = 0

        # -----------------------------------------------------
        # Exact title
        # -----------------------------------------------------

        if title == ingredient:

            score += 150

        # -----------------------------------------------------
        # Exact phrase
        # -----------------------------------------------------

        elif ingredient in title:

            score += 80

        # -----------------------------------------------------
        # Matching words
        # -----------------------------------------------------

        matching = (
            ingredient_words
            & title_words
        )

        score += (
            len(matching) * 30
        )

        # -----------------------------------------------------
        # Match ratio
        # -----------------------------------------------------

        ratio = (
            len(matching)
            / max(
                len(ingredient_words),
                1,
            )
        )

        score += int(
            ratio * 40
        )

        # -----------------------------------------------------
        # Positive food context
        # -----------------------------------------------------

        positive = (
            title_words
            & cls._positive_food_words()
        )

        score += min(
            len(positive) * 5,
            20,
        )

        # -----------------------------------------------------
        # Simplicity
        # -----------------------------------------------------

        extra_words = (
            title_words
            - ingredient_words
            - cls._generic_words()
        )

        allowed_modifiers = (
            cls._allowed_compound_modifiers(
                ingredient_name
            )
        )

        meaningful_extra = (
            extra_words
            - allowed_modifiers
        )

        if len(meaningful_extra) == 0:

            score += 40

        elif len(meaningful_extra) == 1:

            score += 25

        elif len(meaningful_extra) == 2:

            score += 10

        elif len(meaningful_extra) == 3:

            score -= 10

        elif len(meaningful_extra) > 5:

            score -= 30

        # =====================================================
        # MIXED INGREDIENT PROTECTION
        # =====================================================

        competing_food_words = {
            "corn",
            "flour",
            "wheat",
            "chicken",
            "beef",
            "pork",
            "fish",
            "salmon",
            "shrimp",
            "onion",
            "garlic",
            "potato",
            "tomato",
            "pepper",
            "carrot",
            "cheese",
            "egg",
            "rice",
            "beans",
            "lentils",
        }

        competing = (
            title_words
            & competing_food_words
            - ingredient_words
        )

        competing = (
            competing
            - allowed_modifiers
        )

        if competing:

            score -= (
                len(competing) * 60
            )

        # =====================================================
        # MILK
        # =====================================================

        if ingredient == "milk":

            if "milk" in title_words:

                score += 20

            if (
                "glass" in title_words
                and "milk" in title_words
            ):

                score += 30

            if (
                "bottle" in title_words
                and "milk" in title_words
            ):

                score += 25

        # =====================================================
        # CREAM
        # =====================================================

        elif ingredient == "cream":

            if "cream" in title_words:

                score += 30

            if (
                "heavy" in title_words
                or "whipping" in title_words
                or "double" in title_words
            ):

                score += 15

            if (
                "fresh" in title_words
                and "cream" in title_words
            ):

                score += 10

        # =====================================================
        # POTATO
        # =====================================================

        elif ingredient == "potato":

            if "potato" in title_words:

                score += 30

            if "potatoes" in title_words:

                score += 30

            if (
                "tuber" in title_words
                or "tubers" in title_words
            ):

                score += 40

            if (
                "russet" in title_words
                and (
                    "potato" in title_words
                    or "potatoes" in title_words
                )
            ):

                score += 40

            if (
                "market" in title_words
                and (
                    "potato" in title_words
                    or "potatoes" in title_words
                )
            ):

                score += 15

        # =====================================================
        # GARLIC
        # =====================================================

        elif ingredient == "garlic":

            if "garlic" in title_words:

                score += 30

            if (
                "bulb" in title_words
                or "bulbs" in title_words
            ):

                score += 20

            if (
                "clove" in title_words
                or "cloves" in title_words
            ):

                score += 20

        # =====================================================
        # BLACK PEPPER
        # =====================================================

        elif ingredient == "black pepper":

            if (
                "black" in title_words
                and "pepper" in title_words
            ):

                score += 45

            if (
                "peppercorn" in title_words
                or "peppercorns" in title_words
            ):

                score += 25

            if (
                "basket" in title_words
                and "pepper" in title_words
            ):

                score += 10

        # =====================================================
        # RICE
        # =====================================================

        elif ingredient == "rice":

            if "rice" in title_words:

                score += 30

            if (
                "white" in title_words
                or "brown" in title_words
                or "wild" in title_words
            ):

                score += 20

            if (
                "grain" in title_words
                or "grains" in title_words
            ):

                score += 45

            if (
                "uncooked" in title_words
                or "raw" in title_words
            ):

                score += 25

            if (
                "single" in title_words
                and (
                    "grain" in title_words
                    or "rice" in title_words
                )
            ):

                score += 10

        # =====================================================
        # CORN TORTILLA
        # =====================================================

        elif ingredient == "corn tortilla":

            has_corn = (
                "corn" in title_words
                or "maize" in title_words
            )

            has_tortilla = (
                "tortilla" in title_words
                or "tortillas" in title_words
            )

            if (
                has_corn
                and has_tortilla
            ):

                score += 100

            if (
                "maize" in title_words
                and has_tortilla
            ):

                score += 35

            if (
                has_corn
                and has_tortilla
                and len(title_words) <= 4
            ):

                score += 30

        # =====================================================
        # FLOUR TORTILLA
        # =====================================================

        elif ingredient == "flour tortilla":

            has_flour = (
                "flour" in title_words
            )

            has_tortilla = (
                "tortilla" in title_words
                or "tortillas" in title_words
            )

            if (
                has_flour
                and has_tortilla
            ):

                score += 100

            if (
                has_flour
                and has_tortilla
                and len(title_words) <= 4
            ):

                score += 30

        # =====================================================
        # WHEAT TORTILLA
        # =====================================================

        elif ingredient == "wheat tortilla":

            has_wheat = (
                "wheat" in title_words
            )

            has_tortilla = (
                "tortilla" in title_words
                or "tortillas" in title_words
            )

            if (
                has_wheat
                and has_tortilla
            ):

                score += 100

            if (
                has_wheat
                and has_tortilla
                and len(title_words) <= 4
            ):

                score += 30

        # =====================================================
        # BEAN MIX
        # =====================================================

        elif ingredient == "bean mix":

            if (
                "bean" in title_words
                and "mix" in title_words
            ):

                score += 90

            if (
                len(title_words) <= 4
            ):

                score += 20

        # =====================================================
        # BUTTERMILK
        # =====================================================

        elif ingredient == "buttermilk":

            if "buttermilk" in title_words:

                score += 50

            if len(title_words) <= 3:

                score += 20

        # =====================================================
        # CHEDDAR CHEESE
        # =====================================================

        elif ingredient == "cheddar cheese":

            has_cheddar = (
                "cheddar" in title_words
            )

            has_cheese = (
                "cheese" in title_words
            )

            if (
                has_cheddar
                and has_cheese
            ):

                score += 110

            if len(title_words) <= 4:

                score += 20

        return (
            max(score, 0),
            "",
        )

    # =========================================================
    # HTTP REQUEST
    # =========================================================

    def _request(
        self,
        search_query: str,
    ) -> dict:

        if (
            time.monotonic()
            < self._rate_limited_until
        ):

            raise WikimediaRateLimitError(
                "Wikimedia is currently in cooldown."
            )

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

        except requests.Timeout as exc:

            print(
                "  Wikimedia request timed out."
            )

            raise WikimediaRateLimitError(
                "Wikimedia request timed out."
            ) from exc

        except requests.RequestException as exc:

            print(
                f"  Wikimedia request failed: "
                f"{exc}"
            )

            return {}

        # -----------------------------------------------------
        # Rate limit
        # -----------------------------------------------------

        if response.status_code == 429:

            retry_after = (
                response.headers.get(
                    "Retry-After"
                )
            )

            cooldown = (
                self.RATE_LIMIT_COOLDOWN_SECONDS
            )

            if retry_after:

                try:

                    cooldown = max(
                        int(retry_after),
                        self.RATE_LIMIT_COOLDOWN_SECONDS,
                    )

                except ValueError:

                    pass

            self._rate_limited_until = (
                time.monotonic()
                + cooldown
            )

            print(
                "  Wikimedia rate limit reached."
            )

            print(
                f"  Cooldown: {cooldown} seconds."
            )

            raise WikimediaRateLimitError(
                "Wikimedia returned HTTP 429."
            )

        # -----------------------------------------------------
        # Unauthorized / forbidden
        # -----------------------------------------------------

        if response.status_code in (
            401,
            403,
        ):

            print(
                "  Wikimedia rejected request "
                f"({response.status_code})."
            )

            return {}

        # -----------------------------------------------------
        # Other HTTP errors
        # -----------------------------------------------------

        try:

            response.raise_for_status()

        except requests.RequestException as exc:

            print(
                f"  Wikimedia HTTP error: "
                f"{exc}"
            )

            return {}

        # -----------------------------------------------------
        # JSON
        # -----------------------------------------------------

        try:

            return response.json()

        except ValueError:

            print(
                "  Wikimedia returned invalid JSON."
            )

            return {}

    # =========================================================
    # SEARCH QUERIES
    # =========================================================

    def _build_search_queries(
        self,
        visual_name: str,
    ) -> list[str]:

        special_queries: dict[
            str,
            list[str],
        ] = {
            "corn tortilla": [
                "100% corn tortilla",
                "maize tortilla",
            ],
            "flour tortilla": [
                "flour tortilla",
                "flour tortillas",
            ],
            "black pepper": [
                "black pepper",
                "black peppercorns",
            ],
            "rice": [
                "rice grain",
                "rice grains",
            ],
            "beans": [
                "beans ingredient",
                "dry beans",
            ],
            "stuffing": [
                "stuffing mix ingredient",
                "bread stuffing mix",
            ],
            "cream": [
                "cream ingredient",
                "heavy cream",
            ],
            "potato": [
                "potato ingredient",
                "potato tuber",
            ],
            "pie shell": [
                "pie shell ingredient",
                "unbaked pie shell",
            ],
            "pie crust": [
                "pie crust ingredient",
                "plain pie crust",
            ],
            "deep dish pie crust": [
                "deep dish pie crust",
                "deep dish unbaked pie crust",
            ],
            "deep dish pie shell": [
                "deep dish pie shell",
                "deep dish unbaked pie shell",
            ],
            "wheat tortilla": [
                "wheat tortilla ingredient",
                "whole wheat tortilla",
            ],
            "pita": [
                "pita flatbread",
                "pita bread",
            ],
            "bread": [
                "bread ingredient",
                "plain bread",
            ],
            "graham cracker": [
                "graham cracker",
                "graham crackers",
            ],
            "bean mix": [
                "bean mix ingredient",
                "mixed beans",
            ],
            "buttermilk": [
                "buttermilk ingredient",
                "buttermilk",
            ],
            "cheddar cheese": [
                "cheddar cheese ingredient",
                "cheddar cheese",
            ],
            "evaporated milk": [
    "evaporated milk ingredient",
    "plain evaporated milk",
],
        }


        queries = special_queries.get(
            visual_name
        )

        if queries is None:

            queries = [
                f"{visual_name} ingredient",
                visual_name,
            ]

        return list(
            dict.fromkeys(
                queries
            )
        )[:2]

    # =========================================================
    # SEARCH
    # =========================================================

    def search(
        self,
        ingredient_name: str,
    ) -> ImageResult | None:

        queries = (
            get_ingredient_image_queries(
                ingredient_name
            )
        )

        if not queries:

            print(
                "  No image queries generated."
            )

            return None

        visual_name = (
            queries[0]
            .replace(
                " ingredient",
                "",
            )
            .strip()
        )

        visual_name = self._normalize(
            visual_name
        )

        if not visual_name:

            return None

        print(
            "  Visual ingredient: "
            f"{visual_name}"
        )

        # -----------------------------------------------------
        # In-process success cache
        # -----------------------------------------------------

        cached = (
            self._image_cache.get(
                visual_name
            )
        )

        if cached is not None:

            print(
                "  Cache hit."
            )

            return cached

        # -----------------------------------------------------
        # Search queries
        # -----------------------------------------------------

        search_queries = (
            self._build_search_queries(
                visual_name
            )
        )

        # =====================================================
        # QUERY LOOP
        # =====================================================

        for query_index, search_query in enumerate(
            search_queries,
            start=1,
        ):

            print(
                f"  Search {query_index}/"
                f"{len(search_queries)}: "
                f"{search_query}"
            )

            try:

                data = self._request(
                    search_query
                )

            except WikimediaRateLimitError:

                raise

            pages = (
                data
                .get("query", {})
                .get("pages", {})
            )

            best: tuple[
                int,
                ImageResult,
                str,
            ] | None = None

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

                # ---------------------------------------------
                # MIME
                # ---------------------------------------------

                mime_type = (
                    info.get(
                        "mime",
                        "",
                    )
                    .strip()
                    .lower()
                )

                if mime_type not in (
                    ALLOWED_MIME_TYPES
                ):

                    continue

                # ---------------------------------------------
                # ---------------------------------------------
                # IMAGE URL
                # ---------------------------------------------

                image_url = info.get("thumburl")

                if not image_url:
                    image_url = info.get("url")

                if not image_url:
                    continue

                # ---------------------------------------------
                # TITLE
                # ---------------------------------------------

                candidate_title = (
                    page.get(
                        "title",
                        "",
                    )
                    .replace(
                        "File:",
                        "",
                    )
                    .strip()
                )

                # ---------------------------------------------
                # SCORE
                # ---------------------------------------------

                score, reason = (
                    self._score_candidate(
                        visual_name,
                        candidate_title,
                    )
                )

                if score <= 0:

                    if reason:

                        print(
                            "  Rejected: "
                            f"{candidate_title} "
                            f"({reason})"
                        )

                    continue

                print(
                    "  Candidate: "
                    f"{candidate_title} "
                    f"[score={score}]"
                )

                result = ImageResult(
                    url=image_url,
                    mime_type=mime_type,
                )

                if (
                    best is None
                    or score > best[0]
                ):

                    best = (
                        score,
                        result,
                        candidate_title,
                    )

            # =================================================
            # NO CANDIDATE
            # =================================================

            if best is None:

                print(
                    "  No suitable image from "
                    f"query {query_index}."
                )

            else:

                best_score = best[0]
                best_result = best[1]
                best_title = best[2]

                print(
                    f"  Best score: "
                    f"{best_score}"
                )

                print(
                    "  Selected: "
                    f"{best_title}"
                )

                if (
                    best_score
                    >= MINIMUM_SCORE
                ):

                    self._image_cache[
                        visual_name
                    ] = best_result

                    return best_result

                print(
                    "  Best candidate is below "
                    "minimum score."
                )

            # =================================================
            # FALLBACK DELAY
            # =================================================

            if (
                query_index
                < len(search_queries)
            ):

                print(
                    "  Trying controlled "
                    "fallback query..."
                )

                if REQUEST_DELAY_SECONDS > 0:

                    time.sleep(
                        REQUEST_DELAY_SECONDS
                    )

        # =====================================================
        # FINAL FAILURE
        # =====================================================

        print(
            "  No suitable image found."
        )

        return None