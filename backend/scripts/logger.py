from pathlib import Path

from import_config import LOG_FILE


class ImportLogger:
    def __init__(self):
        self.log_path = Path(LOG_FILE)

    def log(self, recipe_id: int, message: str):
        with self.log_path.open(
            "a",
            encoding="utf-8",
        ) as file:
            file.write(
                f"Recipe {recipe_id}: {message}\n"
            )

    def clear(self):
        self.log_path.write_text(
            "",
            encoding="utf-8",
        )