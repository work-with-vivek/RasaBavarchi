"""
RasaBavarchi - Ingredient Master Importer

Purpose:
    Import the validated ingredient classification master CSV
    into the RasaBavarchi database.

Source:
    data/ingredients_master.csv

CSV format:
    name,dietary_type

Supported dietary types:
    Vegan
    Vegetarian
    Non-Vegetarian

Database classifications:
    VEGAN
    VEGETARIAN
    NON_VEGETARIAN
    UNKNOWN

IMPORTANT SAFETY RULES:
    - Dry run by default.
    - --apply is required to modify the database.
    - Exact normalized-name matching only.
    - No fuzzy matching.
    - No ingredient deletion.
    - No ingredient creation.
    - No classification -> UNKNOWN changes.
    - Existing classifications may be changed because the master
      database is now the authoritative classification source.
    - Every imported classification gets an audit record in
      ingredient_classifications.
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path
from collections import Counter

from sqlalchemy import text


# ============================================================================
# PYTHON PATH
# ============================================================================

BACKEND_ROOT = Path(__file__).resolve().parent.parent

if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))


from app.dependencies.database import SessionLocal


# ============================================================================
# CONFIGURATION
# ============================================================================

CSV_PATH = (
    BACKEND_ROOT
    / "data"
    / "ingredients_master.csv"
)

SOURCE_NAME = "RasaBavarchi Master Ingredient Database"
METHOD_NAME = "MASTER_IMPORT"
CONFIDENCE = 1.0000


DIETARY_TO_FOOD_TYPE = {
    "Vegan": "VEGAN",
    "Vegetarian": "VEGETARIAN",
    "Non-Vegetarian": "NON_VEGETARIAN",
}


VALID_FOOD_TYPES = {
    "VEGAN",
    "VEGETARIAN",
    "NON_VEGETARIAN",
}


# ============================================================================
# HELPERS
# ============================================================================

def normalize_name(name: str) -> str:
    """
    Normalize an ingredient name for exact matching.

    Current normalization intentionally remains conservative:
        - strip whitespace
        - lowercase

    We do NOT remove punctuation or alter wording because the master
    database was generated from the same ingredient list.
    """

    return name.strip().lower()


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Import the RasaBavarchi ingredient classification master."
    )

    parser.add_argument(
        "--apply",
        action="store_true",
        help="Apply changes to the database.",
    )

    return parser.parse_args()


# ============================================================================
# CSV
# ============================================================================

def load_master_csv() -> dict[str, dict]:
    """
    Load and validate the master CSV.

    Returns:
        {
            normalized_name: {
                "name": original_name,
                "dietary_type": dietary_type,
                "food_type": mapped_food_type,
            }
        }
    """

    if not CSV_PATH.exists():
        raise FileNotFoundError(
            f"Master CSV not found:\n{CSV_PATH}"
        )

    master: dict[str, dict] = {}

    with CSV_PATH.open(
        "r",
        encoding="utf-8-sig",
        newline="",
    ) as file:

        reader = csv.DictReader(file)

        expected_columns = {
            "name",
            "dietary_type",
        }

        actual_columns = set(
            reader.fieldnames or []
        )

        if actual_columns != expected_columns:
            raise RuntimeError(
                "Invalid CSV columns.\n"
                f"Expected: {sorted(expected_columns)}\n"
                f"Found:    {sorted(actual_columns)}"
            )

        for row_number, row in enumerate(
            reader,
            start=2,
        ):

            name = (
                row.get("name") or ""
            ).strip()

            dietary_type = (
                row.get("dietary_type") or ""
            ).strip()

            if not name:
                raise RuntimeError(
                    f"Empty ingredient name at CSV row "
                    f"{row_number}."
                )

            if dietary_type not in DIETARY_TO_FOOD_TYPE:
                raise RuntimeError(
                    f"Invalid dietary_type at CSV row "
                    f"{row_number}: {dietary_type!r}"
                )

            normalized = normalize_name(name)

            if normalized in master:
                previous = master[normalized]["name"]

                raise RuntimeError(
                    "Duplicate normalized ingredient "
                    f"in master CSV:\n"
                    f"  First:  {previous!r}\n"
                    f"  Second: {name!r}\n"
                    f"  Row:    {row_number}"
                )

            food_type = DIETARY_TO_FOOD_TYPE[
                dietary_type
            ]

            master[normalized] = {
                "name": name,
                "dietary_type": dietary_type,
                "food_type": food_type,
            }

    return master


# ============================================================================
# DATABASE
# ============================================================================

def load_rasabavarchi_ingredients(db):
    """
    Load every RasaBavarchi ingredient.

    Returns:
        normalized_name -> database row information
    """

    rows = db.execute(
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
    ).mappings().all()

    ingredients: dict[str, dict] = {}

    for row in rows:

        normalized = normalize_name(
            row["name"]
        )

        if normalized in ingredients:
            raise RuntimeError(
                "Duplicate normalized ingredient "
                "in RasaBavarchi database:\n"
                f"  {row['name']!r}"
            )

        ingredients[normalized] = {
            "id": row["id"],
            "name": row["name"],
            "food_type": row["food_type"],
        }

    return ingredients


# ============================================================================
# CLASSIFICATION TABLE
# ============================================================================

def load_existing_classifications(db):
    """
    Load existing ingredient_classifications records.

    Returns:
        ingredient_id -> classification record
    """

    rows = db.execute(
        text(
            """
            SELECT
                id,
                ingredient_id,
                food_type,
                confidence,
                method,
                reason,
                source,
                reviewed
            FROM ingredient_classifications
            """
        )
    ).mappings().all()

    return {
        row["ingredient_id"]: dict(row)
        for row in rows
    }


# ============================================================================
# ANALYSIS
# ============================================================================

def analyze(master, ingredients):
    """
    Compare master classifications against the current database.
    """

    matched = []
    missing = []
    already_correct = []
    changes = []

    for normalized, master_row in master.items():

        ingredient = ingredients.get(
            normalized
        )

        if ingredient is None:
            missing.append(master_row)
            continue

        item = {
            "id": ingredient["id"],
            "name": ingredient["name"],
            "current": ingredient["food_type"],
            "new": master_row["food_type"],
            "dietary_type": master_row["dietary_type"],
        }

        matched.append(item)

        if ingredient["food_type"] == master_row["food_type"]:
            already_correct.append(item)

        else:
            changes.append(item)

    return {
        "matched": matched,
        "missing": missing,
        "already_correct": already_correct,
        "changes": changes,
    }


# ============================================================================
# DISPLAY
# ============================================================================

def get_counts(db):
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
    ).mappings().one()

    return {
        "VEGAN": row["vegan"],
        "VEGETARIAN": row["vegetarian"],
        "NON_VEGETARIAN": row["non_vegetarian"],
        "UNKNOWN": row["unknown"],
        "TOTAL": row["total"],
    }


def print_counts(title, counts):
    print()
    print("=" * 90)
    print(title)
    print("=" * 90)

    print(
        f"{'VEGAN':<25}: {counts['VEGAN']:>10,}"
    )

    print(
        f"{'VEGETARIAN':<25}: {counts['VEGETARIAN']:>10,}"
    )

    print(
        f"{'NON_VEGETARIAN':<25}: "
        f"{counts['NON_VEGETARIAN']:>10,}"
    )

    print(
        f"{'UNKNOWN':<25}: {counts['UNKNOWN']:>10,}"
    )

    print("-" * 90)

    print(
        f"{'TOTAL':<25}: {counts['TOTAL']:>10,}"
    )


def calculate_expected_counts(
    current_counts,
    changes,
):
    expected = dict(current_counts)

    for item in changes:

        old_type = item["current"]
        new_type = item["new"]

        if old_type in VALID_FOOD_TYPES:
            expected[old_type] -= 1

        elif old_type == "UNKNOWN":
            expected["UNKNOWN"] -= 1

        else:
            raise RuntimeError(
                f"Unexpected current food_type: "
                f"{old_type!r}"
            )

        expected[new_type] += 1

    return expected


def print_change_summary(changes):
    summary = Counter(
        item["new"]
        for item in changes
    )

    print()
    print("=" * 90)
    print("CHANGE SUMMARY")
    print("=" * 90)

    print(
        f"{'TO VEGAN':<25}: "
        f"{summary['VEGAN']:>10,}"
    )

    print(
        f"{'TO VEGETARIAN':<25}: "
        f"{summary['VEGETARIAN']:>10,}"
    )

    print(
        f"{'TO NON_VEGETARIAN':<25}: "
        f"{summary['NON_VEGETARIAN']:>10,}"
    )


def print_changes(changes, limit=100):
    if not changes:
        print()
        print("No classification changes required.")
        return

    print()
    print("=" * 90)
    print("PROPOSED CHANGES")
    print("=" * 90)

    for item in changes[:limit]:

        print(
            f"{item['name']:<60}"
            f"{item['current']:<18}"
            f"-> {item['new']}"
        )

    if len(changes) > limit:

        print()
        print(
            f"... and "
            f"{len(changes) - limit:,} "
            f"additional changes."
        )


# ============================================================================
# APPLY
# ============================================================================

def apply_changes(
    db,
    changes,
    existing_classifications,
):
    """
    Apply master classifications.

    Two things are synchronized:

        1. ingredients.food_type
        2. ingredient_classifications

    Existing classification records are updated rather than duplicated.
    """

    ingredient_updates = 0
    classification_inserts = 0
    classification_updates = 0

    for item in changes:

        ingredient_id = item["id"]
        new_type = item["new"]

        # ------------------------------------------------------------
        # Update operational ingredient classification
        # ------------------------------------------------------------

        result = db.execute(
            text(
                """
                UPDATE ingredients

                SET
                    food_type = :food_type,
                    updated_at = CURRENT_TIMESTAMP

                WHERE id = :ingredient_id

                  AND food_type IS DISTINCT FROM :food_type
                """
            ),
            {
                "ingredient_id": ingredient_id,
                "food_type": new_type,
            },
        )

        ingredient_updates += result.rowcount

        # ------------------------------------------------------------
        # Upsert classification knowledge record
        # ------------------------------------------------------------

        existing = existing_classifications.get(
            ingredient_id
        )

        if existing is None:

            db.execute(
                text(
                    """
                    INSERT INTO ingredient_classifications (
                        ingredient_id,
                        food_type,
                        confidence,
                        method,
                        reason,
                        source,
                        reviewed,
                        created_at,
                        updated_at
                    )

                    VALUES (
                        :ingredient_id,
                        :food_type,
                        :confidence,
                        :method,
                        :reason,
                        :source,
                        :reviewed,
                        CURRENT_TIMESTAMP,
                        CURRENT_TIMESTAMP
                    )
                    """
                ),
                {
                    "ingredient_id": ingredient_id,
                    "food_type": new_type,
                    "confidence": CONFIDENCE,
                    "method": METHOD_NAME,
                    "reason": (
                        "Classification imported from the "
                        "validated RasaBavarchi ingredient "
                        "master database."
                    ),
                    "source": SOURCE_NAME,
                    "reviewed": True,
                },
            )

            classification_inserts += 1

        else:

            db.execute(
                text(
                    """
                    UPDATE ingredient_classifications

                    SET
                        food_type = :food_type,
                        confidence = :confidence,
                        method = :method,
                        reason = :reason,
                        source = :source,
                        reviewed = :reviewed,
                        updated_at = CURRENT_TIMESTAMP

                    WHERE ingredient_id = :ingredient_id
                    """
                ),
                {
                    "ingredient_id": ingredient_id,
                    "food_type": new_type,
                    "confidence": CONFIDENCE,
                    "method": METHOD_NAME,
                    "reason": (
                        "Classification imported from the "
                        "validated RasaBavarchi ingredient "
                        "master database."
                    ),
                    "source": SOURCE_NAME,
                    "reviewed": True,
                },
            )

            classification_updates += 1

    return {
        "ingredient_updates": ingredient_updates,
        "classification_inserts": classification_inserts,
        "classification_updates": classification_updates,
    }


# ============================================================================
# VERIFICATION
# ============================================================================

def verify_database(
    db,
    expected_counts,
):
    actual_counts = get_counts(db)

    for key in (
        "VEGAN",
        "VEGETARIAN",
        "NON_VEGETARIAN",
        "UNKNOWN",
        "TOTAL",
    ):

        if actual_counts[key] != expected_counts[key]:

            raise RuntimeError(
                f"Verification failed for {key}.\n"
                f"Expected: {expected_counts[key]:,}\n"
                f"Actual:   {actual_counts[key]:,}"
            )

    return actual_counts


# ============================================================================
# MAIN
# ============================================================================

def main():

    args = parse_arguments()

    apply_mode = args.apply

    print("=" * 90)
    print("RasaBavarchi - INGREDIENT MASTER IMPORT")
    print("=" * 90)

    print()

    if apply_mode:

        print("MODE: APPLY")
        print("DATABASE WILL BE MODIFIED.")

    else:

        print("MODE: DRY RUN")
        print("DATABASE WILL NOT BE MODIFIED.")

    print()

    print(
        f"MASTER CSV: {CSV_PATH}"
    )

    # ------------------------------------------------------------------------
    # Load master
    # ------------------------------------------------------------------------

    print()
    print("Loading master classification...")

    master = load_master_csv()

    print(
        f"MASTER INGREDIENTS: {len(master):,}"
    )

    # ------------------------------------------------------------------------
    # Database
    # ------------------------------------------------------------------------

    db = SessionLocal()

    try:

        ingredients = load_rasabavarchi_ingredients(
            db
        )

        existing_classifications = (
            load_existing_classifications(db)
        )

        print(
            f"RASABAVARCHI INGREDIENTS: "
            f"{len(ingredients):,}"
        )

        print(
            f"EXISTING CLASSIFICATION RECORDS: "
            f"{len(existing_classifications):,}"
        )

        # --------------------------------------------------------------------
        # Current counts
        # --------------------------------------------------------------------

        current_counts = get_counts(db)

        print_counts(
            "CURRENT DATABASE",
            current_counts,
        )

        # --------------------------------------------------------------------
        # Analyze
        # --------------------------------------------------------------------

        analysis = analyze(
            master,
            ingredients,
        )

        matched = analysis["matched"]
        missing = analysis["missing"]
        already_correct = analysis[
            "already_correct"
        ]
        changes = analysis["changes"]

        print()
        print("=" * 90)
        print("MASTER MATCH ANALYSIS")
        print("=" * 90)

        print(
            f"{'MASTER INGREDIENTS':<35}: "
            f"{len(master):>10,}"
        )

        print(
            f"{'EXACT MATCHES':<35}: "
            f"{len(matched):>10,}"
        )

        print(
            f"{'ALREADY CORRECT':<35}: "
            f"{len(already_correct):>10,}"
        )

        print(
            f"{'ROWS TO CHANGE':<35}: "
            f"{len(changes):>10,}"
        )

        print(
            f"{'UNMATCHED MASTER INGREDIENTS':<35}: "
            f"{len(missing):>10,}"
        )

        # --------------------------------------------------------------------
        # HARD SAFETY CHECK
        # --------------------------------------------------------------------

        if missing:

            print()
            print("=" * 90)
            print("SAFETY CHECK FAILED")
            print("=" * 90)

            print(
                "Some master ingredients do not exist "
                "in RasaBavarchi."
            )

            print(
                "DATABASE WILL NOT BE MODIFIED."
            )

            print()

            for item in missing[:100]:

                print(
                    f"{item['name']:<60}"
                    f"-> {item['dietary_type']}"
                )

            if len(missing) > 100:

                print(
                    f"... and "
                    f"{len(missing) - 100:,} more."
                )

            raise RuntimeError(
                "Master import aborted because "
                "unmatched ingredients were found."
            )

        # --------------------------------------------------------------------
        # Expected counts
        # --------------------------------------------------------------------

        expected_counts = (
            calculate_expected_counts(
                current_counts,
                changes,
            )
        )

        print_counts(
            "EXPECTED DATABASE AFTER IMPORT",
            expected_counts,
        )

        # --------------------------------------------------------------------
        # Changes
        # --------------------------------------------------------------------

        print_change_summary(changes)

        print_changes(changes)

        # --------------------------------------------------------------------
        # Safety guarantees
        # --------------------------------------------------------------------

        print()
        print("=" * 90)
        print("SAFETY CHECKS")
        print("=" * 90)

        print(
            "Exact normalized matching: ENABLED"
        )

        print(
            "Fuzzy matching: DISABLED"
        )

        print(
            "Ingredient creation: DISABLED"
        )

        print(
            "Ingredient deletion: DISABLED"
        )

        print(
            "Unmatched ingredients: 0 REQUIRED"
        )

        print(
            "Classification -> UNKNOWN: DISABLED"
        )

        print(
            "Master classification is authoritative: ENABLED"
        )

        # --------------------------------------------------------------------
        # Dry run
        # --------------------------------------------------------------------

        if not apply_mode:

            print()
            print("=" * 90)
            print("DRY RUN COMPLETE")
            print("=" * 90)

            print(
                "DATABASE WAS NOT MODIFIED."
            )

            print()
            print(
                "If the proposed changes are correct, "
                "apply with:"
            )

            print()
            print(
                "python scripts\\import_ingredient_master.py --apply"
            )

            print("=" * 90)

            return

        # --------------------------------------------------------------------
        # Apply
        # --------------------------------------------------------------------

        print()
        print("=" * 90)
        print("APPLYING MASTER CLASSIFICATION")
        print("=" * 90)

        if not changes:

            print(
                "Nothing to update."
            )

            db.rollback()
            return

        result = apply_changes(
            db,
            changes,
            existing_classifications,
        )

        print()
        print(
            f"Ingredient rows updated: "
            f"{result['ingredient_updates']:,}"
        )

        print(
            f"Classification records inserted: "
            f"{result['classification_inserts']:,}"
        )

        print(
            f"Classification records updated: "
            f"{result['classification_updates']:,}"
        )

        # --------------------------------------------------------------------
        # Verify BEFORE commit
        # --------------------------------------------------------------------

        print()
        print(
            "Verifying transaction before commit..."
        )

        actual_counts = verify_database(
            db,
            expected_counts,
        )

        print(
            "COUNT VERIFICATION PASSED."
        )

        # --------------------------------------------------------------------
        # Commit
        # --------------------------------------------------------------------

        print()
        print(
            "Committing transaction..."
        )

        db.commit()

        print()
        print("=" * 90)
        print("MASTER INGREDIENT IMPORT COMMITTED SUCCESSFULLY")
        print("=" * 90)

        print_counts(
            "FINAL DATABASE",
            actual_counts,
        )

        print()
        print("=" * 90)
        print("NEXT STEP")
        print("=" * 90)

        print(
            "Recalculate recipe classifications with:"
        )

        print()
        print(
            "python scripts\\classify_recipes_only.py --apply"
        )

        print("=" * 90)

    except Exception:

        db.rollback()

        print()
        print("=" * 90)
        print("IMPORT FAILED")
        print("=" * 90)

        print(
            "Transaction rolled back."
        )

        print(
            "DATABASE WAS NOT MODIFIED."
        )

        raise

    finally:

        db.close()


if __name__ == "__main__":
    main()