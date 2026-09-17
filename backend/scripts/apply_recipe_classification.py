import os
import sys

sys.path.append(
    os.path.dirname(
        os.path.dirname(__file__)
    )
)

from sqlalchemy import text

from app.dependencies.database import SessionLocal


# ============================================================
# APPLY RECIPE FOOD TYPE CLASSIFICATION
# ============================================================

UPDATE_SQL = """
WITH recipe_types AS (

    SELECT
        ri.recipe_id,

        BOOL_OR(
            i.food_type = 'NON_VEGETARIAN'
        ) AS has_non_vegetarian,

        BOOL_OR(
            i.food_type = 'UNKNOWN'
        ) AS has_unknown,

        BOOL_OR(
            i.food_type = 'VEGETARIAN'
        ) AS has_vegetarian,

        BOOL_AND(
            i.food_type = 'VEGAN'
        ) AS all_vegan

    FROM recipe_ingredients ri

    JOIN ingredients i
        ON i.id = ri.ingredient_id

    GROUP BY ri.recipe_id
),

classified AS (

    SELECT
        recipe_id,

        CASE

            WHEN has_non_vegetarian
                THEN 'NON_VEGETARIAN'

            WHEN has_unknown
                THEN 'UNKNOWN'

            WHEN has_vegetarian
                THEN 'VEGETARIAN'

            WHEN all_vegan
                THEN 'VEGAN'

            ELSE 'UNKNOWN'

        END AS food_type

    FROM recipe_types
)

UPDATE recipes r

SET
    food_type = c.food_type,
    updated_at = NOW()

FROM classified c

WHERE r.id = c.recipe_id
"""


# ============================================================
# MAIN
# ============================================================

def main():

    db = SessionLocal()

    try:

        print()
        print("=" * 70)
        print("APPLY RECIPE FOOD TYPE CLASSIFICATION")
        print("=" * 70)

        print()
        print("Classification priority:")
        print(
            "NON_VEGETARIAN > UNKNOWN > "
            "VEGETARIAN > VEGAN"
        )

        print()
        print("Starting PostgreSQL bulk UPDATE...")
        print("This may take some time, but it is ONE SQL UPDATE.")
        print()

        result = db.execute(
            text(UPDATE_SQL)
        )

        print(
            f"Rows updated: {result.rowcount:,}"
        )

        print()
        print("Committing changes...")

        db.commit()

        print()
        print("=" * 70)
        print("RECIPE CLASSIFICATION APPLIED SUCCESSFULLY")
        print("=" * 70)

    except Exception:

        db.rollback()

        print()
        print("=" * 70)
        print("ERROR")
        print("=" * 70)
        print("Changes were rolled back.")

        raise

    finally:

        db.close()


if __name__ == "__main__":
    main()