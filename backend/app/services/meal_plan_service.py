from uuid import UUID

from app.models.meal import Meal
from app.models.meal_plan import MealPlan
from app.models.user import User

from app.repositories.meal_plan_repository import (
    MealPlanRepository,
)
from app.repositories.recipe_repository import RecipeRepository

from app.schemas.meal_plan import (
    MealCreate,
    MealPlanCreate,
    MealPlanResponse,
    MealPlanUpdate,
)


class MealPlanService:
    def __init__(
        self,
        meal_plan_repository: MealPlanRepository,
        recipe_repository: RecipeRepository,
    ):
        self.meal_plan_repository = meal_plan_repository
        self.recipe_repository = recipe_repository

    # ---------------------------------
    # Meal Plans
    # ---------------------------------

    def create_meal_plan(
        self,
        request: MealPlanCreate,
        current_user: User,
    ) -> MealPlan:

        meal_plan = MealPlan(
            name=request.name,
            description=request.description,
            user_id=current_user.id,
        )

        return self.meal_plan_repository.create(
            meal_plan
        )

    def get_meal_plans(
        self,
        current_user: User,
    ) -> list[MealPlan]:

        return self.meal_plan_repository.get_by_user(
            current_user.id
        )

    def get_meal_plan(
        self,
        meal_plan_id: UUID,
        current_user: User,
    ) -> MealPlan:

        meal_plan = (
            self.meal_plan_repository.get_by_id(
                meal_plan_id
            )
        )

        if meal_plan is None:
            raise ValueError(
                "Meal plan not found."
            )

        if meal_plan.user_id != current_user.id:
            raise ValueError(
                "You do not have permission to access this meal plan."
            )

        return meal_plan

    def update_meal_plan(
        self,
        meal_plan_id: UUID,
        request: MealPlanUpdate,
        current_user: User,
    ) -> MealPlan:

        meal_plan = self.get_meal_plan(
            meal_plan_id,
            current_user,
        )

        if request.name is not None:
            meal_plan.name = request.name

        if request.description is not None:
            meal_plan.description = (
                request.description
            )

        return self.meal_plan_repository.update(
            meal_plan
        )

    def delete_meal_plan(
        self,
        meal_plan_id: UUID,
        current_user: User,
    ) -> None:

        meal_plan = self.get_meal_plan(
            meal_plan_id,
            current_user,
        )

        self.meal_plan_repository.delete(
            meal_plan
        )

    # ---------------------------------
    # Meals
    # ---------------------------------

    def add_meal(
        self,
        meal_plan_id: UUID,
        request: MealCreate,
        current_user: User,
    ) -> Meal:

        meal_plan = self.get_meal_plan(
            meal_plan_id,
            current_user,
        )

        recipe = self.recipe_repository.get_by_id(
            request.recipe_id
        )

        if recipe is None:
            raise ValueError(
                "Recipe not found."
            )

        meal = Meal(
            meal_plan_id=meal_plan.id,
            recipe_id=request.recipe_id,
            meal_date=request.meal_date,
            meal_type=request.meal_type,
            notes=request.notes,
        )

        return self.meal_plan_repository.add_meal(
            meal
        )

    def remove_meal(
        self,
        meal_id: UUID,
        current_user: User,
    ) -> None:

        meal = (
            self.meal_plan_repository.get_meal_by_id(
                meal_id
            )
        )

        if meal is None:
            raise ValueError(
                "Meal not found."
            )

        meal_plan = self.get_meal_plan(
            meal.meal_plan_id,
            current_user,
        )

        self.meal_plan_repository.delete_meal(
            meal
        )