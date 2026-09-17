from uuid import UUID

from fastapi import HTTPException, status

from app.repositories.shopping_repository import ShoppingRepository
from app.schemas.shopping import (
    ShoppingItemResponse,
    ShoppingListResponse,
)


class ShoppingService:
    def __init__(
        self,
        shopping_repository: ShoppingRepository,
    ):
        self.shopping_repository = shopping_repository

    def generate_shopping_list(
        self,
        meal_plan_id: UUID,
    ) -> ShoppingListResponse:

        meal_plan = self.shopping_repository.get_meal_plan(
            meal_plan_id
        )

        if meal_plan is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Meal plan not found.",
            )

        shopping_items: dict[
            tuple[str, str],
            float,
        ] = {}

        for meal in meal_plan.meals:

            if meal.recipe is None:
                continue

            for ingredient in meal.recipe.ingredients:

                key = (
                    ingredient.name.strip().lower(),
                    ingredient.unit.strip().lower(),
                )

                shopping_items[key] = (
                    shopping_items.get(key, 0)
                    + float(ingredient.quantity)
                )

        items = [
            ShoppingItemResponse(
                ingredient=name.title(),
                quantity=quantity,
                unit=unit,
            )
            for (name, unit), quantity in sorted(
                shopping_items.items()
            )
        ]

        return ShoppingListResponse(
            meal_plan_id=str(meal_plan.id),
            meal_plan_name=meal_plan.name,
            items=items,
        )