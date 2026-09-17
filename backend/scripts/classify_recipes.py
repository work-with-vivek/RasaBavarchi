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
# FOOD TYPES
# ============================================================

VEGAN = "VEGAN"
VEGETARIAN = "VEGETARIAN"
NON_VEGETARIAN = "NON_VEGETARIAN"
UNKNOWN = "UNKNOWN"


# ============================================================
# RECIPE CLASSIFICATION
#
# Priority:
#
# NON_VEGETARIAN
#        ↓
# UNKNOWN
#        ↓
# VEGETARIAN
#        ↓
# VEGAN
#
# ============================================================

CLASSIFICATION_SQL = """
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

SELECT
    food_type,
    COUNT(*) AS recipe_count

FROM classified

GROUP BY food_type

ORDER BY food_type
"""


# ============================================================
# PANEE​R TEST
# ============================================================

PANEER_TEST_SQL = """
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

SELECT
    r.external_id,
    r.title,
    c.food_type

FROM classified c

JOIN recipes r
    ON r.id = c.recipe_id

WHERE LOWER(r.title) LIKE '%paneer%'

ORDER BY r.title

LIMIT 30
"""


# ============================================================
# IMPORTANT TESTS
# ============================================================

IMPORTANT_TEST_SQL = """
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

SELECT
    r.external_id,
    r.title,
    c.food_type

FROM classified c

JOIN recipes r
    ON r.id = c.recipe_id

WHERE LOWER(r.title) IN (
    'paneer butter masala',
    'cabbage with paneer and tomato  bund gobhi paneer'
)

ORDER BY r.title
"""


# ============================================================
# MAIN
# ============================================================

def main():

    db = SessionLocal()

    try:

        print()
        print("=" * 70)
        print("RECIPE FOOD TYPE CLASSIFICATION - SQL DRY RUN")
        print("=" * 70)

        print()
        print("Classification priority:")
        print(
            "NON_VEGETARIAN > UNKNOWN > "
            "VEGETARIAN > VEGAN"
        )

        # ----------------------------------------------------
        # COUNTS
        # ----------------------------------------------------

        print()
        print("-" * 70)
        print("CALCULATING RECIPE FOOD TYPES")
        print("-" * 70)

        rows = db.execute(
            text(CLASSIFICATION_SQL)
        ).fetchall()

        total = 0

        print()

        for food_type, count in rows:

            print(
                f"{food_type:<20} "
                f"{count:,}"
            )

            total += count

        print("-" * 70)

        print(
            f"{'TOTAL CLASSIFIED':<20}"
            f"{total:,}"
        )

        # ----------------------------------------------------
        # PANEER TEST
        # ----------------------------------------------------

        print()
        print("=" * 70)
        print("PANEER RECIPE TEST")
        print("=" * 70)

        paneer_rows = db.execute(
            text(PANEER_TEST_SQL)
        ).fetchall()

        if not paneer_rows:

            print(
                "No Paneer recipes found."
            )

        else:

            for external_id, title, food_type in paneer_rows:

                print(
                    f"{str(external_id):<10} "
                    f"{food_type:<18} "
                    f"{title}"
                )

        # ----------------------------------------------------
        # IMPORTANT TESTS
        # ----------------------------------------------------

        print()
        print("=" * 70)
        print("IMPORTANT RECIPE TESTS")
        print("=" * 70)

        important_rows = db.execute(
            text(IMPORTANT_TEST_SQL)
        ).fetchall()

        if not important_rows:

            print(
                "Requested test recipes were not found."
            )

        else:

            for external_id, title, food_type in important_rows:

                print()
                print(
                    f"ID:          {external_id}"
                )

                print(
                    f"Title:       {title}"
                )

                print(
                    f"Food type:   {food_type}"
                )

        # ----------------------------------------------------
        # DRY RUN
        # ----------------------------------------------------

        print()
        print("=" * 70)
        print("DRY RUN ONLY")
        print("=" * 70)

        print(
            "DATABASE WAS NOT MODIFIED."
        )

        print(
            "No UPDATE was executed."
        )

        print(
            "No COMMIT was executed."
        )

        print("=" * 70)

    except Exception:

        db.rollback()
        raise

    finally:

        db.close()


if __name__ == "__main__":
    main()