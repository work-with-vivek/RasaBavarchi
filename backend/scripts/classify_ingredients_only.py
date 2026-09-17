"""
RasaBavarchi
FINAL INGREDIENT CLASSIFICATION

Purpose:
    Classify ingredients only.

Important:
    - Does NOT classify recipes.
    - Does NOT touch recipes table.
    - Preserves existing valid classifications.
    - Only changes an existing classification when an explicit rule says so.
    - Default mode is DRY RUN.
    - Use --apply to commit.

Run:
    python scripts\classify_ingredients_only.py

Apply:
    python scripts\classify_ingredients_only.py --apply
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path


# ============================================================================
# PATH SETUP
# ============================================================================

BACKEND_ROOT = Path(__file__).resolve().parent.parent

if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))


from sqlalchemy import text

from app.dependencies.database import SessionLocal


# ============================================================================
# CONSTANTS
# ============================================================================

VALID_TYPES = {
    "VEGAN",
    "VEGETARIAN",
    "NON_VEGETARIAN",
    "UNKNOWN",
}


# ============================================================================
# NORMALIZATION
# ============================================================================

def normalize(name: str | None) -> str:
    """
    Normalize ingredient names for rule matching.
    """

    if not name:
        return ""

    value = str(name).strip().lower()

    # Normalize curly apostrophes.
    value = value.replace("’", "'")

    # Normalize repeated whitespace.
    value = " ".join(value.split())

    return value


# ============================================================================
# VEGAN
# ============================================================================
#
# ONLY ingredients that are unambiguously vegan.
#
# Do NOT put ambiguous processed products here.
# ============================================================================

VEGAN = {
    # ------------------------------------------------------------------------
    # FRUITS
    # ------------------------------------------------------------------------

    "apple",
    "apples",
    "apricot",
    "apricots",
    "banana",
    "bananas",
    "berries",
    "blackberry",
    "blackberries",
    "blueberries",
    "cherries",
    "cranberries",
    "currants",
    "dates",
    "dried apricots",
    "dried cherries",
    "fig",
    "figs",
    "grapes",
    "grapefruit",
    "kiwi",
    "lemon",
    "lemons",
    "lime",
    "limes",
    "mango",
    "mangoes",
    "orange",
    "oranges",
    "peach",
    "peaches",
    "pear",
    "pears",
    "pineapple",
    "plum",
    "plums",
    "raspberries",
    "strawberries",
    "watermelon",
    "cantaloupe",

    # ------------------------------------------------------------------------
    # VEGETABLES
    # ------------------------------------------------------------------------

    "asparagus",
    "beets",
    "broccoli",
    "brussels sprouts",
    "cabbage",
    "carrot",
    "carrots",
    "cauliflower",
    "celery",
    "corn",
    "cucumber",
    "eggplant",
    "fennel",
    "green chili",
    "green chilies",
    "jalapeno",
    "jalapenos",
    "kale",
    "leek",
    "leeks",
    "lettuce",
    "mushrooms",
    "onion",
    "onions",
    "peas",
    "pepper",
    "peppers",
    "potato",
    "potatoes",
    "pumpkin",
    "radishes",
    "spinach",
    "squash",
    "sweet potato",
    "sweet potatoes",
    "tomato",
    "tomatoes",
    "vegetables",
    "zucchini",
    "yellow squash",

    # ------------------------------------------------------------------------
    # HERBS / SPICES
    # ------------------------------------------------------------------------

    "basil",
    "bay leaf",
    "bay leaves",
    "caraway seed",
    "cardamom",
    "cayenne",
    "chili powder",
    "cilantro",
    "clove",
    "cloves",
    "coriander",
    "coriander powder",
    "cumin",
    "dill",
    "dill weed",
    "fennel seed",
    "garam masala",
    "garlic",
    "ginger",
    "marjoram",
    "mint",
    "nutmeg",
    "oregano",
    "paprika",
    "parsley",
    "poppy seeds",
    "red chili powder",
    "rosemary",
    "sage",
    "thyme",
    "turmeric",

    # ------------------------------------------------------------------------
    # GRAINS / LEGUMES
    # ------------------------------------------------------------------------

    "barley",
    "brown rice",
    "couscous",
    "lentils",
    "oat bran",
    "oatmeal",
    "oats",
    "pasta",
    "penne pasta",
    "quinoa",
    "rice",
    "spaghetti",
    "orzo pasta",

    # ------------------------------------------------------------------------
    # NUTS / SEEDS
    # ------------------------------------------------------------------------

    "almonds",
    "cashews",
    "chia seeds",
    "flax seed",
    "flax seed meal",
    "ground flax seeds",
    "hazelnuts",
    "macadamia nuts",
    "peanuts",
    "pecans",
    "pistachios",
    "sesame seeds",
    "sunflower seeds",
    "walnuts",

    # ------------------------------------------------------------------------
    # OILS
    # ------------------------------------------------------------------------

    "corn oil",
    "olive oil",
    "sunflower oil",
    "vegetable oil",

    # ------------------------------------------------------------------------
    # CLEARLY VEGAN INGREDIENTS
    # ------------------------------------------------------------------------

    "agave nectar",
    "baking soda",
    "bicarbonate of soda",
    "coarse salt",
    "table salt",
    "xanthan gum",
    "tahini",
    "tamari",

    # Coffee / tea
    "coffee",
    "brewed coffee",
    "instant coffee",
    "instant coffee granules",
    "strong coffee",
    "tea bags",

    # Some clearly plant-based basics
    "coconut",
    "coconut flakes",
    "desiccated coconut",
}


# ============================================================================
# VEGETARIAN
# ============================================================================
#
# IMPORTANT:
# Keep this conservative.
#
# Vegetarian is NOT automatically vegan.
#
# We do not classify generic dairy/egg products here unless explicitly
# confirmed by the ingredient data/rules.
# ============================================================================

VEGETARIAN = {
    # Intentionally conservative.
    #
    # Add only ingredients that are certainly vegetarian.
    #
    # Examples could include:
    #
    # "milk",
    # "cheese",
    # "yogurt",
    #
    # BUT they are intentionally not automatically added here.
}


# ============================================================================
# NON-VEGETARIAN
# ============================================================================
#
# These are direct animal meat / fish / seafood ingredients.
# ============================================================================

NON_VEGETARIAN = {
    # ------------------------------------------------------------------------
    # BEEF
    # ------------------------------------------------------------------------

    "beef",
    "ground beef",
    "ground chuck",
    "steak",
    "flank steak",
    "flank steaks",

    # ------------------------------------------------------------------------
    # PORK
    # ------------------------------------------------------------------------

    "pork",
    "ham",
    "bacon",
    "sausage",
    "kielbasa",
    "prosciutto",

    # ------------------------------------------------------------------------
    # POULTRY
    # ------------------------------------------------------------------------

    "chicken",
    "chicken breast",
    "chicken breasts",
    "chicken thigh",
    "chicken thighs",
    "turkey",
    "duck",

    # ------------------------------------------------------------------------
    # OTHER MEAT
    # ------------------------------------------------------------------------

    "lamb",
    "veal",

    # ------------------------------------------------------------------------
    # FISH
    # ------------------------------------------------------------------------

    "fish",
    "fish fillets",
    "salmon",
    "tuna",
    "tilapia",
    "tilapia fillets",
    "cod",
    "sardines",

    # ------------------------------------------------------------------------
    # SEAFOOD
    # ------------------------------------------------------------------------

    "shrimp",
    "prawns",
    "crab",
    "lobster",
    "anchovies",
    "mussels",
    "clams",
    "oysters",
}


# ============================================================================
# KEEP UNKNOWN
# ============================================================================
#
# These were identified during our previous database analysis as ambiguous
# processed ingredients.
#
# IMPORTANT:
# They intentionally remain UNKNOWN.
# ============================================================================

KEEP_UNKNOWN = {
    # ------------------------------------------------------------------------
    # FATS / SPREADS
    # ------------------------------------------------------------------------

    "margarine",
    "shortening",
    "vegetable shortening",

    # ------------------------------------------------------------------------
    # BREAD
    # ------------------------------------------------------------------------

    "bread",
    "white bread",
    "french bread",
    "italian bread",
    "whole wheat bread",

    # ------------------------------------------------------------------------
    # BREADCRUMBS
    # ------------------------------------------------------------------------

    "breadcrumbs",
    "dry breadcrumbs",

    # ------------------------------------------------------------------------
    # CAKE MIX
    # ------------------------------------------------------------------------

    "yellow cake mix",
    "white cake mix",
    "chocolate cake mix",
    "devil's food cake mix",

    # ------------------------------------------------------------------------
    # CHOCOLATE / CHOCOLATE PRODUCTS
    # ------------------------------------------------------------------------

    "semisweet chocolate",
    "semi-sweet chocolate chips",
    "bittersweet chocolate",
    "dark chocolate",
    "white chocolate",
    "chocolate",
    "chocolate chips",
    "chocolate syrup",

    # ------------------------------------------------------------------------
    # MARSHMALLOWS
    # ------------------------------------------------------------------------

    "marshmallows",
    "mini marshmallows",
    "miniature marshmallows",
    "marshmallow creme",

    # ------------------------------------------------------------------------
    # WHIPPED TOPPING
    # ------------------------------------------------------------------------

    "whipped topping",
    "frozen whipped topping",

    # ------------------------------------------------------------------------
    # SAUCES / DRESSINGS
    # ------------------------------------------------------------------------

    "pesto sauce",
    "mayonnaise",
    "light mayonnaise",
    "miracle whip",
    "italian dressing",
    "barbecue sauce",
    "pizza sauce",
    "spaghetti sauce",
    "marinara sauce",
    "tomato sauce",

    # ------------------------------------------------------------------------
    # PUDDING
    # ------------------------------------------------------------------------

    "instant vanilla pudding",
    "vanilla instant pudding mix",
    "instant chocolate pudding mix",

    # ------------------------------------------------------------------------
    # PIE / BAKING PRODUCTS
    # ------------------------------------------------------------------------

    "pie crust",
    "pie crusts",
    "bisquick",

    # ------------------------------------------------------------------------
    # TORTILLA PRODUCTS
    # ------------------------------------------------------------------------

    "flour tortillas",
    "corn tortillas",
    "tortilla chips",

    # ------------------------------------------------------------------------
    # COOKIES
    # ------------------------------------------------------------------------

    "oreo cookies",

    # ------------------------------------------------------------------------
    # CARAMEL
    # ------------------------------------------------------------------------

    "caramels",

    # ------------------------------------------------------------------------
    # FOOD COLORING
    # ------------------------------------------------------------------------

    "white food coloring",
    "red food coloring",
    "green food coloring",
    "food coloring",

    # ------------------------------------------------------------------------
    # ARTIFICIAL SWEETENERS
    # ------------------------------------------------------------------------

    "artificial sweetener",
    "splenda granular",

    # ------------------------------------------------------------------------
    # COOKING SPRAY
    # ------------------------------------------------------------------------

    "cooking spray",
    "nonstick cooking spray",

    # ------------------------------------------------------------------------
    # SOUPS
    # ------------------------------------------------------------------------

    "cream of mushroom soup",

    # ------------------------------------------------------------------------
    # DAIRY / AMBIGUOUS
    # ------------------------------------------------------------------------

    "ghee",
    "creme fraiche",
}


# ============================================================================
# RULE VALIDATION
# ============================================================================

def validate_rules() -> None:
    """
    Ensure no ingredient appears in conflicting rule groups.
    """

    groups = {
        "VEGAN": {normalize(x) for x in VEGAN},
        "VEGETARIAN": {normalize(x) for x in VEGETARIAN},
        "NON_VEGETARIAN": {
            normalize(x) for x in NON_VEGETARIAN
        },
        "KEEP_UNKNOWN": {
            normalize(x) for x in KEEP_UNKNOWN
        },
    }

    print("=" * 90)
    print("VALIDATING INGREDIENT CLASSIFICATION RULES")
    print("=" * 90)

    errors = []

    group_names = list(groups.keys())

    for index, first_name in enumerate(group_names):
        for second_name in group_names[index + 1:]:
            overlap = groups[first_name] & groups[second_name]

            if overlap:
                errors.append(
                    (
                        first_name,
                        second_name,
                        sorted(overlap),
                    )
                )

    if errors:
        print()
        print("RULE VALIDATION FAILED")
        print("=" * 90)

        for first, second, overlap in errors:
            print(f"\nOverlap: {first} vs {second}")

            for item in overlap:
                print(f"  {item}")

        print()

        raise RuntimeError(
            "Ingredient classification rule overlap detected."
        )

    print("RULE VALIDATION PASSED")
    print("=" * 90)


# ============================================================================
# CLASSIFICATION
# ============================================================================

def classify(
    name: str,
    existing_food_type: str | None,
) -> str:
    """
    Determine the food type.

    IMPORTANT BEHAVIOR:

    Explicit rules have priority.

    If there is NO rule for an ingredient:
        preserve the existing valid classification.

    This prevents the classifier from destroying existing database data.
    """

    value = normalize(name)

    existing = (
        existing_food_type.strip().upper()
        if existing_food_type
        else "UNKNOWN"
    )

    # ------------------------------------------------------------------------
    # 1. Explicitly reviewed ambiguous ingredients.
    # ------------------------------------------------------------------------

    if value in KEEP_UNKNOWN:
        return "UNKNOWN"

    # ------------------------------------------------------------------------
    # 2. Explicit non-vegetarian.
    # ------------------------------------------------------------------------

    if value in NON_VEGETARIAN:
        return "NON_VEGETARIAN"

    # ------------------------------------------------------------------------
    # 3. Explicit vegan.
    # ------------------------------------------------------------------------

    if value in VEGAN:
        return "VEGAN"

    # ------------------------------------------------------------------------
    # 4. Explicit vegetarian.
    # ------------------------------------------------------------------------

    if value in VEGETARIAN:
        return "VEGETARIAN"

    # ------------------------------------------------------------------------
    # 5. CRITICAL:
    # Preserve existing valid database classification.
    # ------------------------------------------------------------------------

    if existing in {
        "VEGAN",
        "VEGETARIAN",
        "NON_VEGETARIAN",
    }:
        return existing

    # ------------------------------------------------------------------------
    # 6. Otherwise unknown.
    # ------------------------------------------------------------------------

    return "UNKNOWN"


# ============================================================================
# DATABASE COUNTS
# ============================================================================

def print_counts(title: str, counts: Counter) -> None:
    print()
    print(title)
    print("-" * 90)

    print(
        f"VEGAN:              "
        f"{counts.get('VEGAN', 0):,}"
    )

    print(
        f"VEGETARIAN:         "
        f"{counts.get('VEGETARIAN', 0):,}"
    )

    print(
        f"NON_VEGETARIAN:     "
        f"{counts.get('NON_VEGETARIAN', 0):,}"
    )

    print(
        f"UNKNOWN:            "
        f"{counts.get('UNKNOWN', 0):,}"
    )


# ============================================================================
# MAIN
# ============================================================================

def main() -> None:

    parser = argparse.ArgumentParser(
        description=(
            "Classify RasaBavarchi ingredients only. "
            "Recipes are NOT modified."
        )
    )

    parser.add_argument(
        "--apply",
        action="store_true",
        help="Apply changes to PostgreSQL.",
    )

    args = parser.parse_args()

    # ------------------------------------------------------------------------
    # Validate rules BEFORE touching database.
    # ------------------------------------------------------------------------

    validate_rules()

    db = SessionLocal()

    try:

        # --------------------------------------------------------------------
        # Load ingredients.
        # --------------------------------------------------------------------

        rows = db.execute(
            text(
                """
                SELECT
                    id,
                    name,
                    food_type
                FROM ingredients
                ORDER BY name
                """
            )
        ).fetchall()

        print()
        print("=" * 90)
        print("FINAL INGREDIENT CLASSIFICATION")
        print("=" * 90)

        print(
            f"TOTAL INGREDIENTS:     "
            f"{len(rows):,}"
        )

        # --------------------------------------------------------------------
        # Current database state.
        # --------------------------------------------------------------------

        current_counts = Counter(
            (
                row.food_type or "UNKNOWN"
            ).upper()
            for row in rows
        )

        print_counts(
            "CURRENT DATABASE",
            current_counts,
        )

        # --------------------------------------------------------------------
        # Calculate final state.
        # --------------------------------------------------------------------

        final_counts = Counter()
        changes = []

        for row in rows:

            old_type = (
                row.food_type or "UNKNOWN"
            ).upper()

            new_type = classify(
                row.name,
                old_type,
            )

            final_counts[new_type] += 1

            if old_type != new_type:
                changes.append(
                    {
                        "id": str(row.id),
                        "name": row.name,
                        "old": old_type,
                        "new": new_type,
                    }
                )

        # --------------------------------------------------------------------
        # Display final classification.
        # --------------------------------------------------------------------

        print_counts(
            "FINAL CLASSIFICATION",
            final_counts,
        )

        print()
        print(
            f"ROWS THAT WOULD CHANGE: "
            f"{len(changes):,}"
        )

        # --------------------------------------------------------------------
        # Display changes by type.
        # --------------------------------------------------------------------

        change_counts = Counter(
            item["new"]
            for item in changes
        )

        print()
        print("CHANGE SUMMARY")
        print("-" * 90)

        print(
            f"TO VEGAN:            "
            f"{change_counts.get('VEGAN', 0):,}"
        )

        print(
            f"TO VEGETARIAN:       "
            f"{change_counts.get('VEGETARIAN', 0):,}"
        )

        print(
            f"TO NON_VEGETARIAN:   "
            f"{change_counts.get('NON_VEGETARIAN', 0):,}"
        )

        print(
            f"TO UNKNOWN:          "
            f"{change_counts.get('UNKNOWN', 0):,}"
        )

        # --------------------------------------------------------------------
        # Nothing to change.
        # --------------------------------------------------------------------

        if not changes:

            print()
            print("=" * 90)
            print("NO CHANGES REQUIRED")
            print("=" * 90)

            return

        # --------------------------------------------------------------------
        # DRY RUN.
        # --------------------------------------------------------------------

        if not args.apply:

            print()
            print("=" * 90)
            print("DRY RUN COMPLETE")
            print("=" * 90)
            print("DATABASE WAS NOT MODIFIED.")
            print()
            print(
                "To actually apply ingredient classification:"
            )
            print(
                "python scripts\\classify_ingredients_only.py --apply"
            )
            print("=" * 90)

            return

        # --------------------------------------------------------------------
        # APPLY.
        # --------------------------------------------------------------------

        print()
        print("=" * 90)
        print("APPLYING INGREDIENT CLASSIFICATION")
        print("=" * 90)

        print(
            f"Rows to update: {len(changes):,}"
        )

        # --------------------------------------------------------------------
        # Safety check:
        # Do not accidentally update recipes.
        # --------------------------------------------------------------------

        print()
        print(
            "Target table: ingredients"
        )

        print(
            "Recipe table will NOT be modified."
        )

        # --------------------------------------------------------------------
        # JSON payload for one PostgreSQL UPDATE.
        # --------------------------------------------------------------------

        payload = [
            {
                "id": item["id"],
                "food_type": item["new"],
            }
            for item in changes
        ]

        update_sql = text(
            """
            UPDATE ingredients AS i
            SET
                food_type = v.food_type,
                updated_at = CURRENT_TIMESTAMP
            FROM (
                SELECT
                    (x->>'id')::uuid AS id,
                    x->>'food_type' AS food_type
                FROM jsonb_array_elements(
                    CAST(:payload AS jsonb)
                ) AS x
            ) AS v
            WHERE i.id = v.id
              AND i.food_type IS DISTINCT FROM v.food_type
            """
        )

        print()
        print(
            "Executing ONE PostgreSQL UPDATE..."
        )

        result = db.execute(
            update_sql,
            {
                "payload": json.dumps(
                    payload,
                    separators=(",", ":"),
                )
            },
        )

        print(
            f"PostgreSQL rows updated: "
            f"{result.rowcount:,}"
        )

        # --------------------------------------------------------------------
        # COMMIT INGREDIENTS ONLY.
        # --------------------------------------------------------------------

        print()
        print("Committing ingredient transaction...")

        db.commit()

        print()
        print("=" * 90)
        print("INGREDIENT CLASSIFICATION COMMITTED")
        print("=" * 90)

        print(
            "Recipes were NOT modified."
        )

        # --------------------------------------------------------------------
        # Verify after commit.
        # --------------------------------------------------------------------

        verification_rows = db.execute(
            text(
                """
                SELECT
                    food_type,
                    COUNT(*) AS count
                FROM ingredients
                GROUP BY food_type
                ORDER BY food_type
                """
            )
        ).fetchall()

        verification = Counter()

        for row in verification_rows:
            verification[
                (row.food_type or "UNKNOWN").upper()
            ] = row.count

        print()
        print_counts(
            "DATABASE AFTER COMMIT",
            verification,
        )

        total_after = sum(
            verification.values()
        )

        print()
        print(
            f"TOTAL AFTER COMMIT: "
            f"{total_after:,}"
        )

        if total_after != len(rows):
            raise RuntimeError(
                "Verification failed: ingredient total changed."
            )

        print()
        print("=" * 90)
        print("VERIFICATION PASSED")
        print("=" * 90)

    except Exception:

        # Only rollback if this transaction is still active.
        db.rollback()

        print()
        print("=" * 90)
        print("INGREDIENT CLASSIFICATION FAILED")
        print("=" * 90)

        raise

    finally:
        db.close()


# ============================================================================
# ENTRY POINT
# ============================================================================

if __name__ == "__main__":
    main()