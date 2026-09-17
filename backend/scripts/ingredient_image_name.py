from __future__ import annotations

import re


# =============================================================
# WORDS THAT ARE NOT USEFUL FOR VISUAL IDENTIFICATION
# =============================================================

REMOVE_WORDS = {
    # ---------------------------------------------------------
    # Nutrition / fat
    # ---------------------------------------------------------

    "fat",
    "low",
    "lowfat",
    "low-fat",
    "nonfat",
    "non-fat",
    "reduced",
    "reduced-fat",
    "skim",
    "skimmed",
    "full-fat",
    "fullfat",
    "lean",
    "leaned",
    "free",
    "low-carb",
    "lowcarb",
    "carb",

    # ---------------------------------------------------------
    # Freshness / storage
    # ---------------------------------------------------------

    "fresh",
    "freshly",
    "frozen",
    "thawed",
    "dry",
    "canned",
    "tinned",
    "packed",
    "packaged",
    "prepared",

    # ---------------------------------------------------------
    # Preparation
    # ---------------------------------------------------------

    "diced",
    "chopped",
    "sliced",
    "minced",
    "crushed",
    "grated",
    "shredded",
    "cubed",
    "julienned",
    "quartered",
    "halved",
    "peeled",
    "seeded",
    "de-seeded",
    "boneless",
    "skinless",
    "baked",
    "unbaked",

    # ---------------------------------------------------------
    # Time
    # ---------------------------------------------------------

    "minute",
    "minutes",

    # ---------------------------------------------------------
    # Alcohol strength
    # ---------------------------------------------------------

    "proof",

    # ---------------------------------------------------------
    # Quality / marketing
    # ---------------------------------------------------------

    "organic",
    "natural",
    "premium",
    "classic",
    "original",
    "regular",
    "light",
    "lite",
    "extra",
    "special",
    "select",
    "choice",
    "fancy",

    # ---------------------------------------------------------
    # Packaging
    # ---------------------------------------------------------

    "jarred",
    "bottled",
    "boxed",
    "packet",
    "packets",
    "package",
    "packages",

    # ---------------------------------------------------------
    # Measurements
    # ---------------------------------------------------------

    "inch",
    "inches",

    # ---------------------------------------------------------
    # Generic
    # ---------------------------------------------------------

    "recipe",
    "recipes",
    "ingredient",
    "ingredients",
}


# =============================================================
# CONTEXTUAL / SIZE DESCRIPTORS
# =============================================================

CONTEXTUAL_REMOVE_WORDS = {
    "large",
    "small",
    "medium",
    "tiny",
    "mini",
    "extra-large",
    "curd",
    "curds",
}


# =============================================================
# REGEX
# =============================================================

PERCENT_PATTERN = re.compile(
    r"\b\d+(?:\.\d+)?\s*%"
)

NUMBER_PATTERN = re.compile(
    r"\b\d+(?:\.\d+)?\b"
)


# =============================================================
# EXACT SPECIAL REPLACEMENTS
# =============================================================

SPECIAL_REPLACEMENTS = {
    # ---------------------------------------------------------
    # Rice
    # ---------------------------------------------------------

    "success rice": "rice",
    "minute success rice": "rice",
    "minute rice": "rice",

    # ---------------------------------------------------------
    # Bean soup mix
    # ---------------------------------------------------------

    "10 bean soup mix": "beans",
    "13 bean soup mix": "beans",
    "15 bean soup mix": "beans",
    "bean soup mix": "beans",

    # ---------------------------------------------------------
    # Bean mix
    # ---------------------------------------------------------

    "3 bean mix": "bean mix",
    "7 bean mix": "bean mix",
    "15 bean mix": "bean mix",
    "16 bean mix": "bean mix",

    # ---------------------------------------------------------
    # Stuffing
    # ---------------------------------------------------------

    "10 minute herb stuffing mix": "stuffing",
    "herb stuffing mix": "stuffing",
    "herb stuffing": "stuffing",

    # ---------------------------------------------------------
    # Oils
    # ---------------------------------------------------------

    "extra virgin olive oil": "olive oil",
    "virgin olive oil": "olive oil",

    # ---------------------------------------------------------
    # Chicken
    # ---------------------------------------------------------

    "boneless skinless chicken breast": "chicken breast",
    "boneless skinless chicken breasts": "chicken breast",
    "chicken breast boneless skinless": "chicken breast",

    # ---------------------------------------------------------
    # Garlic
    # ---------------------------------------------------------

    "fresh garlic cloves": "garlic",
    "garlic cloves": "garlic",

    # ---------------------------------------------------------
    # Ginger
    # ---------------------------------------------------------

    "fresh ginger root": "ginger",
    "ginger root": "ginger",

    # ---------------------------------------------------------
    # Pepper
    # ---------------------------------------------------------

    "ground black pepper": "black pepper",
    "ground pepper": "black pepper",
    "crushed red pepper": "red pepper",

    # ---------------------------------------------------------
    # Flour
    # ---------------------------------------------------------

    "all purpose flour": "all purpose flour",
    "all-purpose flour": "all purpose flour",

    # ---------------------------------------------------------
    # Graham crackers
    # ---------------------------------------------------------

    "graham cracker crisps": "graham cracker",
    "graham cracker crumbs": "graham cracker",

    # ---------------------------------------------------------
    # Tapioca pudding
    # ---------------------------------------------------------

    "snack pack tapioca pudding": "tapioca pudding",

    # ---------------------------------------------------------
    # Sun-dried tomato tortilla
    # ---------------------------------------------------------

    "sun dried tomato tortillas": "sun dried tomato tortilla",
    "sun dried tomato tortilla": "sun dried tomato tortilla",

    # ---------------------------------------------------------
    # Bran
    # ---------------------------------------------------------

    "100 bran": "bran",

    # ---------------------------------------------------------
    # Cottage cheese
    # ---------------------------------------------------------

    "large curd cottage cheese": "cottage cheese",
    "large curds cottage cheese": "cottage cheese",
    "small curd cottage cheese": "cottage cheese",
    "small curds cottage cheese": "cottage cheese",
    "cottage cheese large curd": "cottage cheese",
    "cottage cheese small curd": "cottage cheese",

    # ---------------------------------------------------------
    # Pie / crust
    # ---------------------------------------------------------

    "12 inch pizza crust": "pizza crust",
    "15 inch pizza crusts": "pizza crust",

    "3 inch pie pastry tart shells": "tart shell",
    "3 inch tart shells": "tart shell",

    "8 inch baked pie shell": "pie shell",
    "8 inch double crust pie shell": "double crust pie shell",

    "8 inch graham cracker crust": "graham cracker crust",
    "8 inch ready made graham cracker crust": (
        "graham cracker crust"
    ),
    "8 inch pre baked crumb crust": "crumb crust",

    # ---------------------------------------------------------
    # Dairy
    # ---------------------------------------------------------

    "18 table cream": "table cream",
    "35 fresh cream": "cream",
    "35 cream": "cream",

    "4 fat cottage cheese": "cottage cheese",
    "5 fat ricotta cheese": "ricotta cheese",

    "2 evaporated milk": "evaporated milk",

    # ---------------------------------------------------------
    # Cheese
    # ---------------------------------------------------------

    "2 mexican cheese blend": "mexican cheese blend",

    "3 cheese gourmet cheddar blend cheese": (
        "cheddar cheese blend"
    ),

    "6 cheese zesty mexican cheese blend": (
        "mexican cheese blend"
    ),

    # ---------------------------------------------------------
    # Pita / tortilla
    # ---------------------------------------------------------

    "5 pitas": "pita",
    "6 pitas": "pita",

    "6 whole wheat pitas": "whole wheat pita",

    "6 whole wheat tortilla": "wheat tortilla",

    "6 inch tortillas": "tortilla",

    "6 corn tortillas": "corn tortilla",
    "6 flour tortillas": "flour tortilla",

    "7 flour tortillas": "flour tortilla",

    "8 flour tortillas": "flour tortilla",
    "8 fat free flour tortillas": "flour tortilla",

    "8 low carb whole wheat tortilla": "wheat tortilla",

    "8 97 fat free flour tortillas": "flour tortilla",

    "6 fat free whole wheat pita bread": (
        "whole wheat pita"
    ),

    # ---------------------------------------------------------
    # Flour / bread / meat
    # ---------------------------------------------------------

    "4 grain bread flour": "bread flour",
    "8 grain bread": "bread",
    "9 inch cake layers": "cake layer",
    "cake layers": "cake layer",
    "9 in baked pastry shell": "baked pastry shell",
    "9 inch baked pastry shell": "baked pastry shell",
    "9 inch baked pie crusts": "pie crust",
    "9 inch deep dish pie crusts": "deep dish pie crust",
    "70 lean ground beef": "ground beef",

    # ---------------------------------------------------------
    # Soda
    # ---------------------------------------------------------

    "7 up": "7 up",
    "7 up soda": "7 up",
}



# =============================================================
# IMAGE SEARCH ALIASES
# =============================================================
#
# These aliases normalize product-specific names into a useful
# ingredient name for image search. They do not change the
# database ingredient itself.
# =============================================================

IMAGE_SEARCH_ALIASES = {
    # Achiote / annatto
    "achiote paste cubes": "achiote paste",
    "achiote cube": "achiote paste",
    "achiote cubes": "achiote paste",

    # Whole-product names
    "whole potatoes": "potato",
    "whole potato": "potato",
}


# =============================================================
# SINGULARIZATION
# =============================================================

SINGULAR_REPLACEMENTS = {
    # Vegetables
    "tomatoes": "tomato",
    "potatoes": "potato",
    "onions": "onion",
    "carrots": "carrot",
    "peppers": "pepper",

    # Tortillas / pita
    "tortillas": "tortilla",
    "pitas": "pita",

    # Baking
    "shells": "shell",

    # Fruits
    "lemons": "lemon",
    "limes": "lime",
    "apples": "apple",
    "bananas": "banana",
    "oranges": "orange",

    # Meat
    "chicken breasts": "chicken breast",
    "turkey breasts": "turkey breast",
    "beef steaks": "beef steak",
    "pork chops": "pork chop",

    # Eggs
    "eggs": "egg",

    # Dairy
    "cheeses": "cheese",
}


# =============================================================
# POST-CLEAN SPECIAL MAPPINGS
# =============================================================

POST_CLEAN_SPECIAL = {
    # ---------------------------------------------------------
    # Graham
    # ---------------------------------------------------------

    "cinnamon graham cracker crisps": "graham cracker",
    "honey maid cinnamon graham cracker crisps": (
        "graham cracker"
    ),

    # ---------------------------------------------------------
    # Tapioca
    # ---------------------------------------------------------

    "tapioca pudding": "tapioca pudding",

    # ---------------------------------------------------------
    # Rice
    # ---------------------------------------------------------

    "minute success rice": "rice",
    "success rice": "rice",
    "minute rice": "rice",

    # ---------------------------------------------------------
    # Cottage cheese
    # ---------------------------------------------------------

    "large curd cottage cheese": "cottage cheese",
    "small curd cottage cheese": "cottage cheese",

    # ---------------------------------------------------------
    # Crust
    # ---------------------------------------------------------

    "graham cracker crust": "graham cracker crust",
    "ready made graham cracker crust": (
        "graham cracker crust"
    ),
    "pre baked crumb crust": "crumb crust",

    # ---------------------------------------------------------
    # Cheese blends
    # ---------------------------------------------------------

    "cheese gourmet cheddar blend cheese": (
        "cheddar cheese blend"
    ),
    "zesty mexican cheese blend": (
        "mexican cheese blend"
    ),
}


# =============================================================
# BRAND / PACKAGE WORDS
# =============================================================

BRAND_WORDS = {
    "honey",
    "maid",
    "snack",
    "pack",
    "success",
}


# =============================================================
# NORMALIZE
# =============================================================

def normalize(
    text: str,
) -> str:
    """
    Normalize ingredient text.
    """

    text = (
        text
        or ""
    ).strip().lower()

    # ---------------------------------------------------------
    # Common encoding artifacts
    # ---------------------------------------------------------

    text = text.replace(
        "Γò¼├┤Γö£├ºΓö£├╗",
        "'",
    )

    text = text.replace(
        "╬ô├ç├û",
        "'",
    )

    # ---------------------------------------------------------
    # Ampersand
    # ---------------------------------------------------------

    text = text.replace(
        "&",
        " and ",
    )

    # ---------------------------------------------------------
    # Punctuation
    # ---------------------------------------------------------

    text = re.sub(
        r"[(),;/]+",
        " ",
        text,
    )

    # ---------------------------------------------------------
    # Hyphen
    # ---------------------------------------------------------

    text = text.replace(
        "-",
        " ",
    )

    # ---------------------------------------------------------
    # Whitespace
    # ---------------------------------------------------------

    text = re.sub(
        r"\s+",
        " ",
        text,
    )

    return text.strip()


# =============================================================
# REMOVE MEASUREMENTS
# =============================================================

def remove_measurements(
    text: str,
) -> str:
    """
    Remove size and measurement expressions.

    Examples:

        10-Inch
        10 inch
        10 inches
        10"
        10'
        12-in
        12 in
        1.5 ft
    """

    # ---------------------------------------------------------
    # Word measurements
    # ---------------------------------------------------------

    text = re.sub(
        r"\b\d+(?:\.\d+)?\s*-\s*inches?\b",
        " ",
        text,
        flags=re.IGNORECASE,
    )

    text = re.sub(
        r"\b\d+(?:\.\d+)?\s+inches?\b",
        " ",
        text,
        flags=re.IGNORECASE,
    )

    text = re.sub(
        r"\b\d+(?:\.\d+)?\s+inch\b",
        " ",
        text,
        flags=re.IGNORECASE,
    )

    text = re.sub(
        r"\b\d+(?:\.\d+)?\s+in\b",
        " ",
        text,
        flags=re.IGNORECASE,
    )

    # ---------------------------------------------------------
    # Quoted measurements
    # ---------------------------------------------------------

    text = re.sub(
        r"\b\d+(?:\.\d+)?\s*[\"']",
        " ",
        text,
    )

    # ---------------------------------------------------------
    # Hyphenated numeric measurements
    # ---------------------------------------------------------

    text = re.sub(
        r"\b\d+(?:\.\d+)?\s*-\s*inch(?:es)?\b",
        " ",
        text,
        flags=re.IGNORECASE,
    )

    # ---------------------------------------------------------
    # Feet
    # ---------------------------------------------------------

    text = re.sub(
        r"\b\d+(?:\.\d+)?\s*(?:feet|foot|ft)\b",
        " ",
        text,
        flags=re.IGNORECASE,
    )

    # ---------------------------------------------------------
    # Whitespace
    # ---------------------------------------------------------

    text = re.sub(
        r"\s+",
        " ",
        text,
    ).strip()

    return text


# =============================================================
# REMOVE MODIFIERS
# =============================================================

def remove_modifiers(
    text: str,
) -> str:
    """
    Remove generic modifiers and numeric values.
    """

    words = text.split()

    cleaned: list[str] = []

    for word in words:

        if word in REMOVE_WORDS:
            continue

        if word in CONTEXTUAL_REMOVE_WORDS:
            continue

        if NUMBER_PATTERN.fullmatch(
            word
        ):
            continue

        cleaned.append(
            word
        )

    return " ".join(
        cleaned
    )


# =============================================================
# FINALIZE
# =============================================================

def _finalize(
    value: str,
) -> str:
    """
    Apply final normalization and singularization.
    """

    value = normalize(
        value
    )

    if not value:
        return ""

    # ---------------------------------------------------------
    # Exact singular replacement
    # ---------------------------------------------------------

    if value in SINGULAR_REPLACEMENTS:

        value = SINGULAR_REPLACEMENTS[
            value
        ]

    else:

        words = value.split()

        if words:

            last_word = words[-1]

            if (
                last_word
                in SINGULAR_REPLACEMENTS
            ):

                words[-1] = (
                    SINGULAR_REPLACEMENTS[
                        last_word
                    ]
                )

            value = " ".join(
                words
            )

    value = re.sub(
        r"\s+",
        " ",
        value,
    ).strip()

    # Remove accidental punctuation left at the edges.
    value = value.strip(" ._-")

    return value


# =============================================================
# FAMILY-SPECIFIC CANONICALIZATION
# =============================================================

def _apply_canonical_rules(
    value: str,
) -> str:
    """
    Apply conservative ingredient-family-specific
    canonicalization rules.
    """

    value = normalize(
        value
    )

    # ---------------------------------------------------------
    # Normalize plural words before family checks
    # ---------------------------------------------------------

    words = value.split()

    words = [
        SINGULAR_REPLACEMENTS.get(
            word,
            word,
        )
        for word in words
    ]

    value = " ".join(
        words
    )

    # ---------------------------------------------------------
    # Potato
    # ---------------------------------------------------------

    if value in {
        "potato",
        "whole potato",
    }:
        return "potato"

    # ---------------------------------------------------------
    # Cottage cheese
    # ---------------------------------------------------------

    if "cottage cheese" in value:
        return "cottage cheese"

    # ---------------------------------------------------------
    # Evaporated milk
    # ---------------------------------------------------------

    if "evaporated milk" in value:
        return "evaporated milk"

    # ---------------------------------------------------------
    # Buttermilk
    # ---------------------------------------------------------

    if value == "buttermilk":
        return "buttermilk"

    # ---------------------------------------------------------
    # Cheddar cheese
    # ---------------------------------------------------------

    if value == "cheddar cheese":
        return "cheddar cheese"

    # ---------------------------------------------------------
    # Cheddar cheese blend
    # ---------------------------------------------------------

    if (
        "cheddar" in value
        and "blend" in value
    ):
        return "cheddar cheese blend"

    # ---------------------------------------------------------
    # Mexican cheese blend
    # ---------------------------------------------------------

    if (
        "mexican" in value
        and "cheese" in value
        and "blend" in value
    ):
        return "mexican cheese blend"

    # ---------------------------------------------------------
    # Graham cracker crust
    # ---------------------------------------------------------

    if "graham cracker crust" in value:
        return "graham cracker crust"

    # ---------------------------------------------------------
    # Whole wheat pita
    # ---------------------------------------------------------

    if (
        "whole" in value
        and "wheat" in value
        and "pita" in value
    ):
        return "whole wheat pita"

    # ---------------------------------------------------------
    # Wheat pita
    # ---------------------------------------------------------

    if (
        "wheat" in value
        and "pita" in value
    ):
        return "wheat pita"

    # ---------------------------------------------------------
    # Whole wheat tortilla
    #
    # Keep canonical form as wheat tortilla.
    # ---------------------------------------------------------

    if (
        "wheat" in value
        and "tortilla" in value
    ):
        return "wheat tortilla"

    # ---------------------------------------------------------
    # Flour tortilla
    # ---------------------------------------------------------

    if (
        "flour" in value
        and "tortilla" in value
    ):
        return "flour tortilla"

    # ---------------------------------------------------------
    # Ground beef
    # ---------------------------------------------------------

    if (
        "ground" in value
        and "beef" in value
    ):
        return "ground beef"

    return value


# =============================================================
# VISUAL INGREDIENT NAME
# =============================================================

def get_visual_ingredient_name(
    ingredient_name: str,
) -> str:
    """
    Convert a database ingredient/product name into a canonical
    visual ingredient name.
    """

    original = normalize(
        ingredient_name
    )

    if not original:
        return ""

    # =========================================================
    # EXACT SPECIAL MAPPING
    # =========================================================

    special = (
        SPECIAL_REPLACEMENTS.get(
            original
        )
    )

    if special is not None:

        return _finalize(
            special
        )

    # =========================================================
    # REMOVE PERCENTAGES
    # =========================================================

    value = PERCENT_PATTERN.sub(
        " ",
        original,
    )

    # =========================================================
    # REMOVE MEASUREMENTS
    # =========================================================

    value = remove_measurements(
        value
    )

    # =========================================================
    # REMOVE MODIFIERS
    # =========================================================

    value = remove_modifiers(
        value
    )

    # =========================================================
    # CALORIE DESCRIPTORS
    # =========================================================

    value = re.sub(
        r"\b\d+\s*(?:calorie|calories)\b",
        " ",
        value,
        flags=re.IGNORECASE,
    )

    value = re.sub(
        r"\bcalorie(?:s)?\b",
        " ",
        value,
        flags=re.IGNORECASE,
    )

    # =========================================================
    # BRAND / PACKAGE TERMS
    # =========================================================

    words = value.split()

    words = [
        word
        for word in words
        if word not in BRAND_WORDS
    ]

    value = " ".join(
        words
    )

    # =========================================================
    # CLEAN
    # =========================================================

    value = re.sub(
        r"\s+",
        " ",
        value,
    ).strip()

    # =========================================================
    # POST-CLEAN SPECIAL MAPPING
    # =========================================================

    post_clean = (
        POST_CLEAN_SPECIAL.get(
            value
        )
    )

    if post_clean is not None:

        value = post_clean

    # =========================================================
    # FAMILY RULES
    # =========================================================

    value = _apply_canonical_rules(
        value
    )

    # =========================================================
    # FINAL CANONICAL EDGE CASES
    # =========================================================

    final_special = {
        "pie crusts": "pie crust",
        "deep dish pie crusts": "deep dish pie crust",
        "cake layers": "cake layer",
        "baked pastry shell": "baked pastry shell",
    }

    value = final_special.get(
        value,
        value,
    )

    # ---------------------------------------------------------
    # Image-search aliases
    # ---------------------------------------------------------
    image_alias = IMAGE_SEARCH_ALIASES.get(
        value
    )

    if image_alias is not None:
        value = image_alias

    # =========================================================
    # FINALIZE
    # =========================================================

    return _finalize(
        value
    )


# =============================================================
# IMAGE SEARCH QUERIES
# =============================================================

def get_ingredient_image_queries(
    ingredient_name: str,
) -> list[str]:
    """
    Generate at most two basic image search queries.
    """

    visual_name = (
        get_visual_ingredient_name(
            ingredient_name
        )
    )

    if not visual_name:
        return []

    queries: list[str] = []

    def add(
        value: str,
    ) -> None:

        value = value.strip()

        if not value:
            return

        if value not in queries:

            queries.append(
                value
            )

    add(
        f"{visual_name} ingredient"
    )

    add(
        visual_name
    )

    # Also expose an explicit lookup alias when one exists.
    lookup_alias = IMAGE_SEARCH_ALIASES.get(
        visual_name
    )

    if lookup_alias is not None:
        add(
            f"{lookup_alias} ingredient"
        )
        add(
            lookup_alias
        )

    return queries


# =============================================================
# MANUAL TEST
# =============================================================

if __name__ == "__main__":

    tests = [
        # -----------------------------------------------------
        # Existing tested cases
        # -----------------------------------------------------

        "10-Inch Corn Tortillas",
        "10-Inch Flour Tortilla",
        "10-Inch Flour Tortillas",
        "10-Inch Deep Dish Pie Crust",
        "10-Inch Baked Pie Shells",
        "10-Inch Pie Shell",
        '10" Pie Crust',
        "10-Inch Sun-Dried Tomato Tortillas",
        "10-Inch Unbaked Deep-Dish Pie Shell",
        "10-Inch Whole Wheat Tortillas",

        "10-Minute Herb Stuffing Mix",
        "10-Minute Success Rice",
        "10 Bean Soup Mix",

        # -----------------------------------------------------
        # Current database edge cases
        # -----------------------------------------------------

        "13 Bean Soup Mix",
        "15 Bean Mix",
        "15 Bean Soup Mix",
        "15 Inch Pizza Crusts",
        "16 Bean Mix",
        "18% Table Cream",
        "2% Evaporated Milk",
        "2% Mexican Cheese Blend",
        "3-Cheese Gourmet Cheddar Blend Cheese",
        "3-Inch Pie Pastry Tart Shells",
        "3-Inch Tart Shells",
        "3 Bean Mix",
        "35 % Fresh Cream",
        "35% Cream",
        "4 Grain Bread Flour",
        "4% Fat Cottage Cheese",
        "5-Inch Pitas",
        "5% Fat Ricotta Cheese",
        "6-Inch Corn Tortillas",
        "6-Inch Flour Tortillas",
        "6-Inch Pitas",
        "6-Inch Tortillas",
        "6-Inch Whole Wheat Pitas",
        "6-Inch Whole Wheat Tortilla",
        "6 Cheese Zesty Mexican Cheese Blend",
        "6 Inch Fat-Free Whole Wheat Pita Bread",
        "7-Inch Flour Tortillas",
        "7-Up",
        "7-Up Soda",
        "7 Bean Mix",
        "70% Lean Ground Beef",
        "8-Grain Bread",
        "8-Inch 97% Fat Free Flour Tortillas",
        "8-Inch Baked Pie Shell",
        "8-Inch Double-Crust Pie Shell",
        "8-Inch Fat-Free Flour Tortillas",
        "8-Inch Flour Tortillas",
        "8-Inch Graham Cracker Crust",
        "8-Inch Low-Carb Whole Wheat Tortilla",
        "8-Inch Pre-Baked Crumb Crust",
        "8-Inch Ready-Made Graham Cracker Crust",

        # -----------------------------------------------------
        # Image-search alias edge cases
        # -----------------------------------------------------

        "Achiote Paste Cubes",
        "Achiote Cube",
        "Achiote Powder",
        "Whole Potatoes",

        # -----------------------------------------------------
        # Previously tested
        # -----------------------------------------------------

        "10% Cream",
        "15% Cream",
        "18% Table Cream",
        "1% Low-Fat Milk",
        "2% Buttermilk",
        "2% Fat Cottage Cheese",
        "2% Large-Curd Cottage Cheese",
        "Fresh Boneless Skinless Chicken Breast",
        "Diced Canned Tomatoes",
        "Extra Virgin Olive Oil",
        "Fresh Garlic Cloves",
        "Ground Black Pepper",
        "Whole Potatoes",
    ]

    print(
        "=" * 80
    )

    print(
        "VISUAL INGREDIENT NAME TEST"
    )

    print(
        "=" * 80
    )

    for ingredient in tests:

        visual = (
            get_visual_ingredient_name(
                ingredient
            )
        )

        print(
            f"{ingredient} -> {visual}"
        )