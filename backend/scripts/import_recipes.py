import ast
import os
import re
import sys
from dataclasses import dataclass
from fractions import Fraction

import pandas as pd

sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from app.dependencies.database import SessionLocal
from app.models.category import Category
from app.models.cuisine import Cuisine
from app.models.difficulty import Difficulty
from app.models.ingredient import Ingredient
from app.models.ingredient_category import IngredientCategory
from app.models.recipe import Recipe
from app.models.recipe_ingredient import RecipeIngredient
from app.models.unit import Unit
from app.models.user import User

from import_config import (
    BATCH_SIZE,
    DATASET_PATH,
    IMPORT_LIMIT,
    PROGRESS_INTERVAL,
    DEFAULT_SERVINGS,
    DEFAULT_IMAGE_URL,
)
from import_stats import ImportStats
from logger import ImportLogger


# ============================================================
# DATABASE
# ============================================================

db = SessionLocal()

stats = ImportStats()
logger = ImportLogger()
logger.clear()


# ============================================================
# DATA CLASS
# ============================================================

@dataclass
class ParsedIngredient:
    quantity: float
    unit_symbol: str
    name: str


# ============================================================
# FRACTION / QUANTITY HELPERS
# ============================================================

UNICODE_FRACTIONS = {
    "½": 0.5,
    "⅓": 1 / 3,
    "⅔": 2 / 3,
    "¼": 0.25,
    "¾": 0.75,
    "⅕": 0.2,
    "⅖": 0.4,
    "⅗": 0.6,
    "⅘": 0.8,
    "⅙": 1 / 6,
    "⅚": 5 / 6,
    "⅛": 0.125,
    "⅜": 0.375,
    "⅝": 0.625,
    "⅞": 0.875,
}


def parse_number(value: str) -> float | None:
    """
    Parse common recipe number formats:

    1
    1.5
    1/2
    1 1/2
    2-3
    ½
    1½
    """

    if not value:
        return None

    value = value.strip()

    # Replace unicode fractions when possible.
    for symbol, number in UNICODE_FRACTIONS.items():
        if value == symbol:
            return number

        if value.endswith(symbol):
            prefix = value[:-1].strip()

            if not prefix:
                return number

            try:
                return float(prefix) + number
            except ValueError:
                pass

    # Mixed fraction: 1 1/2
    mixed_match = re.fullmatch(
        r"(\d+(?:\.\d+)?)\s+(\d+)\s*/\s*(\d+)",
        value,
    )

    if mixed_match:
        whole = float(mixed_match.group(1))
        numerator = float(mixed_match.group(2))
        denominator = float(mixed_match.group(3))

        if denominator == 0:
            return None

        return whole + (numerator / denominator)

    # Simple fraction: 1/2
    fraction_match = re.fullmatch(
        r"(\d+)\s*/\s*(\d+)",
        value,
    )

    if fraction_match:
        numerator = float(fraction_match.group(1))
        denominator = float(fraction_match.group(2))

        if denominator == 0:
            return None

        return numerator / denominator

    # Range: 2-3.
    range_match = re.fullmatch(
        r"(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)",
        value,
    )

    if range_match:
        first = float(range_match.group(1))
        second = float(range_match.group(2))

        # Use the lower quantity instead of inventing an average.
        return first if first > 0 else second

    # Normal decimal/integer.
    try:
        return float(value)
    except ValueError:
        return None


# ============================================================
# UNIT NORMALIZATION
# ============================================================

UNIT_ALIASES = {
    # teaspoon
    "tsp": "tsp",
    "tsps": "tsp",
    "teaspoon": "tsp",
    "teaspoons": "tsp",

    # tablespoon
    "tbsp": "tbsp",
    "tbs": "tbsp",
    "tbsps": "tbsp",
    "tablespoon": "tbsp",
    "tablespoons": "tbsp",

    # cup
    "cup": "cup",
    "cups": "cup",

    # gram
    "g": "g",
    "gram": "g",
    "grams": "g",

    # kilogram
    "kg": "kg",
    "kgs": "kg",
    "kilogram": "kg",
    "kilograms": "kg",

    # milliliter
    "ml": "ml",
    "milliliter": "ml",
    "milliliters": "ml",
    "millilitre": "ml",
    "millilitres": "ml",

    # liter
    "l": "L",
    "liter": "L",
    "liters": "L",
    "litre": "L",
    "litres": "L",

    # pinch
    "pinch": "pinch",
    "pinches": "pinch",

    # ounce -> converted to grams
    "oz": "oz",
    "ounce": "oz",
    "ounces": "oz",

    # pound -> converted to grams
    "lb": "lb",
    "lbs": "lb",
    "pound": "lb",
    "pounds": "lb",

    # fluid ounce -> converted to ml
    "fl oz": "fl_oz",
    "fluid ounce": "fl_oz",
    "fluid ounces": "fl_oz",

    # common discrete/package units
    "pc": "pc",
    "pcs": "pc",
    "piece": "pc",
    "pieces": "pc",

    "clove": "pc",
    "cloves": "pc",

    "egg": "pc",
    "eggs": "pc",

    "slice": "pc",
    "slices": "pc",

    "sprig": "pc",
    "sprigs": "pc",

    "can": "pc",
    "cans": "pc",

    "package": "pc",
    "packages": "pc",
    "pkg": "pc",
    "pkgs": "pc",

    "packet": "pc",
    "packets": "pc",

    "bottle": "pc",
    "bottles": "pc",

    "jar": "pc",
    "jars": "pc",

    "container": "pc",
    "containers": "pc",
}


def normalize_unit_token(unit_text: str) -> tuple[str, float | None]:
    """
    Return:

    (database unit symbol, conversion multiplier)

    Conversion multiplier converts source quantity to the
    database unit.

    Examples:

    oz -> g   multiplier 28.3495
    lb -> g   multiplier 453.592
    fl oz -> ml multiplier 29.5735
    """

    key = unit_text.strip().lower()

    if key == "oz":
        return "g", 28.3495

    if key in {"ounce", "ounces"}:
        return "g", 28.3495

    if key in {"lb", "lbs", "pound", "pounds"}:
        return "g", 453.592

    if key in {
        "fl oz",
        "fluid ounce",
        "fluid ounces",
    }:
        return "ml", 29.5735

    symbol = UNIT_ALIASES.get(key)

    if symbol is None:
        return "unk", None

    return symbol, 1.0


# ============================================================
# INGREDIENT CLEANING
# ============================================================

def clean_ingredient_name(name: str) -> str:
    """
    Clean common dataset wording without trying to invent
    a completely different ingredient.
    """

    name = name.strip()

    # Remove leading punctuation.
    name = re.sub(r"^[,\-:;]+", "", name).strip()

    # Remove trailing punctuation.
    name = re.sub(r"[,\-:;]+$", "", name).strip()

    # Remove common preparation words from the beginning.
    name = re.sub(
        r"^(of|and)\s+",
        "",
        name,
        flags=re.IGNORECASE,
    ).strip()

    # Remove common parenthetical preparation details.
    name = re.sub(
        r"\([^)]*\)",
        "",
        name,
    ).strip()

    # Normalize whitespace.
    name = re.sub(r"\s+", " ", name)

    return name.strip()


# ============================================================
# PARSE INGREDIENT STRING
# ============================================================

def parse_ingredient(raw_value: str) -> ParsedIngredient:
    """
    Parse Food.com-style ingredient strings such as:

        2 tablespoons olive oil
        1/2 cup milk
        1 lb chicken breast
        3 cloves garlic
        1 can tomatoes
        2 eggs

    The parser intentionally keeps an ingredient as Unknown
    only when the source does not contain enough information
    to identify a supported unit safely.
    """

    raw = str(raw_value).strip()

    if not raw:
        return ParsedIngredient(
            quantity=1.0,
            unit_symbol="pc",
            name="Ingredient",
        )

    # --------------------------------------------------------
    # Normalize text
    # --------------------------------------------------------

    text = raw.replace("–", "-").replace("—", "-")
    text = re.sub(r"\s+", " ", text).strip()

    # --------------------------------------------------------
    # Quantity at beginning
    # --------------------------------------------------------

    quantity = None
    remainder = text

    quantity_patterns = [
        # 1 1/2
        r"^(?P<number>\d+(?:\.\d+)?\s+\d+\s*/\s*\d+)\s+(?P<rest>.+)$",

        # 1/2
        r"^(?P<number>\d+\s*/\s*\d+)\s*(?P<rest>.+)$",

        # 2-3
        r"^(?P<number>\d+(?:\.\d+)?\s*-\s*\d+(?:\.\d+)?)\s*(?P<rest>.+)$",

        # 1½ / ½
        r"^(?P<number>\d+(?:\.\d+)?[½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞])\s*(?P<rest>.+)$",

        r"^(?P<number>[½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞])\s*(?P<rest>.+)$",

        # 1.5
        r"^(?P<number>\d+(?:\.\d+)?)\s*(?P<rest>.+)$",
    ]

    for pattern in quantity_patterns:
        match = re.match(
            pattern,
            remainder,
            flags=re.IGNORECASE,
        )

        if not match:
            continue

        parsed_quantity = parse_number(
            match.group("number")
        )

        if parsed_quantity is None:
            continue

        quantity = parsed_quantity
        remainder = match.group("rest").strip()
        break

    # --------------------------------------------------------
    # No quantity found
    # --------------------------------------------------------

    if quantity is None:
        # Dataset occasionally contains ingredients without a
        # machine-readable quantity. In that case use one piece
        # rather than Unknown, because the recipe still needs a
        # usable shopping representation.
        return ParsedIngredient(
            quantity=1.0,
            unit_symbol="pc",
            name=clean_ingredient_name(remainder),
        )

    # --------------------------------------------------------
    # Unit detection
    # --------------------------------------------------------

    unit_symbol = "pc"
    conversion_multiplier = 1.0

    # Longest-first to avoid matching "oz" before "fl oz".
    unit_patterns = [
        "fluid ounces",
        "fluid ounce",
        "fl oz",
        "tablespoons",
        "tablespoon",
        "teaspoons",
        "teaspoon",
        "milliliters",
        "milliliter",
        "millilitres",
        "millilitre",
        "kilograms",
        "kilogram",
        "ounces",
        "ounce",
        "pounds",
        "pound",
        "packages",
        "package",
        "packets",
        "packet",
        "containers",
        "container",
        "bottles",
        "bottle",
        "pieces",
        "piece",
        "sprigs",
        "sprig",
        "slices",
        "slice",
        "cloves",
        "clove",
        "cans",
        "can",
        "jars",
        "jar",
        "teaspoons",
        "tsp",
        "tbsp",
        "tbsps",
        "cups",
        "cup",
        "grams",
        "gram",
        "kg",
        "ml",
        "liters",
        "liter",
        "litres",
        "litre",
        "g",
        "l",
        "oz",
        "lb",
        "pinches",
        "pinch",
        "eggs",
        "egg",
        "pcs",
        "pc",
    ]

    unit_pattern = "|".join(
        re.escape(value)
        for value in sorted(
            set(unit_patterns),
            key=len,
            reverse=True,
        )
    )

    unit_match = re.match(
        rf"^(?P<unit>{unit_pattern})(?:\s+|$)(?P<rest>.*)$",
        remainder,
        flags=re.IGNORECASE,
    )

    if unit_match:
        source_unit = unit_match.group("unit")

        unit_symbol, multiplier = normalize_unit_token(
            source_unit
        )

        if multiplier is not None:
            conversion_multiplier = multiplier

        remainder = unit_match.group("rest").strip()

    # --------------------------------------------------------
    # Handle "of ..." formulations
    # --------------------------------------------------------

    remainder = re.sub(
        r"^of\s+",
        "",
        remainder,
        flags=re.IGNORECASE,
    ).strip()

    # --------------------------------------------------------
    # Remove common preparation clauses
    # --------------------------------------------------------

    preparation_patterns = [
        r",\s*finely chopped.*$",
        r",\s*roughly chopped.*$",
        r",\s*chopped.*$",
        r",\s*diced.*$",
        r",\s*sliced.*$",
        r",\s*minced.*$",
        r",\s*grated.*$",
        r",\s*shredded.*$",
        r",\s*crushed.*$",
        r",\s*ground.*$",
        r",\s*peeled.*$",
        r",\s*divided.*$",
        r",\s*to taste.*$",
        r",\s*as needed.*$",
    ]

    for pattern in preparation_patterns:
        remainder = re.sub(
            pattern,
            "",
            remainder,
            flags=re.IGNORECASE,
        )

    remainder = clean_ingredient_name(remainder)

    if not remainder:
        remainder = "Ingredient"

    final_quantity = quantity * conversion_multiplier

    return ParsedIngredient(
        quantity=final_quantity,
        unit_symbol=unit_symbol,
        name=remainder,
    )


# ============================================================
# READ DATASET
# ============================================================

df = pd.read_csv(DATASET_PATH)

if IMPORT_LIMIT is not None:
    df = df.head(IMPORT_LIMIT)

print(f"Importing {len(df)} recipes...")

total_recipes = len(df)

if total_recipes == 0:
    print("No recipes found in dataset.")
    db.close()
    sys.exit(0)


# ============================================================
# LOAD DEFAULT RECORDS
# ============================================================

default_category = (
    db.query(Category)
    .first()
)

default_cuisine = (
    db.query(Cuisine)
    .first()
)

default_difficulty = (
    db.query(Difficulty)
    .first()
)

default_author = (
    db.query(User)
    .first()
)

default_ingredient_category = (
    db.query(IngredientCategory)
    .filter(
        IngredientCategory.name == "Other"
    )
    .first()
)


# ============================================================
# LOAD ALL REQUIRED UNITS
# ============================================================

required_unit_symbols = {
    "cup",
    "g",
    "kg",
    "L",
    "ml",
    "pc",
    "pinch",
    "tbsp",
    "tsp",
    "unk",
}


unit_cache: dict[str, Unit] = {}

for unit in db.query(Unit).all():
    symbol = str(unit.symbol).strip()

    if symbol in required_unit_symbols:
        unit_cache[symbol] = unit


if default_category is None:
    raise Exception("No recipe category found.")

if default_cuisine is None:
    raise Exception("No cuisine found.")

if default_difficulty is None:
    raise Exception("No difficulty found.")

if default_author is None:
    raise Exception("No user found.")

if default_ingredient_category is None:
    raise Exception(
        "Ingredient category 'Other' not found."
    )


missing_unit_symbols = (
    required_unit_symbols - unit_cache.keys()
)

if missing_unit_symbols:
    raise Exception(
        "Missing units in database: "
        + ", ".join(sorted(missing_unit_symbols))
    )


default_unit = unit_cache["unk"]


# ============================================================
# CACHE EXISTING RECIPES
# ============================================================

recipe_cache = {
    recipe.external_id: recipe
    for recipe in db.query(Recipe).all()
}

print(
    f"Loaded {len(recipe_cache):,} existing recipes."
)


# ============================================================
# CACHE EXISTING INGREDIENTS
# ============================================================

ingredient_cache = {
    ingredient.name.strip().lower(): ingredient
    for ingredient in db.query(Ingredient).all()
}

print(
    f"Loaded {len(ingredient_cache):,} ingredients."
)


# ============================================================
# HELPER: GET OR CREATE INGREDIENT
# ============================================================

def get_or_create_ingredient(
    ingredient_name: str,
) -> Ingredient:

    clean_name = clean_ingredient_name(
        ingredient_name
    )

    cache_key = clean_name.lower()

    ingredient = ingredient_cache.get(cache_key)

    if ingredient is not None:
        return ingredient

    ingredient = Ingredient(
        name=clean_name.title(),
        category_id=default_ingredient_category.id,
    )

    db.add(ingredient)
    db.flush()

    ingredient_cache[cache_key] = ingredient

    return ingredient


# ============================================================
# HELPER: REMOVE EXISTING RECIPE INGREDIENTS
# ============================================================

def clear_recipe_ingredients(recipe_id) -> None:
    db.query(RecipeIngredient).filter(
        RecipeIngredient.recipe_id == recipe_id
    ).delete(
        synchronize_session=False
    )


# ============================================================
# IMPORT / REPAIR RECIPES
# ============================================================

for index, row in df.iterrows():

    try:
        external_id = int(row["id"])
    except Exception:
        stats.failed += 1
        logger.log(
            str(row.get("id", "")),
            "Invalid recipe ID",
        )
        continue

    title = row["name"]

    if pd.isna(title):
        stats.skipped += 1
        continue

    title = str(title).strip()[:200]

    # --------------------------------------------------------
    # DESCRIPTION
    # --------------------------------------------------------

    description = row["description"]

    if pd.isna(description):
        description = ""

    description = str(description)

    # --------------------------------------------------------
    # STEPS
    # --------------------------------------------------------

    if pd.isna(row["steps"]):
        stats.skipped += 1
        logger.log(
            external_id,
            "Missing steps",
        )
        continue

    try:
        steps = ast.literal_eval(
            row["steps"]
        )

        if not isinstance(steps, list):
            raise ValueError(
                "Steps is not a list."
            )

        instructions = "\n".join(
            str(step).strip()
            for step in steps
            if str(step).strip()
        )

    except Exception:
        stats.failed += 1
        logger.log(
            external_id,
            "Invalid steps data",
        )
        continue

    # --------------------------------------------------------
    # RECIPE
    # --------------------------------------------------------

    recipe = recipe_cache.get(
        external_id
    )

    is_existing_recipe = recipe is not None

    if recipe is None:

        recipe = Recipe(
            external_id=external_id,
            title=title,
            description=description,
            instructions=instructions,
            prep_time=int(
                row["minutes"] // 2
            ),
            cook_time=int(
                row["minutes"] // 2
            ),
            servings=DEFAULT_SERVINGS,
            image_url=DEFAULT_IMAGE_URL,
            is_published=True,
            is_vegetarian=False,
            is_vegan=False,
            category_id=default_category.id,
            cuisine_id=default_cuisine.id,
            difficulty_id=default_difficulty.id,
            author_id=default_author.id,
        )

        db.add(recipe)
        db.flush()

        recipe_cache[
            external_id
        ] = recipe

    else:

        # Existing recipe:
        # keep its ID and update source fields.
        recipe.title = title
        recipe.description = description
        recipe.instructions = instructions
        recipe.prep_time = int(
            row["minutes"] // 2
        )
        recipe.cook_time = int(
            row["minutes"] // 2
        )

        if recipe.servings is None or recipe.servings <= 0:
            recipe.servings = DEFAULT_SERVINGS

        # Preserve existing image when available.
        if not recipe.image_url:
            recipe.image_url = DEFAULT_IMAGE_URL

    # --------------------------------------------------------
    # INGREDIENTS
    # --------------------------------------------------------

    if pd.isna(row["ingredients"]):
        stats.skipped += 1
        logger.log(
            external_id,
            "Missing ingredients",
        )
        continue

    try:
        ingredients = ast.literal_eval(
            row["ingredients"]
        )

        if not isinstance(ingredients, list):
            raise ValueError(
                "Ingredients is not a list."
            )

    except Exception:
        stats.failed += 1
        logger.log(
            external_id,
            "Invalid ingredients data",
        )
        continue

    # For both newly imported and existing recipes,
    # rebuild the ingredient mapping from the source dataset.
    if is_existing_recipe:
        clear_recipe_ingredients(
            recipe.id
        )

    ingredient_count = 0

    for raw_ingredient in ingredients:

        parsed = parse_ingredient(
            str(raw_ingredient)
        )

        ingredient_name = (
            parsed.name.strip()
        )

        if not ingredient_name:
            continue

        ingredient = get_or_create_ingredient(
            ingredient_name
        )

        unit = unit_cache.get(
            parsed.unit_symbol
        )

        if unit is None:
            unit = default_unit

        recipe_ingredient = RecipeIngredient(
            recipe_id=recipe.id,
            ingredient_id=ingredient.id,
            quantity=max(
                float(parsed.quantity),
                0.0001,
            ),
            unit_id=unit.id,
            is_optional=False,
        )

        db.add(recipe_ingredient)

        ingredient_count += 1

    if ingredient_count == 0:
        stats.skipped += 1
        logger.log(
            external_id,
            "No usable ingredients",
        )
        continue

    stats.imported += 1

    # --------------------------------------------------------
    # COMMIT IN BATCHES
    # --------------------------------------------------------

    if stats.imported % BATCH_SIZE == 0:

        db.commit()

        percentage = (
            stats.imported
            / total_recipes
            * 100
        )

        print(
            f"Processed {stats.imported:,}/"
            f"{total_recipes:,} "
            f"({percentage:.2f}%)"
        )

    elif (
        PROGRESS_INTERVAL
        and stats.imported % PROGRESS_INTERVAL == 0
    ):

        db.commit()

        percentage = (
            stats.imported
            / total_recipes
            * 100
        )

        print(
            f"Processed {stats.imported:,}/"
            f"{total_recipes:,} "
            f"({percentage:.2f}%)"
        )


# ============================================================
# FINAL COMMIT
# ============================================================

db.commit()

stats.print_summary()

print(
    "Recipe import/repair completed successfully!"
)

db.close()