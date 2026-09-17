from __future__ import annotations

import re


# =========================================================
# SOURCE / TITLE NOISE
# =========================================================

NOISE_WORDS = {
    "recipe",
    "recipes",
    "easy",
    "quick",
    "simple",
    "best",
    "favorite",
    "favourite",
    "homemade",
    "my",
    "our",
    "grandma",
    "grandmother",
    "grandpa",
    "grandfather",
    "mrs",
    "mr",
    "miss",
    "stand",
    "restaurant",
    "bakery",
}


# =========================================================
# NORMALIZE
# =========================================================

def normalize_title(title: str) -> str:
    """
    Normalize a recipe title.

    Handles apostrophes/possessives so that:

        bird's

    and:

        bird s

    do not leave a meaningless standalone "s".
    """

    title = (title or "").strip().lower()

    # Normalize curly apostrophes.
    title = title.replace("’", "'")

    # Remove possessive apostrophe before normalization.
    #
    # bird's -> bird
    # grandma's -> grandma
    title = re.sub(
        r"([a-z])'s\b",
        r"\1",
        title,
    )

    # Remove remaining apostrophes.
    title = title.replace(
        "'",
        " ",
    )

    # Remove punctuation.
    title = re.sub(
        r"[^a-z0-9\s]",
        " ",
        title,
    )

    # Collapse whitespace.
    title = re.sub(
        r"\s+",
        " ",
        title,
    )

    return title.strip()


# =========================================================
# TOKENS
# =========================================================

def title_tokens(title: str) -> list[str]:
    """
    Return normalized title tokens.
    """

    normalized = normalize_title(
        title
    )

    return [
        token
        for token in normalized.split()
        if token
    ]


# =========================================================
# CLEAN TITLE
# =========================================================

def clean_recipe_title(title: str) -> str:
    """
    Remove obvious source/title noise while preserving
    meaningful recipe terms.
    """

    tokens = title_tokens(
        title
    )

    cleaned: list[str] = []

    for token in tokens:

        # Standalone "s" is normally an artifact caused by
        # possessive text such as "bird's" becoming "bird s".
        if token == "s":
            continue

        if token in NOISE_WORDS:
            continue

        cleaned.append(
            token
        )

    return " ".join(
        cleaned
    )


# =========================================================
# SEARCH TITLE VARIANTS
# =========================================================

def get_clean_title_variants(
    title: str,
) -> list[str]:
    """
    Return useful title variants.

    The original normalized title is retained first.
    """

    original = normalize_title(
        title
    )

    cleaned = clean_recipe_title(
        title
    )

    variants: list[str] = []

    def add(value: str) -> None:

        value = normalize_title(
            value
        )

        if not value:
            return

        if value in variants:
            return

        variants.append(
            value
        )

    add(original)
    add(cleaned)

    return variants