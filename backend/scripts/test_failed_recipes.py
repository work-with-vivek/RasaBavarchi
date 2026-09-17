from __future__ import annotations

import sys
from pathlib import Path


# =============================================================
# ENSURE BACKEND ROOT IS IMPORTABLE
# =============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))


# =============================================================
# PROVIDERS
# =============================================================

from scripts.image_providers import (
    ImageProviderManager,
    OpenverseProvider,
    TheMealDBProvider,
)


# =============================================================
# MAIN
# =============================================================

def main() -> None:
    """
    Test recipes that previously failed image import.
    """

    manager = ImageProviderManager(
        [
            OpenverseProvider(),
            TheMealDBProvider(),
        ]
    )

    titles = [
        "bird s lemonade stand parfaits",
        "watercress raita",
        "buttermilk cobbler",
        "red fruit soup norway",
        "pizza possibilites",
        "three layer orange jello salad",
        "grandma s coleslaw 2",
        "ginger yogurt",
        "herbed carrots",
        "chicken paprikas",
    ]

    for title in titles:

        print()
        print("=" * 70)
        print(title)
        print("=" * 70)

        try:

            result = manager.search(
                title
            )

            print(
                "RESULT:",
                result,
            )

        except Exception as exc:

            print(
                "ERROR:",
                exc,
            )


# =============================================================
# ENTRY POINT
# =============================================================

if __name__ == "__main__":
    main()