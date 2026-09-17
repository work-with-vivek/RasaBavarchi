from fastapi import (
    APIRouter,
    Depends,
    File,
    UploadFile,
    status,
)

from app.ai.providers.gemini_provider import GeminiProvider
from app.dependencies.auth import get_current_user
from app.db.session import get_db
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
    ExplainRecipeRequest,
    ExplainRecipeResponse,
    GeneratePantryRecipeRequest,
    GenerateRecipeRequest,
    GenerateRecipeResponse,
    PantryScanResponse,
)
from app.services.ai_service import AIService

router = APIRouter(
    prefix="/ai",
    tags=["AI"],
)
def get_ai_service() -> AIService:
    db = next(get_db())

    return AIService(
        provider=GeminiProvider(),
        recipe_repository=RecipeRepository(db),
        recipe_ingredient_repository=RecipeIngredientRepository(db),
        category_repository=CategoryRepository(db),
        cuisine_repository=CuisineRepository(db),
        difficulty_repository=DifficultyRepository(db),
        pantry_repository=PantryRepository(db),
    )