from pathlib import Path

# Dataset
DATASET_PATH = Path("data/RAW_recipes.csv")

# Import settings
BATCH_SIZE = 1000

# Set to None to import everything
IMPORT_LIMIT = None

# Show progress every N recipes
PROGRESS_INTERVAL = 1000

# Default values
DEFAULT_SERVINGS = 4
DEFAULT_IMAGE_URL = ""

# Logging
LOG_FILE = "import_errors.log"