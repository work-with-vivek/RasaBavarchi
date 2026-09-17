"""
RasaBavarchi - Master Ingredient Classification Matcher

Purpose:
    Compare the external/master ingredient classification CSV
    against the RasaBavarchi ingredients table.

IMPORTANT:
    READ-ONLY.
    This script NEVER modifies the database.
"""

from pathlib import Path
import csv
import sys

# Add backend root to Python path
BACKEND_ROOT = Path(__file__).resolve().parent.parent

if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from sqlalchemy import text
from app.dependencies.database import SessionLocal


CSV_PATH = (
    Path(__file__).resolve().parent.parent
    / "data"
    / "ingredients_master.csv"
)


def normalize_name(name: str) -> str:
    """
    Normalize ingredient names for comparison.

    Current normalization:
        - strip leading/trailing whitespace
        - lowercase
    """
    return name.strip().lower()


def load_master_csv():
    """Load the master ingredient classification CSV."""

    if not CSV_PATH.exists():
        raise FileNotFoundError(
            f"Master CSV not found:\n{CSV_PATH}"
        )

    master = {}

    with CSV_PATH.open(
        "r",
        encoding="utf-8-sig",
        newline="",
    ) as file:

        reader = csv.DictReader(file)

        required_columns = {
            "name",
            "dietary_type",
        }

        if not required_columns.issubset(
            set(reader.fieldnames or [])
        ):
            raise RuntimeError(
                "CSV must contain columns: name,dietary_type"
            )

        for row_number, row in enumerate(reader, start=2):

            name = (row["name"] or "").strip()
            dietary_type = (
                row["dietary_type"] or ""
            ).strip()

            if not name:
                raise RuntimeError(
                    f"Empty ingredient name at CSV row {row_number}"
                )

            if dietary_type not in {
                "Vegan",
                "Vegetarian",
                "Non-Vegetarian",
            }:
                raise RuntimeError(
                    f"Invalid dietary_type at CSV row "
                    f"{row_number}: {dietary_type!r}"
                )

            normalized = normalize_name(name)

            if normalized in master:
                raise RuntimeError(
                    f"Duplicate normalized ingredient in CSV: "
                    f"{name!r}"
                )

            master[normalized] = {
                "name": name,
                "dietary_type": dietary_type,
            }

    return master


def load_rasabavarchi_ingredients(db):
    """Load all RasaBavarchi ingredients."""

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
    ).fetchall()

    ingredients = {}

    for row in rows:

        normalized = normalize_name(row.name)

        if normalized in ingredients:
            raise RuntimeError(
                "Duplicate normalized ingredient in "
                f"RasaBavarchi database: {row.name!r}"
            )

        ingredients[normalized] = {
            "id": row.id,
            "name": row.name,
            "food_type": row.food_type,
        }

    return ingredients


def main():

    print("=" * 100)
    print("RasaBavarchi - MASTER INGREDIENT MATCH CHECK")
    print("=" * 100)
    print()
    print("READ-ONLY")
    print("NO DATABASE CHANGES WILL BE MADE.")
    print()

    print(f"Master CSV: {CSV_PATH}")
    print()

    master = load_master_csv()

    print(
        f"MASTER INGREDIENTS: {len(master):,}"
    )

    db = SessionLocal()

    try:

        rasabavarchi = load_rasabavarchi_ingredients(
            db
        )

        print(
            f"RASABAVARCHI INGREDIENTS: "
            f"{len(rasabavarchi):,}"
        )

        print()
        print("=" * 100)
        print("MATCH ANALYSIS")
        print("=" * 100)

        matched = []
        missing_in_rasabavarchi = []
        missing_in_master = []
        classification_differences = []

        # Master -> RasaBavarchi
        for normalized, master_row in master.items():

            rb = rasabavarchi.get(normalized)

            if rb is None:

                missing_in_rasabavarchi.append(
                    master_row
                )

                continue

            matched.append(
                (
                    master_row,
                    rb,
                )
            )

            proposed_type = {
                "Vegan": "VEGAN",
                "Vegetarian": "VEGETARIAN",
                "Non-Vegetarian": "NON_VEGETARIAN",
            }[master_row["dietary_type"]]

            if rb["food_type"] != proposed_type:

                classification_differences.append(
                    {
                        "name": rb["name"],
                        "current": rb["food_type"],
                        "master": proposed_type,
                    }
                )

        # RasaBavarchi -> Master
        for normalized, rb_row in rasabavarchi.items():

            if normalized not in master:

                missing_in_master.append(
                    rb_row
                )

        print()
        print(
            f"EXACT NORMALIZED MATCHES: "
            f"{len(matched):,}"
        )

        print(
            f"MASTER ONLY: "
            f"{len(missing_in_rasabavarchi):,}"
        )

        print(
            f"RASABAVARCHI ONLY: "
            f"{len(missing_in_master):,}"
        )

        print(
            f"CLASSIFICATION DIFFERENCES: "
            f"{len(classification_differences):,}"
        )

        print()
        print("=" * 100)
        print("MATCH RATE")
        print("=" * 100)

        if master:

            match_rate = (
                len(matched)
                / len(master)
                * 100
            )

            print(
                f"{match_rate:.2f}% of master ingredients "
                f"match RasaBavarchi."
            )

        if rasabavarchi:

            reverse_rate = (
                len(matched)
                / len(rasabavarchi)
                * 100
            )

            print(
                f"{reverse_rate:.2f}% of RasaBavarchi "
                f"ingredients exist in master."
            )

        # Classification summary
        print()
        print("=" * 100)
        print("MASTER CLASSIFICATION DISTRIBUTION")
        print("=" * 100)

        distribution = {
            "Vegan": 0,
            "Vegetarian": 0,
            "Non-Vegetarian": 0,
        }

        for row in master.values():
            distribution[row["dietary_type"]] += 1

        print(
            f"Vegan              : "
            f"{distribution['Vegan']:>8,}"
        )

        print(
            f"Vegetarian         : "
            f"{distribution['Vegetarian']:>8,}"
        )

        print(
            f"Non-Vegetarian     : "
            f"{distribution['Non-Vegetarian']:>8,}"
        )

        print(
            f"TOTAL              : "
            f"{len(master):>8,}"
        )

        # Show differences
        if classification_differences:

            print()
            print("=" * 100)
            print("CURRENT VS MASTER DIFFERENCES")
            print("=" * 100)

            for item in classification_differences[
                :100
            ]:

                print(
                    f"{item['name']:<55}"
                    f"CURRENT={item['current']:<18}"
                    f"MASTER={item['master']}"
                )

            if len(classification_differences) > 100:

                print()
                print(
                    f"... and "
                    f"{len(classification_differences) - 100:,} "
                    f"more differences."
                )

        # Missing from RasaBavarchi
        if missing_in_rasabavarchi:

            print()
            print("=" * 100)
            print("MASTER INGREDIENTS NOT FOUND IN RASABAVARCHI")
            print("=" * 100)

            for row in missing_in_rasabavarchi[:100]:

                print(
                    f"{row['name']:<60}"
                    f"-> {row['dietary_type']}"
                )

        # Missing from master
        if missing_in_master:

            print()
            print("=" * 100)
            print("RASABAVARCHI INGREDIENTS NOT FOUND IN MASTER")
            print("=" * 100)

            for row in missing_in_master[:100]:

                print(
                    f"{row['name']:<60}"
                    f"-> CURRENT {row['food_type']}"
                )

        print()
        print("=" * 100)
        print("SAFETY")
        print("=" * 100)
        print("READ-ONLY CHECK COMPLETE.")
        print("DATABASE WAS NOT MODIFIED.")
        print("=" * 100)

    finally:

        db.close()


if __name__ == "__main__":
    main()