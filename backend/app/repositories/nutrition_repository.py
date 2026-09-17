from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.meal import Meal
from app.models.meal_plan import MealPlan
from app.models.recipe import Recipe
from app.models.recipe_ingredient import RecipeIngredient


class NutritionRepository:
    def __init__(
        self,
        db: Session,
    ):
        self.db = db

    # =========================================================
    # GET RECIPE
    # =========================================================

    def get_recipe(
        self,
        recipe_id: UUID,
    ) -> Recipe | None:

        stmt = (
            select(Recipe)
            .options(
                selectinload(
                    Recipe.ingredients
                ).selectinload(
                    RecipeIngredient.ingredient
                ),
                selectinload(
                    Recipe.ingredients
                ).selectinload(
                    RecipeIngredient.unit
                ),
            )
            .where(
                Recipe.id == recipe_id
            )
        )

        return self.db.scalar(stmt)

    # =========================================================
    # UPDATE RECIPE NUTRITION
    # =========================================================

    def update_recipe_nutrition(
        self,
        recipe: Recipe,
        calories: float,
        protein_g: float,
        carbs_g: float,
        fat_g: float,
    ) -> Recipe:

        recipe.calories = calories
        recipe.protein_g = protein_g
        recipe.carbs_g = carbs_g
        recipe.fat_g = fat_g

        self.db.commit()
        self.db.refresh(recipe)

        return recipe

    # =========================================================
    # GET MEAL PLAN
    # =========================================================

    def get_meal_plan(
        self,
        meal_plan_id: UUID,
    ) -> MealPlan | None:

        stmt = (
            select(MealPlan)
            .options(
                selectinload(
                    MealPlan.meals
                ).selectinload(
                    Meal.recipe
                )
            )
            .where(
                MealPlan.id == meal_plan_id
            )
        )

        return self.db.scalar(stmt)