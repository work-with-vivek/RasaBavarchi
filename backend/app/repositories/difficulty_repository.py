from sqlalchemy.orm import Session

from app.models.difficulty import Difficulty


class DifficultyRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_all(self) -> list[Difficulty]:
        return self.db.query(Difficulty).all()

    def get_by_id(self, difficulty_id):
        return (
            self.db.query(Difficulty)
            .filter(Difficulty.id == difficulty_id)
            .first()
        )

    def get_by_name(self, name: str) -> Difficulty | None:
        return (
            self.db.query(Difficulty)
            .filter(Difficulty.name == name)
            .first()
        )