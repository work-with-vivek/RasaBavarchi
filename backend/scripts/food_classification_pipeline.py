"""
RasaBavarchi - Food Classification Pipeline

Pipeline:

    MASTER DATABASE
          |
          v
    sync_ingredient_master.py
          |
          v
    RasaBavarchi ingredients
          |
          v
    classify_recipes_only.py
          |
          v
    RasaBavarchi recipes
          |
          v
    validate_food_classification.py

Default:
    DRY RUN

Apply:
    python scripts\food_classification_pipeline.py --apply

IMPORTANT:
This file is an ORCHESTRATOR.

It intentionally does NOT duplicate:
- ingredient synchronization logic
- recipe classification SQL
- validation SQL

Those responsibilities remain inside their dedicated scripts.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import time
from pathlib import Path


# ============================================================================
# PATHS
# ============================================================================

BACKEND_DIR = Path(__file__).resolve().parent.parent
SCRIPTS_DIR = BACKEND_DIR / "scripts"


SYNC_SCRIPT = SCRIPTS_DIR / "sync_ingredient_master.py"
RECIPE_SCRIPT = SCRIPTS_DIR / "classify_recipes_only.py"
VALIDATION_SCRIPT = SCRIPTS_DIR / "validate_food_classification.py"


# ============================================================================
# COLORS
# ============================================================================

# Keep output readable even when ANSI colors are unsupported.
USE_COLOR = sys.stdout.isatty()


def green(text: str) -> str:
    if not USE_COLOR:
        return text

    return f"\033[92m{text}\033[0m"


def red(text: str) -> str:
    if not USE_COLOR:
        return text

    return f"\033[91m{text}\033[0m"


def yellow(text: str) -> str:
    if not USE_COLOR:
        return text

    return f"\033[93m{text}\033[0m"


def cyan(text: str) -> str:
    if not USE_COLOR:
        return text

    return f"\033[96m{text}\033[0m"


# ============================================================================
# PRINTING
# ============================================================================


def print_header(title: str) -> None:
    print()
    print("=" * 90)
    print(title)
    print("=" * 90)


def print_step(number: int, title: str) -> None:
    print()
    print("=" * 90)
    print(f"STEP {number}: {title}")
    print("=" * 90)


# ============================================================================
# SCRIPT EXECUTION
# ============================================================================


def run_script(
    script: Path,
    args: list[str] | None = None,
) -> int:
    """
    Execute one pipeline component.

    Returns:
        Process exit code.
    """

    if args is None:
        args = []

    command = [
        sys.executable,
        str(script),
        *args,
    ]

    print()
    print(cyan("COMMAND:"))
    print(" ".join(f'"{part}"' if " " in part else part for part in command))
    print()

    start = time.perf_counter()

    result = subprocess.run(
        command,
        cwd=BACKEND_DIR,
        check=False,
    )

    elapsed = time.perf_counter() - start

    print()
    print("-" * 90)
    print(
        f"Finished: {script.name} "
        f"(exit code={result.returncode}, time={elapsed:.3f}s)"
    )
    print("-" * 90)

    return result.returncode


# ============================================================================
# VALIDATE PIPELINE FILES
# ============================================================================


def check_required_files() -> None:
    """
    Make sure all pipeline components exist before starting.
    """

    print_header("CHECKING PIPELINE COMPONENTS")

    files = [
        ("Ingredient synchronization", SYNC_SCRIPT),
        ("Recipe classification", RECIPE_SCRIPT),
        ("Food classification validation", VALIDATION_SCRIPT),
    ]

    missing = []

    for description, path in files:
        exists = path.is_file()

        status = green("FOUND") if exists else red("MISSING")

        print(
            f"{description:<35} {status}  {path}"
        )

        if not exists:
            missing.append(path)

    if missing:
        print()
        print(red("Pipeline cannot start."))
        print()
        print("Missing files:")

        for path in missing:
            print(f"  - {path}")

        raise SystemExit(1)

    print()
    print(green("All pipeline components found."))


# ============================================================================
# MAIN
# ============================================================================


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Run the complete RasaBavarchi food classification pipeline."
        )
    )

    parser.add_argument(
        "--apply",
        action="store_true",
        help="Apply ingredient and recipe classification changes.",
    )

    args = parser.parse_args()

    mode = "APPLY" if args.apply else "DRY RUN"

    start_total = time.perf_counter()

    print_header(
        "RasaBavarchi - FOOD CLASSIFICATION PIPELINE"
    )

    print()
    print(f"MODE: {mode}")

    if args.apply:
        print(
            yellow(
                "DATABASES MAY BE MODIFIED BY THE PIPELINE."
            )
        )
    else:
        print(
            green(
                "DRY RUN - DATABASE WILL NOT BE MODIFIED."
            )
        )

    print()
    print("Pipeline:")
    print("  1. Master ingredient synchronization")
    print("  2. Recipe classification")
    print("  3. Food classification validation")

    # ========================================================================
    # CHECK FILES
    # ========================================================================

    check_required_files()

    # ========================================================================
    # STEP 1
    # ========================================================================

    print_step(
        1,
        "MASTER INGREDIENT SYNCHRONIZATION",
    )

    sync_args = ["--apply"] if args.apply else []

    exit_code = run_script(
        SYNC_SCRIPT,
        sync_args,
    )

    if exit_code != 0:
        print()
        print_header("PIPELINE FAILED")

        print(
            red(
                "Ingredient synchronization failed."
            )
        )

        print()
        print(
            "Recipe classification was NOT started."
        )

        return exit_code

    print()
    print(
        green(
            "STEP 1 PASSED - MASTER INGREDIENT SYNCHRONIZATION"
        )
    )

    # ========================================================================
    # STEP 2
    # ========================================================================

    print_step(
        2,
        "RECIPE CLASSIFICATION",
    )

    recipe_args = ["--apply"] if args.apply else []

    exit_code = run_script(
        RECIPE_SCRIPT,
        recipe_args,
    )

    if exit_code != 0:
        print()
        print_header("PIPELINE FAILED")

        print(
            red(
                "Recipe classification failed."
            )
        )

        print()
        print(
            "Validation was NOT started."
        )

        return exit_code

    print()
    print(
        green(
            "STEP 2 PASSED - RECIPE CLASSIFICATION"
        )
    )

    # ========================================================================
    # STEP 3
    # ========================================================================

    print_step(
        3,
        "FOOD CLASSIFICATION VALIDATION",
    )

    # Validation is always read-only.
    exit_code = run_script(
        VALIDATION_SCRIPT,
    )

    if exit_code != 0:
        print()
        print_header("PIPELINE FAILED")

        print(
            red(
                "Food classification validation failed."
            )
        )

        print()
        print(
            "Review the validation output above."
        )

        return exit_code

    print()
    print(
        green(
            "STEP 3 PASSED - FOOD CLASSIFICATION VALIDATION"
        )
    )

    # ========================================================================
    # COMPLETE
    # ========================================================================

    total_time = time.perf_counter() - start_total

    print_header(
        "FOOD CLASSIFICATION PIPELINE COMPLETE"
    )

    print()
    print(
        green(
            "ALL PIPELINE STEPS PASSED."
        )
    )

    print()
    print(f"Mode          : {mode}")
    print(f"Total time    : {total_time:.3f} seconds")

    print()
    print("Pipeline completed successfully:")

    print()
    print("  MASTER DATABASE")
    print("        |")
    print("        v")
    print("  Ingredient synchronization")
    print("        |")
    print("        v")
    print("  RasaBavarchi ingredients")
    print("        |")
    print("        v")
    print("  Recipe classification")
    print("        |")
    print("        v")
    print("  RasaBavarchi recipes")
    print("        |")
    print("        v")
    print("  Final validation")
    print("        |")
    print("        v")
    print("      PASS")

    print()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())