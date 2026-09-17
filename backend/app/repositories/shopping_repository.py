from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.meal import Meal
from app.models.meal_plan import MealPlan
from app.models.recipe import Recipe


class ShoppingRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_meal_plan(
        self,
        meal_plan_id: UUID,
    ) -> MealPlan | None:
        """
        Load a meal plan together with:
        MealPlan
            -> Meals
                -> Recipe
                    -> Ingredients
        """

        stmt = (
            select(MealPlan)
            .options(
                selectinload(MealPlan.meals)
                .selectinload(Meal.recipe)
                .selectinload(Recipe.ingredients)
            )
            .where(MealPlan.id == meal_plan_id)
        )

        return self.db.scalar(stmt)