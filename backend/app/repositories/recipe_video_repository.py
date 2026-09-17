from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.recipe import Recipe
from app.models.recipe_ingredient import RecipeIngredient


class RecipeVideoRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_recipe(
        self,
        recipe_id: UUID,
    ) -> Recipe | None:
        statement = (
            select(Recipe)
            .where(
                Recipe.id == recipe_id,
                Recipe.is_published.is_(True),
            )
            .options(
                selectinload(Recipe.ingredients)
                .selectinload(RecipeIngredient.ingredient)
            )
        )

        return self.db.scalar(statement)