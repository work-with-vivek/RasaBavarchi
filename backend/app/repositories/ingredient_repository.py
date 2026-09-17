from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.ingredient import Ingredient


class IngredientRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_name(
        self,
        name: str,
    ) -> Ingredient | None:
        normalized_name = name.strip().lower()

        statement = select(Ingredient).where(
            Ingredient.name.ilike(normalized_name),
        )

        return self.db.scalar(statement)

    def search_by_name(
        self,
        name: str,
        limit: int = 10,
    ) -> list[Ingredient]:
        normalized_name = name.strip().lower()

        if not normalized_name:
            return []

        statement = (
            select(Ingredient)
            .where(
                Ingredient.name.ilike(
                    f"%{normalized_name}%",
                )
            )
            .order_by(Ingredient.name)
            .limit(limit)
        )

        return list(self.db.scalars(statement).all())