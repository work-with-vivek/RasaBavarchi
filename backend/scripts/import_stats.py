from dataclasses import dataclass
from time import time


@dataclass
class ImportStats:
    imported: int = 0
    skipped: int = 0
    failed: int = 0

    def __post_init__(self):
        self.start_time = time()

    def print_summary(self):
        elapsed = time() - self.start_time

        print("\n" + "=" * 50)
        print("IMPORT COMPLETED")
        print("=" * 50)
        print(f"Imported : {self.imported}")
        print(f"Skipped  : {self.skipped}")
        print(f"Failed   : {self.failed}")
        print(f"Time     : {elapsed:.2f} seconds")
        print("=" * 50)