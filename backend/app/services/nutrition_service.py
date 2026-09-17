from uuid import UUID

from app.ai.providers.gemini_provider import GeminiProvider
from app.models.user import User
from app.repositories.nutrition_repository import (
    NutritionRepository,
)
from app.schemas.ai import Nutrition
from app.schemas.nutrition import (
    MealNutritionResponse,
    NutritionSummary,
    RecipeNutritionResponse,
)


class NutritionService:
    def __init__(
        self,
        nutrition_repository: NutritionRepository,
        provider: GeminiProvider,
    ):
        self.nutrition_repository = nutrition_repository
        self.provider = provider

    # =========================================================
    # CHECK WHETHER NUTRITION EXISTS
    # =========================================================

    def _has_nutrition(
        self,
        recipe,
    ) -> bool:
        return (
            recipe.calories > 0
            and recipe.protein_g > 0
            and recipe.carbs_g > 0
            and recipe.fat_g > 0
        )

    # =========================================================
    # BUILD INGREDIENT LIST FOR GEMINI
    # =========================================================

    def _build_ingredient_list(
        self,
        recipe,
    ) -> list[str]:

        ingredients: list[str] = []

        for recipe_ingredient in recipe.ingredients:
            ingredient_name = (
                recipe_ingredient.ingredient.name
            )

            quantity = recipe_ingredient.quantity

            unit_symbol = (
                recipe_ingredient.unit.symbol
            )

            ingredients.append(
                f"{quantity} {unit_symbol} "
                f"{ingredient_name}"
            )

        return ingredients

    # =========================================================
    # GENERATE AND SAVE NUTRITION
    # =========================================================

    def _generate_and_save_nutrition(
        self,
        recipe,
    ):
        ingredients = self._build_ingredient_list(
            recipe
        )

        if not ingredients:
            raise ValueError(
                "Recipe has no ingredients. "
                "Cannot calculate nutrition."
            )

        result = self.provider.generate_nutrition(
            recipe_name=recipe.title,
            servings=recipe.servings,
            ingredients=ingredients,
        )

        # -----------------------------------------------------
        # Validate Gemini response with Pydantic
        # -----------------------------------------------------

        nutrition = Nutrition.model_validate(
            result
        )

        # -----------------------------------------------------
        # Additional safety validation
        # -----------------------------------------------------

        values = (
            nutrition.calories,
            nutrition.protein_g,
            nutrition.carbs_g,
            nutrition.fat_g,
        )

        if any(value < 0 for value in values):
            raise ValueError(
                "Generated nutrition contains "
                "negative values."
            )

        if not any(value > 0 for value in values):
            raise ValueError(
                "Generated nutrition contains only "
                "zero values."
            )

        # -----------------------------------------------------
        # Save to PostgreSQL
        # -----------------------------------------------------

        return (
            self.nutrition_repository.update_recipe_nutrition(
                recipe=recipe,
                calories=float(nutrition.calories),
                protein_g=float(nutrition.protein_g),
                carbs_g=float(nutrition.carbs_g),
                fat_g=float(nutrition.fat_g),
            )
        )

    # =========================================================
    # RECIPE NUTRITION
    # =========================================================

    def get_recipe_nutrition(
        self,
        recipe_id: UUID,
    ) -> RecipeNutritionResponse:

        recipe = self.nutrition_repository.get_recipe(
            recipe_id
        )

        if recipe is None:
            raise ValueError(
                "Recipe not found."
            )

        # -----------------------------------------------------
        # CACHE HIT
        # -----------------------------------------------------
        # Nutrition already exists in PostgreSQL.
        # Do NOT call Gemini again.

        if self._has_nutrition(recipe):
            return RecipeNutritionResponse(
                recipe_id=str(recipe.id),
                recipe_name=recipe.title,
                calories=recipe.calories,
                protein_g=recipe.protein_g,
                carbs_g=recipe.carbs_g,
                fat_g=recipe.fat_g,
            )

        # -----------------------------------------------------
        # CACHE MISS
        # -----------------------------------------------------
        # Nutrition is missing.
        # Generate it using the existing GeminiProvider.

        recipe = self._generate_and_save_nutrition(
            recipe
        )

        return RecipeNutritionResponse(
            recipe_id=str(recipe.id),
            recipe_name=recipe.title,
            calories=recipe.calories,
            protein_g=recipe.protein_g,
            carbs_g=recipe.carbs_g,
            fat_g=recipe.fat_g,
        )

    # =========================================================
    # MEAL PLAN NUTRITION
    # =========================================================

    def get_meal_plan_nutrition(
        self,
        meal_plan_id: UUID,
        current_user: User,
    ) -> MealNutritionResponse:

        meal_plan = (
            self.nutrition_repository.get_meal_plan(
                meal_plan_id
            )
        )

        if meal_plan is None:
            raise ValueError(
                "Meal plan not found."
            )

        if meal_plan.user_id != current_user.id:
            raise ValueError(
                "You do not have permission to access "
                "this meal plan."
            )

        breakfast = NutritionSummary()
        lunch = NutritionSummary()
        dinner = NutritionSummary()
        snack = NutritionSummary()

        for meal in meal_plan.meals:

            recipe = meal.recipe

            # -------------------------------------------------
            # Lazy nutrition generation
            # -------------------------------------------------

            if not self._has_nutrition(recipe):
                recipe = (
                    self._generate_and_save_nutrition(
                        recipe
                    )
                )

            # -------------------------------------------------
            # Add nutrition to meal category
            # -------------------------------------------------

            if meal.meal_type == "Breakfast":

                breakfast.calories += recipe.calories
                breakfast.protein_g += recipe.protein_g
                breakfast.carbs_g += recipe.carbs_g
                breakfast.fat_g += recipe.fat_g

            elif meal.meal_type == "Lunch":

                lunch.calories += recipe.calories
                lunch.protein_g += recipe.protein_g
                lunch.carbs_g += recipe.carbs_g
                lunch.fat_g += recipe.fat_g

            elif meal.meal_type == "Dinner":

                dinner.calories += recipe.calories
                dinner.protein_g += recipe.protein_g
                dinner.carbs_g += recipe.carbs_g
                dinner.fat_g += recipe.fat_g

            elif meal.meal_type == "Snack":

                snack.calories += recipe.calories
                snack.protein_g += recipe.protein_g
                snack.carbs_g += recipe.carbs_g
                snack.fat_g += recipe.fat_g

        # =====================================================
        # TOTAL
        # =====================================================

        total = NutritionSummary(
            calories=(
                breakfast.calories
                + lunch.calories
                + dinner.calories
                + snack.calories
            ),
            protein_g=(
                breakfast.protein_g
                + lunch.protein_g
                + dinner.protein_g
                + snack.protein_g
            ),
            carbs_g=(
                breakfast.carbs_g
                + lunch.carbs_g
                + dinner.carbs_g
                + snack.carbs_g
            ),
            fat_g=(
                breakfast.fat_g
                + lunch.fat_g
                + dinner.fat_g
                + snack.fat_g
            ),
        )

        return MealNutritionResponse(
            breakfast=breakfast,
            lunch=lunch,
            dinner=dinner,
            snack=snack,
            total=total,
        )