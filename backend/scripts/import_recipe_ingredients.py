import ast

import pandas as pd
from sqlalchemy import func, select

from app.db.session import SessionLocal
from app.models.recipe import Recipe
from app.models.recipe_ingredient import RecipeIngredient

CSV_PATH = r"D:\food\RAW_recipes.csv"

BATCH_SIZE = 5000


def main():
    db = SessionLocal()

    try:
        # ---------------------------------------------------
        # Prevent duplicate imports
        # ---------------------------------------------------
        existing = db.scalar(
            select(func.count()).select_from(RecipeIngredient)
        )

        if existing and existing > 0:
            print(
                f"Recipe ingredients table already contains "
                f"{existing:,} rows."
            )
            print("Import cancelled.")
            return

        # ---------------------------------------------------
        # Load CSV
        # ---------------------------------------------------
        print("Loading CSV...")

        df = pd.read_csv(CSV_PATH)

        print(f"Loaded {len(df):,} recipes from CSV.")

        # ---------------------------------------------------
        # Load recipe mapping into memory
        # ---------------------------------------------------
        print("Loading recipe mapping...")

        recipe_map = {
            recipe.external_id: recipe.id
            for recipe in db.scalars(
                select(Recipe)
            ).all()
        }

        print(
            f"Loaded {len(recipe_map):,} recipes into memory."
        )

        batch = []
        total = 0
        processed = 0
        skipped = 0

        print("Starting ingredient import...\n")

        for _, row in df.iterrows():

            processed += 1

            external_id = int(row["id"])

            recipe_id = recipe_map.get(external_id)

            if recipe_id is None:
                skipped += 1
                continue

            try:
                ingredients = ast.literal_eval(
                    row["ingredients"]
                )
            except Exception:
                skipped += 1
                continue

            for ingredient in ingredients:

                ingredient_name = str(ingredient).strip()

                if not ingredient_name:
                    continue

                batch.append(
                    RecipeIngredient(
                        recipe_id=recipe_id,
                        name=ingredient_name,
                        quantity=1,
                        unit="item",
                        is_optional=False,
                    )
                )

            if len(batch) >= BATCH_SIZE:

                db.bulk_save_objects(batch)
                db.commit()

                total += len(batch)

                print(
                    f"Imported: {total:,} ingredients | "
                    f"Processed recipes: {processed:,}"
                )

                batch.clear()

        # ---------------------------------------------------
        # Insert remaining rows
        # ---------------------------------------------------
        if batch:

            db.bulk_save_objects(batch)
            db.commit()

            total += len(batch)

        print("\n========================================")
        print("IMPORT COMPLETED")
        print("========================================")
        print(f"Recipes processed : {processed:,}")
        print(f"Recipes skipped   : {skipped:,}")
        print(f"Ingredients added : {total:,}")
        print("========================================")

    except Exception as e:
        db.rollback()
        print(f"\nERROR: {e}")

    finally:
        db.close()


if __name__ == "__main__":
    main()