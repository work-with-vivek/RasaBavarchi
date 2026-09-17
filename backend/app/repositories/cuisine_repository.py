from sqlalchemy.orm import Session

from app.models.cuisine import Cuisine


class CuisineRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_all(self) -> list[Cuisine]:
        return self.db.query(Cuisine).all()

    def get_by_id(self, cuisine_id):
        return (
            self.db.query(Cuisine)
            .filter(Cuisine.id == cuisine_id)
            .first()
        )

    def get_by_name(self, name: str) -> Cuisine | None:
        return (
            self.db.query(Cuisine)
            .filter(Cuisine.name == name)
            .first()
        )