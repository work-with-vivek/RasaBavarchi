from pathlib import Path


# =============================================================
# RasaBavarchi - Ingredient Image Import Configuration
# =============================================================

# -------------------------------------------------------------
# IMPORTANT
# -------------------------------------------------------------
# Start with 20.
#
# After successful testing:
#
#     20
#     100
#     500
#     1000
#     5000
#     14000+
#
# Do NOT immediately run the complete database.
# -------------------------------------------------------------

IMPORT_LIMIT = 20


# =============================================================
# Paths
# =============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

MEDIA_DIR = BASE_DIR / "media"

INGREDIENT_IMAGE_DIR = (
    MEDIA_DIR / "images" / "ingredients"
)

INGREDIENT_IMAGE_DIR.mkdir(
    parents=True,
    exist_ok=True,
)


# =============================================================
# Wikimedia
# =============================================================

WIKIMEDIA_API_URL = (
    "https://commons.wikimedia.org/w/api.php"
)

USER_AGENT = (
    "RasaBavarchi/1.0 "
    "(ingredient image importer)"
)


# =============================================================
# Request Settings
# =============================================================

SEARCH_TIMEOUT = 20

DOWNLOAD_TIMEOUT = 30

REQUEST_DELAY_SECONDS = 2.0

RATE_LIMIT_BACKOFF_SECONDS = 30.0

MAX_RETRIES = 3


# =============================================================
# Search Settings
# =============================================================

SEARCH_RESULTS = 10

THUMBNAIL_WIDTH = 1000


# =============================================================
# Allowed Image Types
# =============================================================

ALLOWED_MIME_TYPES = {
    "image/jpeg": ".jpg",
    "image/jpg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}


# =============================================================
# Confidence
# =============================================================

MINIMUM_SCORE = 60