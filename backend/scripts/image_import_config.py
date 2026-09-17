from pathlib import Path


# =============================================================
# RasaBavarchi - Recipe Image Import Configuration
# =============================================================

IMPORT_LIMIT = 1000


# =============================================================
# Paths
# =============================================================

BASE_DIR = Path(__file__).resolve().parent.parent

MEDIA_DIR = BASE_DIR / "media" / "images"


# =============================================================
# Wikimedia API
# =============================================================

WIKIMEDIA_API_URL = (
    "https://commons.wikimedia.org/w/api.php"
)

USER_AGENT = (
    "RasaBavarchi/1.0 "
    "(recipe image importer)"
)


# =============================================================
# Request Settings
# =============================================================

SEARCH_TIMEOUT = 20

DOWNLOAD_TIMEOUT = 30

REQUEST_DELAY_SECONDS = 5.0

RATE_LIMIT_BACKOFF_SECONDS = 60.0

MAX_RETRIES = 3


# =============================================================
# Search Settings
# =============================================================

SEARCH_RESULTS = 10

THUMBNAIL_WIDTH = 1200


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
# Openverse
# =============================================================

OPENVERSE_API_URL = (
    "https://api.openverse.org/v1/images/"
)

OPENVERSE_SEARCH_RESULTS = 20

OPENVERSE_SEARCH_TIMEOUT = 20

OPENVERSE_MIN_SCORE = 35