import ast

import pandas as pd
from sqlalchemy import select

from app.dependencies.database import SessionLocal
from app.models.recipe import Recipe
from scripts.import_config import DATASET_PATH


# =========================================================
# Configuration
# =========================================================

BATCH_SIZE = 5000


# =========================================================
# Load Dataset
# =========================================================

print("Loading dataset...")

df = pd.read_csv(DATASET_PATH)

print(f"CSV recipes: {len(df):,}")


# =========================================================
# Build Classification Map
# =========================================================

classification = {}

for _, row in df.iterrows():

    external_id = int(row["id"])

    try:
        tags = ast.literal_eval(row["tags"])
    except Exception:
        tags = []

    tags = {str(tag).strip().lower() for tag in tags}

    is_vegan = "vegan" in tags
    is_vegetarian = "vegetarian" in tags or is_vegan

    classification[external_id] = (
        is_vegetarian,
        is_vegan,
    )


print(
    f"Classification map created: "
    f"{len(classification):,} recipes"
)


# =========================================================
# Statistics From CSV
# =========================================================

csv_vegetarian = sum(
    vegetarian
    for vegetarian, vegan in classification.values()
)

csv_vegan = sum(
    vegan
    for vegetarian, vegan in classification.values()
)

print()
print("CSV classification:")
print(f"  Vegetarian: {csv_vegetarian:,}")
print(f"  Vegan:      {csv_vegan:,}")
print(
    f"  Neither:    "
    f"{len(classification) - csv_vegetarian:,}"
)


# =========================================================
# Database
# =========================================================

db = SessionLocal()

try:

    recipes = db.scalars(
        select(Recipe).where(
            Recipe.external_id.is_not(None)
        )
    ).all()

    print()
    print(
        f"Database recipes with external_id: "
        f"{len(recipes):,}"
    )

    updated = 0
    unchanged = 0
    missing = 0

    # =====================================================
    # Update
    # =====================================================

    for index, recipe in enumerate(recipes, start=1):

        external_id = recipe.external_id

        values = classification.get(external_id)

        if values is None:
            missing += 1
            continue

        new_is_vegetarian, new_is_vegan = values

        if (
            recipe.is_vegetarian == new_is_vegetarian
            and recipe.is_vegan == new_is_vegan
        ):
            unchanged += 1
        else:
            recipe.is_vegetarian = new_is_vegetarian
            recipe.is_vegan = new_is_vegan

            updated += 1

        if index % BATCH_SIZE == 0:

            db.flush()

            print(
                f"Processed {index:,}/"
                f"{len(recipes):,} | "
                f"Updated: {updated:,} | "
                f"Unchanged: {unchanged:,}"
            )

    # =====================================================
    # Commit
    # =====================================================

    print()
    print("Committing changes...")

    db.commit()

    print()
    print("==========================================")
    print("Synchronization completed successfully")
    print("==========================================")
    print(f"Processed:  {len(recipes):,}")
    print(f"Updated:    {updated:,}")
    print(f"Unchanged:  {unchanged:,}")
    print(f"Missing:    {missing:,}")

except Exception:

    print()
    print("ERROR OCCURRED.")
    print("Rolling back all changes...")

    db.rollback()

    raise

finally:
    db.close()