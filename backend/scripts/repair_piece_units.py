from __future__ import annotations

import os
import sys

from sqlalchemy import text

# ------------------------------------------------------------
# Add backend root to Python path
# ------------------------------------------------------------

BACKEND_ROOT = os.path.dirname(
    os.path.dirname(os.path.abspath(__file__))
)

if BACKEND_ROOT not in sys.path:
    sys.path.insert(0, BACKEND_ROOT)

from app.dependencies.database import SessionLocal


# ------------------------------------------------------------
# Unit IDs
# ------------------------------------------------------------

PIECE_UNIT_ID = "f7b18c9f-fe06-4c8d-a7e9-d05412b64bd2"
UNKNOWN_UNIT_ID = "b08aaaa0-c9d9-44e1-ad9d-fa0dd6ae6875"


# ------------------------------------------------------------
# Main repair
# ------------------------------------------------------------

def main() -> None:
    db = SessionLocal()

    try:
        print()
        print("=" * 70)
        print("RasaBavarchi - REPAIR BAD PIECE UNITS")
        print("=" * 70)
        print()

        # ----------------------------------------------------
        # Verify current Piece count
        # ----------------------------------------------------

        before = db.execute(
            text(
                """
                SELECT COUNT(*)
                FROM recipe_ingredients
                WHERE unit_id = :piece_unit_id
                """
            ),
            {
                "piece_unit_id": PIECE_UNIT_ID,
            },
        ).scalar_one()

        print(f"Piece rows before repair : {before:,}")

        if before == 0:
            print("Nothing to repair.")
            return

        # ----------------------------------------------------
        # Perform update inside the current transaction
        # ----------------------------------------------------

        result = db.execute(
            text(
                """
                UPDATE recipe_ingredients
                SET unit_id = :unknown_unit_id
                WHERE unit_id = :piece_unit_id
                """
            ),
            {
                "piece_unit_id": PIECE_UNIT_ID,
                "unknown_unit_id": UNKNOWN_UNIT_ID,
            },
        )

        print(
            f"Rows changed             : {result.rowcount:,}"
        )

        # ----------------------------------------------------
        # Verify inside transaction before COMMIT
        # ----------------------------------------------------

        remaining_piece = db.execute(
            text(
                """
                SELECT COUNT(*)
                FROM recipe_ingredients
                WHERE unit_id = :piece_unit_id
                """
            ),
            {
                "piece_unit_id": PIECE_UNIT_ID,
            },
        ).scalar_one()

        unknown_count = db.execute(
            text(
                """
                SELECT COUNT(*)
                FROM recipe_ingredients
                WHERE unit_id = :unknown_unit_id
                """
            ),
            {
                "unknown_unit_id": UNKNOWN_UNIT_ID,
            },
        ).scalar_one()

        print(
            f"Piece rows remaining     : {remaining_piece:,}"
        )
        print(
            f"Unknown rows after repair: {unknown_count:,}"
        )

        # ----------------------------------------------------
        # Safety check
        # ----------------------------------------------------

        if remaining_piece != 0:
            raise RuntimeError(
                "Safety check failed: Piece rows still remain."
            )

        if result.rowcount != before:
            raise RuntimeError(
                "Safety check failed: updated row count "
                "does not match the original Piece count."
            )

        # ----------------------------------------------------
        # Commit
        # ----------------------------------------------------

        db.commit()

        print()
        print("=" * 70)
        print("REPAIR COMPLETED SUCCESSFULLY")
        print("=" * 70)
        print()
        print(
            f"Converted {result.rowcount:,} Piece rows to Unknown."
        )
        print()

    except Exception:
        db.rollback()

        print()
        print("=" * 70)
        print("REPAIR FAILED - TRANSACTION ROLLED BACK")
        print("=" * 70)
        print()

        raise

    finally:
        db.close()


if __name__ == "__main__":
    main()