"""
RasaBavarchi - Master Ingredient Synchronization

Purpose
-------
Synchronizes ingredient classifications from the separate master database
(my_database) into the RasaBavarchi application database.

Master database:
    my_database.ingredients
        name
        dietary_type

Application database:
    RasaBavarchi.ingredients
        name
        food_type

Rules
-----
1. Master database is authoritative.
2. Matching is performed using normalized ingredient names.
3. No fuzzy matching.
4. No ingredients are created.
5. No ingredients are deleted.
6. Existing application ingredient IDs are preserved.
7. Default mode is DRY RUN.
8. --apply performs the actual update.
9. All updates happen inside one transaction.
10. Final counts are verified after commit.

Usage
-----
Dry run:
    python scripts\\sync_ingredient_master.py

Apply:
    python scripts\\sync_ingredient_master.py --apply
"""

from __future__ import annotations

import argparse
import os
import sys
import time
from collections import Counter

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

# ---------------------------------------------------------------------------
# Make "app" importable when executing:
#
# python scripts\sync_ingredient_master.py
# ---------------------------------------------------------------------------

BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)


from app.dependencies.database import SessionLocal


# ============================================================================
# CONFIGURATION
# ============================================================================

MASTER_DATABASE_URL = os.getenv(
    "MASTER_DATABASE_URL",
    "postgresql+psycopg://postgres:Vm07746293@localhost:5432/my_database",
)

VALID_TYPES = {
    "VEGAN",
    "VEGETARIAN",
    "NON_VEGETARIAN",
}


# ============================================================================
# NORMALIZATION
# ============================================================================


def normalize_name(name: str) -> str:
    """
    Normalize ingredient names for exact matching.

    Examples:

        " Chicken Breast "
            -> "chicken breast"

        "Chicken  Breast"
            -> "chicken breast"
    """

    if name is None:
        return ""

    return " ".join(name.strip().lower().split())


# ============================================================================
# MASTER DATABASE
# ============================================================================


def create_master_engine() -> Engine:
    """
    Create a connection to the master ingredient database.
    """

    return create_engine(
        MASTER_DATABASE_URL,
        pool_pre_ping=True,
        future=True,
    )


def load_master_ingredients(engine: Engine) -> dict[str, str]:
    """
    Load all master ingredients.

    Returns:

        normalized_name -> food_type
    """

    print()
    print("=" * 90)
    print("LOADING MASTER INGREDIENT DATABASE")
    print("=" * 90)

    with engine.connect() as connection:
        rows = connection.execute(
            text(
                """
                SELECT
                    name,
                    dietary_type
                FROM ingredients
                ORDER BY id
                """
            )
        ).fetchall()

    print(f"Master rows loaded: {len(rows):,}")

    master = {}
    duplicates = []

    for name, dietary_type in rows:
        normalized = normalize_name(name)

        if not normalized:
            raise RuntimeError(
                f"Master database contains an empty ingredient name: {name!r}"
            )

        normalized_type = dietary_type.strip().upper().replace('-', '_')

        if normalized_type not in VALID_TYPES:
            raise RuntimeError(
                f"Invalid dietary_type in master database: "
                f"{name!r} -> {dietary_type!r}"
            )

        if normalized in master:
            duplicates.append(name)
        else:
            master[normalized] = normalized_type

    if duplicates:
        print()
        print("ERROR: NORMALIZED DUPLICATES FOUND")
        print("-" * 90)

        for name in duplicates[:50]:
            print(name)

        if len(duplicates) > 50:
            print(f"... and {len(duplicates) - 50:,} more")

        raise RuntimeError(
            "Master database contains duplicate normalized ingredient names."
        )

    print(f"Unique normalized master ingredients: {len(master):,}")

    print()
    print("MASTER CLASSIFICATION COUNTS")
    print("-" * 90)

    counts = Counter(master.values())

    for food_type in (
        "VEGAN",
        "VEGETARIAN",
        "NON_VEGETARIAN",
    ):
        print(f"{food_type:<20}: {counts[food_type]:>8,}")

    return master


# ============================================================================
# APPLICATION DATABASE
# ============================================================================


def load_application_ingredients(db) -> list[tuple]:
    """
    Load all application ingredients.
    """

    return db.execute(
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


# ============================================================================
# ANALYSIS
# ============================================================================


def analyze_matches(
    application_rows,
    master: dict[str, str],
):
    """
    Compare application ingredients against master ingredients.
    """

    matched = []
    unmatched = []
    changes = []

    for row in application_rows:
        ingredient_id = row.id
        name = row.name
        current_type = row.food_type

        normalized = normalize_name(name)

        if normalized not in master:
            unmatched.append(
                {
                    "id": ingredient_id,
                    "name": name,
                    "current_type": current_type,
                }
            )
            continue

        master_type = master[normalized]

        matched.append(
            {
                "id": ingredient_id,
                "name": name,
                "current_type": current_type,
                "master_type": master_type,
            }
        )

        if current_type != master_type:
            changes.append(
                {
                    "id": ingredient_id,
                    "name": name,
                    "current_type": current_type,
                    "master_type": master_type,
                }
            )

    return matched, unmatched, changes


# ============================================================================
# DISPLAY
# ============================================================================


def print_current_counts(db):
    """
    Print current RasaBavarchi ingredient classification counts.
    """

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

    print()
    print("RASABAVARCHI INGREDIENT DATABASE")
    print("-" * 90)
    print(f"{'VEGAN':<20}: {row.vegan:>8,}")
    print(f"{'VEGETARIAN':<20}: {row.vegetarian:>8,}")
    print(f"{'NON_VEGETARIAN':<20}: {row.non_vegetarian:>8,}")
    print(f"{'UNKNOWN':<20}: {row.unknown:>8,}")
    print("-" * 90)
    print(f"{'TOTAL':<20}: {row.total:>8,}")

    return row


def print_changes(changes):
    """
    Print all changes.
    """

    print()
    print("=" * 90)
    print("CLASSIFICATION CHANGES")
    print("=" * 90)

    print(f"Rows that would change: {len(changes):,}")

    if not changes:
        print()
        print("No ingredient classifications need updating.")
        return

    print()
    print("CHANGE SUMMARY")
    print("-" * 90)

    summary = Counter(
        (
            change["current_type"],
            change["master_type"],
        )
        for change in changes
    )

    for (old_type, new_type), count in sorted(summary.items()):
        print(
            f"{old_type:<20} -> "
            f"{new_type:<20}: {count:>8,}"
        )

    print()
    print("CHANGES")
    print("-" * 90)

    for change in changes:
        print(
            f"{change['name']:<60} "
            f"{change['current_type']} -> {change['master_type']}"
        )


def print_unmatched(unmatched):
    """
    Print application ingredients that do not exist in master.
    """

    print()
    print("=" * 90)
    print("UNMATCHED APPLICATION INGREDIENTS")
    print("=" * 90)

    print(f"Unmatched rows: {len(unmatched):,}")

    if not unmatched:
        print("All application ingredients matched the master database.")
        return

    print()
    print("These ingredients WILL NOT be changed.")
    print("-" * 90)

    for row in unmatched[:100]:
        print(
            f"{row['name']:<60} "
            f"current={row['current_type']}"
        )

    if len(unmatched) > 100:
        print()
        print(
            f"... and {len(unmatched) - 100:,} additional unmatched ingredients."
        )


# ============================================================================
# APPLY
# ============================================================================


def apply_changes(db, changes):
    """
    Apply master classifications to the RasaBavarchi database.

    Only matched rows are updated.
    """

    if not changes:
        print()
        print("Nothing to update.")
        return 0

    print()
    print("=" * 90)
    print("APPLYING MASTER CLASSIFICATIONS")
    print("=" * 90)

    payload = [
        {
            "id": str(change["id"]),
            "food_type": change["master_type"],
        }
        for change in changes
    ]

    # PostgreSQL JSONB bulk update.
    result = db.execute(
        text(
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
        ),
        {
            "payload": __import__("json").dumps(payload),
        },
    )

    print(f"PostgreSQL rows updated: {result.rowcount:,}")

    return result.rowcount


# ============================================================================
# VERIFICATION
# ============================================================================


def verify_counts(db, master, application_rows):
    """
    Verify the final RasaBavarchi ingredient database.

    The master database is the classification authority and contains
    one canonical entry per normalized ingredient.

    The application database may contain multiple rows that normalize
    to the same ingredient name. Therefore application classification
    counts are NOT required to equal master row counts.

    Verification rules:

    1. Application ingredient row count must not change.
    2. No UNKNOWN classifications may remain.
    3. Every application ingredient must have a master match.
    4. Every application ingredient classification must match the
       classification assigned by the master database.

    This allows duplicate application ingredients while ensuring that
    every application row is classified correctly.
    """

    # ------------------------------------------------------------------
    # CURRENT APPLICATION COUNTS
    # ------------------------------------------------------------------

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

    print()
    print("=" * 90)
    print("FINAL DATABASE VERIFICATION")
    print("=" * 90)

    print(f"{'VEGAN':<20}: {row.vegan:>8,}")
    print(f"{'VEGETARIAN':<20}: {row.vegetarian:>8,}")
    print(f"{'NON_VEGETARIAN':<20}: {row.non_vegetarian:>8,}")
    print(f"{'UNKNOWN':<20}: {row.unknown:>8,}")
    print("-" * 90)
    print(f"{'TOTAL':<20}: {row.total:>8,}")

    # ------------------------------------------------------------------
    # 1. APPLICATION ROW COUNT MUST NOT CHANGE
    # ------------------------------------------------------------------

    expected_total = len(application_rows)

    if row.total != expected_total:
        raise RuntimeError(
            f"Total ingredient count changed unexpectedly. "
            f"Expected {expected_total:,}, got {row.total:,}."
        )

    # ------------------------------------------------------------------
    # 2. UNKNOWN MUST BE ZERO
    # ------------------------------------------------------------------

    if row.unknown != 0:
        raise RuntimeError(
            f"Verification failed: "
            f"{row.unknown:,} UNKNOWN ingredients remain."
        )

    # ------------------------------------------------------------------
    # 3. VERIFY EVERY APPLICATION INGREDIENT AGAINST MASTER
    # ------------------------------------------------------------------
    #
    # IMPORTANT:
    #
    # We intentionally do NOT compare:
    #
    #     application VEGAN count == master VEGAN count
    #
    # because application ingredients can contain duplicate normalized
    # names.
    #
    # Instead, we verify each application row individually.
    # ------------------------------------------------------------------

    mismatches = []

    for ingredient_id, name, food_type in application_rows:
        normalized_name = normalize_name(name)

        expected_type = master.get(normalized_name)

        if expected_type is None:
            mismatches.append(
                {
                    "id": ingredient_id,
                    "name": name,
                    "actual": food_type,
                    "expected": None,
                    "reason": "MASTER_MATCH_NOT_FOUND",
                }
            )

            continue

        if food_type != expected_type:
            mismatches.append(
                {
                    "id": ingredient_id,
                    "name": name,
                    "actual": food_type,
                    "expected": expected_type,
                    "reason": "CLASSIFICATION_MISMATCH",
                }
            )

    # ------------------------------------------------------------------
    # 4. REPORT MISMATCHES
    # ------------------------------------------------------------------

    if mismatches:
        print()
        print("=" * 90)
        print("VERIFICATION MISMATCHES")
        print("=" * 90)

        print(f"Rows with verification errors: {len(mismatches):,}")

        for item in mismatches[:100]:
            print(
                f"{item['name']!r} "
                f"| actual={item['actual']!r} "
                f"| expected={item['expected']!r} "
                f"| reason={item['reason']}"
            )

        if len(mismatches) > 100:
            print()
            print(
                f"... {len(mismatches) - 100:,} additional mismatches "
                f"not displayed."
            )

        raise RuntimeError(
            f"Ingredient verification failed: "
            f"{len(mismatches):,} application rows do not match "
            f"the master classification."
        )

    # ------------------------------------------------------------------
    # SUCCESS
    # ------------------------------------------------------------------

    print()
    print("MASTER / APPLICATION VERIFICATION")
    print("-" * 90)
    print(
        f"Application rows verified : {len(application_rows):>8,}"
    )
    print(
        f"Master matches             : {len(application_rows):>8,}"
    )
    print(
        f"Classification mismatches  : {0:>8,}"
    )
    print()
    print("VERIFICATION PASSED.")
# ============================================================================
# MAIN
# ============================================================================


def main():
    parser = argparse.ArgumentParser(
        description="Synchronize RasaBavarchi ingredients from master database."
    )

    parser.add_argument(
        "--apply",
        action="store_true",
        help="Apply changes to the RasaBavarchi database.",
    )

    args = parser.parse_args()

    mode = "APPLY" if args.apply else "DRY RUN"

    print("=" * 90)
    print("RasaBavarchi - MASTER INGREDIENT SYNCHRONIZATION")
    print("=" * 90)
    print()
    print(f"MODE: {mode}")

    if args.apply:
        print("DATABASE WILL BE MODIFIED.")
    else:
        print("DATABASE WILL NOT BE MODIFIED.")

    start = time.perf_counter()

    master_engine = None
    db = None

    try:
        # ---------------------------------------------------------------
        # Load master
        # ---------------------------------------------------------------

        master_engine = create_master_engine()

        master = load_master_ingredients(master_engine)

        # ---------------------------------------------------------------
        # Load application DB
        # ---------------------------------------------------------------

        print()
        print("=" * 90)
        print("LOADING RASABAVARCHI INGREDIENT DATABASE")
        print("=" * 90)

        db = SessionLocal()

        application_rows = load_application_ingredients(db)

        print(
            f"Application ingredient rows: "
            f"{len(application_rows):,}"
        )

        # ---------------------------------------------------------------
        # Counts before synchronization
        # ---------------------------------------------------------------

        print_current_counts(db)

        # ---------------------------------------------------------------
        # Analyze
        # ---------------------------------------------------------------

        print()
        print("=" * 90)
        print("MATCHING MASTER -> APPLICATION")
        print("=" * 90)

        match_start = time.perf_counter()

        matched, unmatched, changes = analyze_matches(
            application_rows,
            master,
        )

        match_time = time.perf_counter() - match_start

        print(f"Matched ingredients:   {len(matched):,}")
        print(f"Unmatched ingredients: {len(unmatched):,}")
        print(f"Classification changes: {len(changes):,}")
        print(f"Match time: {match_time:.3f} seconds")

        print_unmatched(unmatched)
        print_changes(changes)

        # ---------------------------------------------------------------
        # Safety check
        # ---------------------------------------------------------------

        if unmatched:
            print()
            print("=" * 90)
            print("SAFETY CHECK FAILED")
            print("=" * 90)
            print()
            print(
                "The master database does not contain every application "
                "ingredient."
            )
            print()
            print(
                "NO CHANGES WILL BE APPLIED."
            )
            print()
            print(
                "Add the missing ingredients to the master database first."
            )

            db.rollback()
            return 1

        # ---------------------------------------------------------------
        # Dry run
        # ---------------------------------------------------------------

        if not args.apply:
            print()
            print("=" * 90)
            print("DRY RUN COMPLETE")
            print("=" * 90)
            print()
            print("DATABASE WAS NOT MODIFIED.")
            print()
            print(
                "To apply the synchronization:"
            )
            print()
            print(
                "python scripts\\sync_ingredient_master.py --apply"
            )

            db.rollback()
            return 0

        # ---------------------------------------------------------------
        # Apply
        # ---------------------------------------------------------------

        updated = apply_changes(db, changes)

        print()
        print(f"Rows to update: {len(changes):,}")

        if updated != len(changes):
            raise RuntimeError(
                f"Update count mismatch. "
                f"Expected {len(changes):,}, updated {updated:,}."
            )

        # ---------------------------------------------------------------
        # Commit
        # ---------------------------------------------------------------

        print()
        print("Committing transaction...")

        db.commit()

        print()
        print("=" * 90)
        print("MASTER INGREDIENT SYNCHRONIZATION COMMITTED")
        print("=" * 90)

        # ---------------------------------------------------------------
        # Verify
        # ---------------------------------------------------------------

        verify_counts(
            db,
            master,
            application_rows,
        )

        elapsed = time.perf_counter() - start

        print()
        print("=" * 90)
        print("SYNCHRONIZATION COMPLETE")
        print("=" * 90)
        print(f"Total execution time: {elapsed:.3f} seconds")

        return 0

    except Exception:
        if db is not None:
            db.rollback()

        print()
        print("=" * 90)
        print("SYNCHRONIZATION FAILED")
        print("=" * 90)
        print()
        print(
            "Transaction was rolled back."
        )

        raise

    finally:
        if db is not None:
            db.close()

        if master_engine is not None:
            master_engine.dispose()


if __name__ == "__main__":
    raise SystemExit(main())
