from __future__ import annotations


# =============================================================
# RasaBavarchi - Ingredient Image Search Aliases
# =============================================================
#
# These aliases are used ONLY for image searching.
# They do not change the ingredient name stored in PostgreSQL.
#
# The canonical visual ingredient name remains the primary value.
# Aliases give Pexels/Wikimedia additional common search terms.
# =============================================================


IMAGE_SEARCH_ALIASES: dict[str, list[str]] = {

    # =========================================================
    # ALMOND
    # =========================================================

    "almonds": [
        "almonds",
        "almond nuts",
        "whole almonds",
    ],

    "almond meal": [
        "almond meal",
        "ground almonds",
        "almond flour",
    ],

    "almond powder": [
        "almond powder",
        "ground almonds",
        "almond flour",
    ],

    "almond paste": [
        "almond paste",
        "almond marzipan",
        "marzipan",
    ],

    "almond milk": [
        "almond milk",
        "almond drink",
    ],

    "almond oil": [
        "almond oil",
        "sweet almond oil",
    ],

    # =========================================================
    # AMCHUR / AMCHOOR
    # =========================================================

    "amchoor powder": [
        "amchoor powder",
        "amchur powder",
        "dried mango powder",
    ],

    "amchur": [
        "amchur",
        "amchoor",
        "dried mango powder",
    ],

    "amchur powder": [
        "amchur powder",
        "amchoor powder",
        "dried mango powder",
    ],

    # =========================================================
    # ANAHEIM CHILI
    # =========================================================

    "anaheim chili": [
        "anaheim chili",
        "anaheim chile",
        "anaheim pepper",
    ],

    "anaheim chilies": [
        "anaheim chili",
        "anaheim chile",
        "anaheim peppers",
    ],

    # =========================================================
    # ANCHO CHILI
    # =========================================================

    "ancho chili": [
        "ancho chili",
        "ancho chile",
        "dried ancho pepper",
    ],

    "ancho chilies": [
        "ancho chili",
        "ancho chile",
        "dried ancho peppers",
    ],

    "ancho chili puree": [
        "ancho chili puree",
        "ancho chile puree",
        "ancho pepper puree",
    ],

    # =========================================================
    # ALLSPICE
    # =========================================================

    "allspice berry": [
        "allspice berry",
        "allspice berries",
    ],

    "allspice berries": [
        "allspice berries",
        "allspice",
    ],

    # =========================================================
    # AMARANTH
    # =========================================================

    "amaranth": [
        "amaranth grain",
        "amaranth seeds",
    ],

    "amaranth grain": [
        "amaranth grain",
        "amaranth seeds",
    ],

    "amaranth flour": [
        "amaranth flour",
    ],

    # =========================================================
    # ACHIOTE / ANNATTO
    # =========================================================

    "achiote powder": [
        "achiote powder",
        "annatto powder",
        "annatto seed powder",
    ],

    "achiote paste": [
        "achiote paste",
        "annatto paste",
    ],

    "achiote paste cubes": [
        "achiote paste",
        "annatto paste",
    ],

    # =========================================================
    # ALOE
    # =========================================================

    "aloe juice": [
        "aloe vera juice",
        "aloe juice",
    ],

    "aloe vera gel": [
        "aloe vera gel",
        "aloe gel",
    ],

    # =========================================================
    # AMERICAN CHEESE
    # =========================================================

    "american cheese": [
        "american cheese",
        "american cheese slices",
    ],

    "american cheese spread": [
        "american cheese spread",
        "processed cheese spread",
    ],

    # =========================================================
    # ANEJO CHEESE
    # =========================================================

    "anejo cheese": [
        "anejo cheese",
        "anejo mexican cheese",
        "aged queso anejo",
    ],

    # =========================================================
    # COCONUT
    # =========================================================

    "angel flake coconut": [
        "angel flake coconut",
        "shredded coconut",
        "sweetened shredded coconut",
    ],

    # =========================================================
    # PASTA
    # =========================================================

    "angel hair pasta": [
        "angel hair pasta",
        "capellini",
        "angel hair spaghetti",
    ],

    "angel hair pasta with herbs mix": [
        "angel hair pasta",
        "herbed angel hair pasta",
        "angel hair pasta herbs",
    ],

    "alphabet pasta": [
        "alphabet pasta",
        "letter pasta",
    ],

    "alphabet pasta and vegetable soup": [
        "alphabet pasta soup",
        "alphabet vegetable soup",
    ],

    # =========================================================
    # ANGELICA
    # =========================================================

    "angelica leaf": [
        "angelica leaf",
        "angelica herb",
        "angelica leaves",
    ],

    "angelica leaves": [
        "angelica leaves",
        "angelica leaf",
        "angelica herb",
    ],

    # =========================================================
    # WORCESTERSHIRE
    # =========================================================

    "angostura sodium worcestershire sauce": [
        "worcestershire sauce",
        "low sodium worcestershire sauce",
        "angostura worcestershire sauce",
    ],

    # =========================================================
    # BEEF
    # =========================================================

    "angus steaks": [
        "angus steak",
        "angus beef",
        "beef steak",
    ],

    # =========================================================
    # ANISE
    # =========================================================

    "anise flavored liqueur": [
        "anise liqueur",
        "anise flavored liqueur",
        "anisette",
    ],

    "anise extract": [
        "anise extract",
        "anise flavor extract",
    ],

    "anise flavoring": [
        "anise flavoring",
        "anise extract",
        "anise flavor",
    ],

    # =========================================================
    # MANGO
    # =========================================================

    "alphonso mangoes": [
        "alphonso mango",
        "alphonso mangoes",
    ],

    # =========================================================
    # BREAD / FLOUR
    # =========================================================

    "bread": [
        "bread",
        "loaf of bread",
        "sliced bread",
    ],

    "bread flour": [
        "bread flour",
        "strong flour",
    ],

    "all purpose flour": [
        "all purpose flour",
        "plain flour",
    ],

    "all purpose white flour": [
        "all purpose flour",
        "plain white flour",
    ],

    # =========================================================
    # CEREAL
    # =========================================================

    "all bran cereal": [
        "all bran cereal",
        "bran cereal",
        "bran flakes",
    ],

    "all bran fiber cereal": [
        "all bran cereal",
        "bran fiber cereal",
        "bran flakes",
    ],

    # =========================================================
    # PANEER
    # =========================================================

    "amul paneer": [
        "amul paneer",
        "paneer",
        "indian cottage cheese",
    ],

    # =========================================================
    # POTATO
    # =========================================================

    "whole potato": [
        "potato",
        "whole potato",
    ],

    "whole potatoes": [
        "potato",
        "whole potato",
        "potatoes",
    ],
}


# =============================================================
# PUBLIC API
# =============================================================


def get_image_search_aliases(
    visual_name: str,
) -> list[str]:
    """
    Return ordered image-search aliases.

    The canonical visual name is always returned first.
    Duplicate aliases are removed while preserving order.
    """

    name = " ".join(
        (visual_name or "").lower().split()
    )

    if not name:
        return []

    aliases = IMAGE_SEARCH_ALIASES.get(
        name,
        [],
    )

    result: list[str] = []

    for value in [name, *aliases]:
        normalized = " ".join(
            value.split()
        )

        if (
            normalized
            and normalized not in result
        ):
            result.append(normalized)

    return result