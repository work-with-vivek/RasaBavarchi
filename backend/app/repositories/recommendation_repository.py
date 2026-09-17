from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.pantry import Pantry
from app.models.pantry_item import PantryItem
from app.models.recipe import Recipe
from app.models.recipe_ingredient import RecipeIngredient


class RecommendationRepository:
    def __init__(
        self,
        db: Session,
    ):
        self.db = db

    def get_user_pantry(
        self,
        user_id: UUID,
    ) -> Pantry | None:
        statement = (
            select(Pantry)
            .options(
                selectinload(Pantry.pantry_items).selectinload(
                    PantryItem.ingredient
                ),
                selectinload(Pantry.pantry_items).selectinload(
                    PantryItem.unit
                ),
            )
            .where(Pantry.user_id == user_id)
        )

        return self.db.scalar(statement)

    def get_published_recipes(
        self,
        vegetarian: bool | None = None,
        vegan: bool | None = None,
    ) -> list[Recipe]:
        statement = (
            select(Recipe)
            .options(
                selectinload(Recipe.category),
                selectinload(Recipe.cuisine),
                selectinload(Recipe.difficulty),
                selectinload(Recipe.author),
                selectinload(Recipe.ingredients).selectinload(
                    RecipeIngredient.ingredient
                ),
                selectinload(Recipe.ingredients).selectinload(
                    RecipeIngredient.unit
                ),
            )
            .where(Recipe.is_published.is_(True))
        )

        if vegetarian is not None:
            statement = statement.where(
                Recipe.is_vegetarian == vegetarian
            )

        if vegan is not None:
            statement = statement.where(
                Recipe.is_vegan == vegan
            )

        return self.db.scalars(statement).all()