"""
RasaBavarchi - Food Classification Validator

READ-ONLY VALIDATION.

This script NEVER modifies the database.

It validates:
1. Application ingredient classifications.
2. UNKNOWN ingredient count.
3. Duplicate recipe/ingredient relationships.
4. Vegan recipe integrity.
5. Vegetarian recipe integrity.
6. Non-vegetarian recipe integrity.
7. Stored recipe food_type vs calculated food_type.
"""

import sys
from pathlib import Path

from sqlalchemy import text

# Make "app" importable when running:
# python scripts\validate_food_classification.py
BACKEND_DIR = Path(__file__).resolve().parent.parent

if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app.dependencies.database import SessionLocal


def print_result(number, name, passed, detail=""):
    status = "PASS" if passed else "FAIL"

    print(
        f"[{number}] {name:<45} {status}"
        + (f"  {detail}" if detail else "")
    )

    return passed


def main():
    print("=" * 90)
    print("RasaBavarchi - FOOD CLASSIFICATION VALIDATION")
    print("=" * 90)
    print()
    print("READ-ONLY MODE")
    print("DATABASE WILL NOT BE MODIFIED.")
    print()

    db = SessionLocal()

    results = []

    try:
        # ================================================================
        # 1. INGREDIENT CLASSIFICATIONS
        # ================================================================

        row = db.execute(
            text(
                """
                SELECT
                    COUNT(*) FILTER (
                        WHERE food_type = 'VEGAN'
                    ) AS vegan,

                    COUNT(*) FILTER (
                        WHERE food_type = 'VEGETARIAN'
                    ) AS vegetarian,

                    COUNT(*) FILTER (
                        WHERE food_type = 'NON_VEGETARIAN'
                    ) AS non_vegetarian,

                    COUNT(*) FILTER (
                        WHERE food_type = 'UNKNOWN'
                    ) AS unknown,

                    COUNT(*) AS total

                FROM ingredients
                """
            )
        ).one()

        print("INGREDIENT CLASSIFICATIONS")
        print("-" * 90)
        print(f"VEGAN              : {row.vegan:>10,}")
        print(f"VEGETARIAN         : {row.vegetarian:>10,}")
        print(f"NON_VEGETARIAN     : {row.non_vegetarian:>10,}")
        print(f"UNKNOWN            : {row.unknown:>10,}")
        print(f"TOTAL              : {row.total:>10,}")
        print()

        ingredient_total_ok = row.total == 14942

        results.append(
            print_result(
                1,
                "Application ingredient count",
                ingredient_total_ok,
                f"expected=14,942 actual={row.total:,}",
            )
        )

        results.append(
            print_result(
                2,
                "UNKNOWN ingredient count",
                row.unknown == 0,
                f"unknown={row.unknown:,}",
            )
        )

        # ================================================================
        # 2. DUPLICATE RECIPE INGREDIENT RELATIONSHIPS
        # ================================================================

        duplicate_count = db.execute(
            text(
                """
                SELECT COUNT(*)
                FROM (
                    SELECT recipe_id, ingredient_id
                    FROM recipe_ingredients
                    GROUP BY recipe_id, ingredient_id
                    HAVING COUNT(*) != 1
                ) duplicates
                """
            )
        ).scalar_one()

        results.append(
            print_result(
                3,
                "Duplicate recipe/ingredient relationships",
                duplicate_count == 0,
                f"duplicates={duplicate_count:,}",
            )
        )

        # ================================================================
        # 3. INVALID VEGAN RECIPES
        # ================================================================

        invalid_vegan = db.execute(
            text(
                """
                SELECT COUNT(*)
                FROM (
                    SELECT r.id
                    FROM recipes r
                    JOIN recipe_ingredients ri
                        ON ri.recipe_id = r.id
                    JOIN ingredients i
                        ON i.id = ri.ingredient_id
                    WHERE r.food_type = 'VEGAN'
                    GROUP BY r.id
                    HAVING
                        COUNT(*) FILTER (
                            WHERE i.food_type = 'NON_VEGETARIAN'
                        ) != 0

                        OR

                        COUNT(*) FILTER (
                            WHERE i.food_type = 'UNKNOWN'
                        ) != 0
                ) invalid
                """
            )
        ).scalar_one()

        results.append(
            print_result(
                4,
                "Invalid VEGAN recipes",
                invalid_vegan == 0,
                f"invalid={invalid_vegan:,}",
            )
        )

        # ================================================================
        # 4. INVALID VEGETARIAN RECIPES
        # ================================================================

        invalid_vegetarian = db.execute(
            text(
                """
                SELECT COUNT(*)
                FROM (
                    SELECT r.id
                    FROM recipes r
                    JOIN recipe_ingredients ri
                        ON ri.recipe_id = r.id
                    JOIN ingredients i
                        ON i.id = ri.ingredient_id
                    WHERE r.food_type = 'VEGETARIAN'
                    GROUP BY r.id
                    HAVING
                        COUNT(*) FILTER (
                            WHERE i.food_type = 'NON_VEGETARIAN'
                        ) != 0

                        OR

                        COUNT(*) FILTER (
                            WHERE i.food_type = 'UNKNOWN'
                        ) != 0
                ) invalid
                """
            )
        ).scalar_one()

        results.append(
            print_result(
                5,
                "Invalid VEGETARIAN recipes",
                invalid_vegetarian == 0,
                f"invalid={invalid_vegetarian:,}",
            )
        )

        # ================================================================
        # 5. INVALID NON-VEGETARIAN RECIPES
        # ================================================================

        invalid_non_vegetarian = db.execute(
            text(
                """
                SELECT COUNT(*)
                FROM (
                    SELECT r.id
                    FROM recipes r
                    JOIN recipe_ingredients ri
                        ON ri.recipe_id = r.id
                    JOIN ingredients i
                        ON i.id = ri.ingredient_id
                    WHERE r.food_type = 'NON_VEGETARIAN'
                    GROUP BY r.id
                    HAVING
                        COUNT(*) FILTER (
                            WHERE i.food_type = 'NON_VEGETARIAN'
                        ) = 0
                ) invalid
                """
            )
        ).scalar_one()

        results.append(
            print_result(
                6,
                "Invalid NON_VEGETARIAN recipes",
                invalid_non_vegetarian == 0,
                f"invalid={invalid_non_vegetarian:,}",
            )
        )

        # ================================================================
        # 6. STORED VS CALCULATED CLASSIFICATION
        # ================================================================

        mismatch_count = db.execute(
            text(
                """
                WITH calculated AS (

                    SELECT
                        r.id AS recipe_id,

                        CASE

                            WHEN COUNT(ri.ingredient_id) = 0
                                THEN 'UNKNOWN'

                            WHEN COUNT(*) FILTER (
                                WHERE i.food_type = 'NON_VEGETARIAN'
                            ) != 0
                                THEN 'NON_VEGETARIAN'

                            WHEN COUNT(*) FILTER (
                                WHERE i.food_type = 'UNKNOWN'
                            ) != 0
                                THEN 'UNKNOWN'

                            WHEN COUNT(*) FILTER (
                                WHERE i.food_type = 'VEGETARIAN'
                            ) != 0
                                THEN 'VEGETARIAN'

                            WHEN COUNT(*) FILTER (
                                WHERE i.food_type = 'VEGAN'
                            ) != 0
                                THEN 'VEGAN'

                            ELSE 'UNKNOWN'

                        END AS calculated_type

                    FROM recipes r

                    LEFT JOIN recipe_ingredients ri
                        ON ri.recipe_id = r.id

                    LEFT JOIN ingredients i
                        ON i.id = ri.ingredient_id

                    GROUP BY r.id
                )

                SELECT COUNT(*)

                FROM recipes r

                JOIN calculated c
                    ON c.recipe_id = r.id

                WHERE r.food_type IS DISTINCT FROM c.calculated_type
                """
            )
        ).scalar_one()

        results.append(
            print_result(
                7,
                "Stored vs calculated recipe classifications",
                mismatch_count == 0,
                f"mismatches={mismatch_count:,}",
            )
        )

        # ================================================================
        # 7. RECIPE TOTALS
        # ================================================================

        recipe_counts = db.execute(
            text(
                """
                SELECT
                    COUNT(*) FILTER (
                        WHERE food_type = 'VEGAN'
                    ) AS vegan,

                    COUNT(*) FILTER (
                        WHERE food_type = 'VEGETARIAN'
                    ) AS vegetarian,

                    COUNT(*) FILTER (
                        WHERE food_type = 'NON_VEGETARIAN'
                    ) AS non_vegetarian,

                    COUNT(*) FILTER (
                        WHERE food_type = 'UNKNOWN'
                    ) AS unknown,

                    COUNT(*) AS total

                FROM recipes
                """
            )
        ).one()

        print()
        print("RECIPE CLASSIFICATIONS")
        print("-" * 90)
        print(f"VEGAN              : {recipe_counts.vegan:>10,}")
        print(f"VEGETARIAN         : {recipe_counts.vegetarian:>10,}")
        print(f"NON_VEGETARIAN     : {recipe_counts.non_vegetarian:>10,}")
        print(f"UNKNOWN            : {recipe_counts.unknown:>10,}")
        print(f"TOTAL              : {recipe_counts.total:>10,}")

        expected_recipe_total = 231637

        results.append(
            print_result(
                8,
                "Recipe total",
                recipe_counts.total == expected_recipe_total,
                f"expected={expected_recipe_total:,} "
                f"actual={recipe_counts.total:,}",
            )
        )

        # ================================================================
        # FINAL RESULT
        # ================================================================

        print()
        print("=" * 90)

        if all(results):
            print("VALIDATION PASSED")
            print("=" * 90)
            print()
            print("All food classification integrity checks passed.")
            return 0

        print("VALIDATION FAILED")
        print("=" * 90)
        print()
        print("One or more integrity checks failed.")
        return 1

    except Exception:
        db.rollback()

        print()
        print("=" * 90)
        print("VALIDATION ERROR")
        print("=" * 90)

        raise

    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(main())