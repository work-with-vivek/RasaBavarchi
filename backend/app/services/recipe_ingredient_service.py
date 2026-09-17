from uuid import UUID

from app.models.recipe_ingredient import RecipeIngredient
from app.repositories.recipe_ingredient_repository import (
    RecipeIngredientRepository,
)
from app.repositories.recipe_repository import RecipeRepository
from app.schemas.recipe_ingredient import (
    RecipeIngredientCreate,
    RecipeIngredientUpdate,
)


class RecipeIngredientService:
    def __init__(
        self,
        recipe_repository: RecipeRepository,
        ingredient_repository: RecipeIngredientRepository,
    ):
        self.recipe_repository = recipe_repository
        self.ingredient_repository = ingredient_repository

    def create_ingredient(
        self,
        recipe_id: UUID,
        request: RecipeIngredientCreate,
    ):
        recipe = self.recipe_repository.get_by_id(
            recipe_id
        )

        if recipe is None:
            raise ValueError("Recipe not found")

        ingredient = RecipeIngredient(
            recipe_id=recipe_id,
            name=request.name,
            quantity=request.quantity,
            unit=request.unit,
            is_optional=request.is_optional,
        )

        return self.ingredient_repository.create(
            ingredient
        )

    def get_ingredients(
        self,
        recipe_id: UUID,
    ):
        recipe = self.recipe_repository.get_by_id(
            recipe_id
        )

        if recipe is None:
            raise ValueError("Recipe not found")

        return self.ingredient_repository.get_by_recipe(
            recipe_id
        )

    def update_ingredient(
        self,
        ingredient_id: UUID,
        request: RecipeIngredientUpdate,
    ):
        ingredient = (
            self.ingredient_repository.get_by_id(
                ingredient_id
            )
        )

        if ingredient is None:
            raise ValueError(
                "Ingredient not found"
            )

        if request.name is not None:
            ingredient.name = request.name

        if request.quantity is not None:
            ingredient.quantity = request.quantity

        if request.unit is not None:
            ingredient.unit = request.unit

        if request.is_optional is not None:
            ingredient.is_optional = (
                request.is_optional
            )

        return self.ingredient_repository.update(
            ingredient
        )

    def delete_ingredient(
        self,
        ingredient_id: UUID,
    ):
        ingredient = (
            self.ingredient_repository.get_by_id(
                ingredient_id
            )
        )

        if ingredient is None:
            raise ValueError(
                "Ingredient not found"
            )

        self.ingredient_repository.delete(
            ingredient
        )