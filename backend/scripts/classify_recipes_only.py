"""
RasaBavarchi - Optimized Recipe Classification

Classification rules:

1. If ANY ingredient is NON_VEGETARIAN
   -> NON_VEGETARIAN

2. Otherwise, if ANY ingredient is UNKNOWN
   -> UNKNOWN

3. Otherwise, if ANY ingredient is VEGETARIAN
   -> VEGETARIAN

4. Otherwise, if ingredients exist and ALL are VEGAN
   -> VEGAN

5. Recipes with no ingredients
   -> UNKNOWN

Default mode:
    DRY RUN

Apply mode:
    python scripts\classify_recipes_only.py --apply
"""

import argparse
import sys
import time
from pathlib import Path

# Make "app" importable when running:
# python scripts\classify_recipes_only.py
BACKEND_DIR = Path(__file__).resolve().parent.parent

if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from sqlalchemy import text

from app.dependencies.database import SessionLocal


# ============================================================================
# SQL: CALCULATE RECIPE CLASSIFICATION
# ============================================================================

CLASSIFICATION_SQL = """
WITH ingredient_summary AS (
    SELECT
        r.id AS recipe_id,

        COUNT(ri.ingredient_id) AS ingredient_count,

        COUNT(*) FILTER (
            WHERE i.food_type = 'NON_VEGETARIAN'
        ) AS non_vegetarian_count,

        COUNT(*) FILTER (
            WHERE i.food_type = 'UNKNOWN'
        ) AS unknown_count,

        COUNT(*) FILTER (
            WHERE i.food_type = 'VEGETARIAN'
        ) AS vegetarian_count,

        COUNT(*) FILTER (
            WHERE i.food_type = 'VEGAN'
        ) AS vegan_count

    FROM recipes AS r

    LEFT JOIN recipe_ingredients AS ri
        ON ri.recipe_id = r.id

    LEFT JOIN ingredients AS i
        ON i.id = ri.ingredient_id

    GROUP BY r.id
)

SELECT
    recipe_id,

    CASE

        WHEN ingredient_count = 0
            THEN 'UNKNOWN'

        WHEN non_vegetarian_count > 0
            THEN 'NON_VEGETARIAN'

        WHEN unknown_count > 0
            THEN 'UNKNOWN'

        WHEN vegetarian_count > 0
            THEN 'VEGETARIAN'

        WHEN vegan_count > 0
            THEN 'VEGAN'

        ELSE 'UNKNOWN'

    END AS food_type

FROM ingredient_summary
"""


# ============================================================================
# COUNT CURRENT DATABASE
# ============================================================================

COUNT_SQL = """
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


# ============================================================================
# COUNT CALCULATED RESULT
# ============================================================================

CALCULATED_COUNT_SQL = f"""
WITH calculated AS (
    {CLASSIFICATION_SQL}
)

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

FROM calculated
"""


# ============================================================================
# COUNT CHANGES
# ============================================================================

CHANGE_COUNT_SQL = f"""
WITH calculated AS (
    {CLASSIFICATION_SQL}
)

SELECT COUNT(*)

FROM recipes AS r

JOIN calculated AS c
    ON c.recipe_id = r.id

WHERE r.food_type IS DISTINCT FROM c.food_type
"""


# ============================================================================
# APPLY
# ============================================================================

APPLY_SQL = f"""
WITH calculated AS (
    {CLASSIFICATION_SQL}
)

UPDATE recipes AS r

SET
    food_type = c.food_type,
    updated_at = CURRENT_TIMESTAMP

FROM calculated AS c

WHERE r.id = c.recipe_id

  AND r.food_type IS DISTINCT FROM c.food_type
"""


# ============================================================================
# PRINT COUNTS
# ============================================================================


def print_counts(title, counts):
    print()
    print(title)
    print("-" * 80)

    print(f"VEGAN              : {counts.vegan:,}")
    print(f"VEGETARIAN         : {counts.vegetarian:,}")
    print(f"NON_VEGETARIAN     : {counts.non_vegetarian:,}")
    print(f"UNKNOWN            : {counts.unknown:,}")
    print(f"TOTAL              : {counts.total:,}")


# ============================================================================
# GET COUNTS
# ============================================================================


def get_counts(db, sql):
    row = db.execute(text(sql)).one()

    return row


# ============================================================================
# MAIN
# ============================================================================


def main():

    parser = argparse.ArgumentParser(
        description="Optimized recipe classification"
    )

    parser.add_argument(
        "--apply",
        action="store_true",
        help="Actually update the database",
    )

    args = parser.parse_args()

    print("=" * 80)
    print("RasaBavarchi - OPTIMIZED RECIPE CLASSIFICATION")
    print("=" * 80)

    if args.apply:
        print()
        print("MODE: APPLY")
        print("DATABASE WILL BE MODIFIED.")
    else:
        print()
        print("MODE: DRY RUN")
        print("DATABASE WILL NOT BE MODIFIED.")

    print()

    db = SessionLocal()

    try:

        # ---------------------------------------------------------------
        # CURRENT COUNTS
        # ---------------------------------------------------------------

        start = time.perf_counter()

        current = get_counts(db, COUNT_SQL)

        current_time = time.perf_counter() - start

        print_counts(
            "CURRENT DATABASE",
            current,
        )

        print()
        print(f"Current count query time: {current_time:.3f} seconds")

        # ---------------------------------------------------------------
        # CALCULATED COUNTS
        # ---------------------------------------------------------------

        print()
        print("=" * 80)
        print("CALCULATING RECIPE CLASSIFICATIONS")
        print("=" * 80)

        start = time.perf_counter()

        calculated = get_counts(
            db,
            CALCULATED_COUNT_SQL,
        )

        calculation_time = time.perf_counter() - start

        print_counts(
            "CALCULATED CLASSIFICATION",
            calculated,
        )

        print()
        print(
            f"Classification calculation time: "
            f"{calculation_time:.3f} seconds"
        )

        # ---------------------------------------------------------------
        # CHANGES
        # ---------------------------------------------------------------

        start = time.perf_counter()

        changes = db.execute(
            text(CHANGE_COUNT_SQL)
        ).scalar_one()

        change_time = time.perf_counter() - start

        print()
        print("=" * 80)
        print("CLASSIFICATION CHANGES")
        print("=" * 80)

        print(
            f"ROWS THAT WOULD CHANGE: {changes:,}"
        )

        print()
        print(
            f"Change detection time: {change_time:.3f} seconds"
        )

        # ---------------------------------------------------------------
        # DRY RUN
        # ---------------------------------------------------------------

        if not args.apply:

            print()
            print("=" * 80)
            print("DRY RUN COMPLETE")
            print("=" * 80)

            print()
            print("DATABASE WAS NOT MODIFIED.")

            print()
            print(
                "To apply the classification:"
            )

            print()
            print(
                "python scripts\\classify_recipes_only.py --apply"
            )

            return

        # ---------------------------------------------------------------
        # APPLY
        # ---------------------------------------------------------------

        print()
        print("=" * 80)
        print("APPLYING RECIPE CLASSIFICATION")
        print("=" * 80)

        if changes == 0:

            print()
            print("Nothing to update.")
            print("Database is already classified.")

            return

        print()
        print(
            f"Rows to update: {changes:,}"
        )

        print()
        print(
            "Executing ONE PostgreSQL UPDATE..."
        )

        start = time.perf_counter()

        result = db.execute(
            text(APPLY_SQL)
        )

        apply_time = time.perf_counter() - start

        updated = result.rowcount

        print()
        print(
            f"PostgreSQL rows updated: {updated:,}"
        )

        print(
            f"UPDATE execution time: {apply_time:.3f} seconds"
        )

        # ---------------------------------------------------------------
        # COMMIT
        # ---------------------------------------------------------------

        print()
        print("Committing transaction...")

        db.commit()

        print()
        print("=" * 80)
        print("RECIPE CLASSIFICATION COMMITTED SUCCESSFULLY")
        print("=" * 80)

        # ---------------------------------------------------------------
        # VERIFY
        # ---------------------------------------------------------------

        print()
        print("VERIFYING DATABASE...")

        verified = get_counts(
            db,
            COUNT_SQL,
        )

        print_counts(
            "FINAL DATABASE",
            verified,
        )

        print()
        print("=" * 80)
        print("DONE")
        print("=" * 80)

    except Exception:

        db.rollback()

        print()
        print("=" * 80)
        print("ERROR")
        print("=" * 80)

        print()
        print(
            "Transaction rolled back."
        )

        raise

    finally:

        db.close()


if __name__ == "__main__":
    main()