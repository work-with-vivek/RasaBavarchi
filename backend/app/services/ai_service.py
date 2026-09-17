from fastapi import UploadFile
from sqlalchemy import select

from app.models.ingredient import Ingredient
from app.models.recipe import Recipe
from app.models.recipe_ingredient import RecipeIngredient
from app.models.unit import Unit
from app.models.user import User

from app.repositories.category_repository import CategoryRepository
from app.repositories.cuisine_repository import CuisineRepository
from app.repositories.difficulty_repository import DifficultyRepository
from app.repositories.pantry_repository import PantryRepository
from app.repositories.recipe_ingredient_repository import (
    RecipeIngredientRepository,
)
from app.repositories.recipe_repository import RecipeRepository

from app.schemas.ai import (
    ExplainRecipeResponse,
    GeneratePantryRecipeRequest,
    GenerateRecipeRequest,
    GenerateRecipeResponse,
    PantryScanResponse,
)


class AIService:
    def __init__(
        self,
        provider,
        recipe_repository: RecipeRepository,
        recipe_ingredient_repository: RecipeIngredientRepository,
        category_repository: CategoryRepository,
        cuisine_repository: CuisineRepository,
        difficulty_repository: DifficultyRepository,
        pantry_repository: PantryRepository,
    ):
        self.provider = provider
        self.recipe_repository = recipe_repository
        self.recipe_ingredient_repository = (
            recipe_ingredient_repository
        )
        self.category_repository = category_repository
        self.cuisine_repository = cuisine_repository
        self.difficulty_repository = difficulty_repository
        self.pantry_repository = pantry_repository

    # ---------------------------------------------------------
    # Normalization Helpers
    # ---------------------------------------------------------

    def _normalize_category(self, category: str) -> str:
        mapping = {
            "Main Course": "Dinner",
            "Main Dish": "Dinner",
            "Entrée": "Dinner",
            "Entree": "Dinner",
            "Appetizer": "Snack",
            "Starter": "Snack",
            "Side Dish": "Snack",
            "Brunch": "Breakfast",
        }

        return mapping.get(
            category.strip(),
            category.strip(),
        )

    def _normalize_cuisine(self, cuisine: str) -> str:
        mapping = {
            "North Indian": "Indian",
            "South Indian": "Indian",
            "Indo-Chinese": "Chinese",
            "Indian": "Indian",
            "Chinese": "Chinese",
            "Italian": "Italian",
            "Mexican": "Mexican",
        }

        return mapping.get(
            cuisine.strip(),
            cuisine.strip(),
        )

    def _normalize_difficulty(self, difficulty: str) -> str:
        mapping = {
            "Beginner": "Easy",
            "Simple": "Easy",
            "Easy": "Easy",
            "Moderate": "Medium",
            "Medium": "Medium",
            "Advanced": "Hard",
            "Hard": "Hard",
        }

        return mapping.get(
            difficulty.strip(),
            difficulty.strip(),
        )

    # ---------------------------------------------------------
    # Ingredient / Unit Helpers
    # ---------------------------------------------------------

    def _find_ingredient(
        self,
        ingredient_name: str,
    ) -> Ingredient | None:
        name = ingredient_name.strip()

        if not name:
            return None

        statement = (
            select(Ingredient)
            .where(
                Ingredient.name.ilike(name)
            )
            .limit(1)
        )

        return self.recipe_ingredient_repository.db.scalar(
            statement
        )

    def _find_unit(
        self,
        unit_value: str,
    ) -> Unit | None:
        value = unit_value.strip()

        if not value:
            value = "unk"

        statement = (
            select(Unit)
            .where(
                (Unit.symbol.ilike(value))
                | (Unit.name.ilike(value))
            )
            .limit(1)
        )

        unit = self.recipe_ingredient_repository.db.scalar(
            statement
        )

        if unit is not None:
            return unit

        # Safe fallback because the database already contains
        # the Unknown unit used by the existing recipe data.
        unknown_statement = (
            select(Unit)
            .where(
                Unit.symbol.ilike("unk")
            )
            .limit(1)
        )

        return self.recipe_ingredient_repository.db.scalar(
            unknown_statement
        )

    def _parse_quantity(
        self,
        quantity: str,
    ) -> float:
        try:
            value = float(
                str(quantity).strip()
            )

            if value < 0:
                return 0.0

            return value

        except (
            TypeError,
            ValueError,
        ):
            return 0.0

    # ---------------------------------------------------------
    # Save Recipe
    # ---------------------------------------------------------

    def _save_recipe(
        self,
        recipe_data: GenerateRecipeResponse,
        current_user: User,
    ) -> GenerateRecipeResponse:
        category_name = self._normalize_category(
            recipe_data.category
        )

        cuisine_name = self._normalize_cuisine(
            recipe_data.cuisine
        )

        difficulty_name = self._normalize_difficulty(
            recipe_data.difficulty
        )

        category = self.category_repository.get_by_name(
            category_name
        )

        cuisine = self.cuisine_repository.get_by_name(
            cuisine_name
        )

        difficulty = self.difficulty_repository.get_by_name(
            difficulty_name
        )

        if category is None:
            raise ValueError(
                f"Category '{category_name}' not found."
            )

        if cuisine is None:
            raise ValueError(
                f"Cuisine '{cuisine_name}' not found."
            )

        if difficulty is None:
            raise ValueError(
                f"Difficulty '{difficulty_name}' not found."
            )

        recipe = Recipe(
            title=recipe_data.recipe_name,
            description=recipe_data.description,
            instructions="\n".join(
                recipe_data.instructions
            ),
            prep_time=recipe_data.prep_time_minutes,
            cook_time=recipe_data.cook_time_minutes,
            servings=recipe_data.servings,
            calories=recipe_data.nutrition.calories,
            protein_g=recipe_data.nutrition.protein_g,
            carbs_g=recipe_data.nutrition.carbs_g,
            fat_g=recipe_data.nutrition.fat_g,
            category_id=category.id,
            cuisine_id=cuisine.id,
            difficulty_id=difficulty.id,
            author_id=current_user.id,
            is_published=True,
            is_vegetarian=False,
            is_vegan=False,
        )

        saved_recipe = self.recipe_repository.create(
            recipe
        )

        # -----------------------------------------------------
        # Save AI ingredients
        # -----------------------------------------------------

        for ingredient_data in recipe_data.ingredients:
            ingredient = self._find_ingredient(
                ingredient_data.item
            )

            # The AI may return an ingredient that does not
            # exist in the database. Do not crash the whole
            # recipe generation request in that case.
            if ingredient is None:
                continue

            unit = self._find_unit(
                ingredient_data.unit
            )

            # Unit is non-null in RecipeIngredient, so if the
            # Unknown unit is somehow missing, skip this row.
            if unit is None:
                continue

            quantity = self._parse_quantity(
                ingredient_data.quantity
            )

            recipe_ingredient = RecipeIngredient(
                recipe_id=saved_recipe.id,
                ingredient_id=ingredient.id,
                quantity=quantity,
                unit_id=unit.id,
                is_optional=False,
            )

            self.recipe_ingredient_repository.create(
                recipe_ingredient
            )

        return recipe_data

    # ---------------------------------------------------------
    # Generate Recipe
    # ---------------------------------------------------------

    def generate_recipe(
        self,
        request: GenerateRecipeRequest,
        current_user: User,
    ) -> GenerateRecipeResponse:
        result = self.provider.generate_recipe(
            ingredients=request.ingredients,
            cuisine=request.cuisine,
            dietary_preference=request.dietary_preference,
            servings=request.servings,
        )

        recipe_data = GenerateRecipeResponse.model_validate(
            result
        )

        return self._save_recipe(
            recipe_data,
            current_user,
        )

    # ---------------------------------------------------------
    # Generate Recipe From Pantry
    # ---------------------------------------------------------

    def generate_recipe_from_pantry(
        self,
        request: GeneratePantryRecipeRequest,
        current_user: User,
    ) -> GenerateRecipeResponse:
        pantry = self.pantry_repository.get_by_user_id(
            current_user.id,
        )

        if pantry is None:
            raise ValueError(
                "Your pantry is empty."
            )

        pantry_items = (
            self.pantry_repository.get_items_by_pantry_id(
                pantry.id,
            )
        )

        if not pantry_items:
            raise ValueError(
                "Your pantry is empty."
            )

        ingredients = [
            item.ingredient.name
            for item in pantry_items
        ]

        result = self.provider.generate_recipe_from_pantry(
            ingredients=ingredients,
            cuisine=request.cuisine,
            dietary_preference=request.dietary_preference,
            servings=request.servings,
        )

        recipe_data = GenerateRecipeResponse.model_validate(
            result
        )

        return self._save_recipe(
            recipe_data,
            current_user,
        )

    # ---------------------------------------------------------
    # Explain Recipe
    # ---------------------------------------------------------

    def explain_recipe(
        self,
        question: str,
    ) -> ExplainRecipeResponse:
        answer = self.provider.explain_recipe(
            question
        )

        return ExplainRecipeResponse(
            answer=answer,
        )

    # ---------------------------------------------------------
    # Pantry Scan
    # ---------------------------------------------------------

    async def scan_pantry(
        self,
        image: UploadFile,
    ) -> PantryScanResponse:
        if (
            image.content_type is None
            or not image.content_type.startswith("image/")
        ):
            raise ValueError(
                "Uploaded file must be an image."
            )

        image_bytes = await image.read()

        result = self.provider.scan_pantry(
            image_bytes=image_bytes,
            mime_type=image.content_type,
        )

        return PantryScanResponse.model_validate(
            result
        )