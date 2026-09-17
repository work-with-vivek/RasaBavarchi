from __future__ import annotations

import os
import sys

from sqlalchemy import text

# Add backend root to Python path.
BACKEND_ROOT = os.path.dirname(
    os.path.dirname(os.path.abspath(__file__))
)

if BACKEND_ROOT not in sys.path:
    sys.path.insert(0, BACKEND_ROOT)

from app.dependencies.database import SessionLocal


PIECE_UNIT_ID = "f7b18c9f-fe06-4c8d-a7e9-d05412b64bd2"

SQL = """
SELECT
    ri.quantity,
    i.name,
    r.title
FROM recipe_ingredients AS ri
JOIN ingredients AS i
    ON i.id = ri.ingredient_id
JOIN recipes AS r
    ON r.id = ri.recipe_id
WHERE ri.unit_id = :piece_unit_id
  AND ri.quantity <> 1
ORDER BY ri.quantity, r.title
LIMIT 100
"""


def main() -> None:
    db = SessionLocal()

    try:
        rows = db.execute(
            text(SQL),
            {
                "piece_unit_id": PIECE_UNIT_ID,
            },
        ).all()

        print()
        print("=" * 100)
        print("NON-1 PIECE SAMPLE")
        print("=" * 100)

        if not rows:
            print("No non-1 Piece rows found.")
            return

        for quantity, ingredient, recipe in rows:
            print(
                f"{quantity} Piece | "
                f"{ingredient} | "
                f"{recipe}"
            )

        print("=" * 100)
        print(f"Rows displayed: {len(rows)}")
        print("=" * 100)

    finally:
        db.close()


if __name__ == "__main__":
    main()