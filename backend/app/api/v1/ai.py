from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    UploadFile,
    status,
)
from sqlalchemy.orm import Session

from app.ai.providers.gemini_provider import GeminiProvider
from app.dependencies.auth import get_current_user
from app.dependencies.database import get_db

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


def get_ai_service(
    db: Session = Depends(get_db),
) -> AIService:
    return AIService(
        provider=GeminiProvider(),
        recipe_repository=RecipeRepository(db),
        recipe_ingredient_repository=RecipeIngredientRepository(db),
        category_repository=CategoryRepository(db),
        cuisine_repository=CuisineRepository(db),
        difficulty_repository=DifficultyRepository(db),
        pantry_repository=PantryRepository(db),
    )


@router.post(
    "/generate-recipe",
    response_model=GenerateRecipeResponse,
)
def generate_recipe(
    request: GenerateRecipeRequest,
    current_user: User = Depends(get_current_user),
    service: AIService = Depends(get_ai_service),
):
    return service.generate_recipe(
        request=request,
        current_user=current_user,
    )


@router.post(
    "/generate-recipe-from-pantry",
    response_model=GenerateRecipeResponse,
)
def generate_recipe_from_pantry(
    request: GeneratePantryRecipeRequest,
    current_user: User = Depends(get_current_user),
    service: AIService = Depends(get_ai_service),
):
    try:
        return service.generate_recipe_from_pantry(
            request=request,
            current_user=current_user,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )
    
@router.post(
    "/explain-recipe",
    response_model=ExplainRecipeResponse,
)
def explain_recipe(
    request: ExplainRecipeRequest,
    service: AIService = Depends(get_ai_service),
):
    return service.explain_recipe(
        question=request.question,
    )
@router.post(
    "/pantry-scan",
    response_model=PantryScanResponse,
)
async def scan_pantry(
    image: UploadFile = File(...),
    service: AIService = Depends(get_ai_service),
):
    try:
        return await service.scan_pantry(image)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )