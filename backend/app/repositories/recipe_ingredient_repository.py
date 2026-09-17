from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.recipe_ingredient import RecipeIngredient


class RecipeIngredientRepository:
    def __init__(
        self,
        db: Session,
    ):
        self.db = db

    def create(
        self,
        ingredient: RecipeIngredient,
    ):
        self.db.add(ingredient)
        self.db.commit()
        self.db.refresh(ingredient)
        return ingredient

    def get_by_id(
        self,
        ingredient_id: UUID,
    ):
        statement = (
            select(RecipeIngredient)
            .where(
                RecipeIngredient.id == ingredient_id
            )
        )

        return self.db.scalar(statement)

    def get_by_recipe(
        self,
        recipe_id: UUID,
    ):
        statement = (
            select(RecipeIngredient)
            .where(
                RecipeIngredient.recipe_id == recipe_id
            )
            .order_by(RecipeIngredient.created_at)
        )

        return self.db.scalars(statement).all()

    def update(
        self,
        ingredient: RecipeIngredient,
    ):
        self.db.commit()
        self.db.refresh(ingredient)
        return ingredient

    def delete(
        self,
        ingredient: RecipeIngredient,
    ):
        self.db.delete(ingredient)
        self.db.commit()