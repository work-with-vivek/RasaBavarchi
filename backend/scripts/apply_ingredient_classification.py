import os
import sys
from datetime import datetime, timezone

sys.path.append(
    os.path.dirname(
        os.path.dirname(__file__)
    )
)

from app.dependencies.database import SessionLocal
from app.models.ingredient import Ingredient

from scripts.classify_ingredients import classify_ingredient


def main():
    db = SessionLocal()

    try:
        ingredients = (
            db.query(Ingredient)
            .order_by(Ingredient.name.asc())
            .all()
        )

        print()
        print("=" * 70)
        print("APPLY INGREDIENT CLASSIFICATION - V9")
        print("=" * 70)
        print()
        print(f"Total ingredients: {len(ingredients):,}")
        print()

        counts = {
            "VEGAN": 0,
            "VEGETARIAN": 0,
            "NON_VEGETARIAN": 0,
            "UNKNOWN": 0,
        }

        changed = 0
        unchanged = 0

        now = datetime.now(timezone.utc)

        for ingredient in ingredients:
            old_type = ingredient.food_type

            new_type = classify_ingredient(
                ingredient.name
            )

            if new_type not in counts:
                new_type = "UNKNOWN"

            counts[new_type] += 1

            if old_type != new_type:
                ingredient.food_type = new_type
                ingredient.updated_at = now
                changed += 1
            else:
                unchanged += 1

        print("-" * 70)
        print("CLASSIFICATION TO APPLY")
        print("-" * 70)

        print(
            f"VEGAN:                   {counts['VEGAN']:,}"
        )
        print(
            f"VEGETARIAN:              {counts['VEGETARIAN']:,}"
        )
        print(
            f"NON-VEGETARIAN:          {counts['NON_VEGETARIAN']:,}"
        )
        print(
            f"UNKNOWN:                 {counts['UNKNOWN']:,}"
        )

        print()
        print(
            f"Rows changed:             {changed:,}"
        )
        print(
            f"Rows unchanged:           {unchanged:,}"
        )

        print()
        print("Committing changes...")

        db.commit()

        print()
        print("=" * 70)
        print("CLASSIFICATION APPLIED SUCCESSFULLY")
        print("=" * 70)

    except Exception:
        db.rollback()
        raise

    finally:
        db.close()


if __name__ == "__main__":
    main()