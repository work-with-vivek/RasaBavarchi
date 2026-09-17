from uuid import UUID

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)
from sqlalchemy.orm import Session

from app.ai.providers.gemini_provider import GeminiProvider
from app.dependencies.auth import get_current_user
from app.dependencies.database import get_db
from app.models.user import User
from app.repositories.nutrition_repository import (
    NutritionRepository,
)
from app.schemas.nutrition import (
    MealNutritionResponse,
    RecipeNutritionResponse,
)
from app.services.nutrition_service import (
    NutritionService,
)


router = APIRouter(
    prefix="/nutrition",
    tags=["Nutrition"],
)


# =========================================================
# NUTRITION SERVICE DEPENDENCY
# =========================================================

def get_nutrition_service(
    db: Session = Depends(get_db),
) -> NutritionService:

    return NutritionService(
        nutrition_repository=NutritionRepository(db),
        provider=GeminiProvider(),
    )


# =========================================================
# RECIPE NUTRITION
# =========================================================

@router.get(
    "/recipes/{recipe_id}",
    response_model=RecipeNutritionResponse,
)
def get_recipe_nutrition(
    recipe_id: UUID,
    service: NutritionService = Depends(
        get_nutrition_service
    ),
):
    try:
        return service.get_recipe_nutrition(
            recipe_id
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )


# =========================================================
# MEAL PLAN NUTRITION
# =========================================================

@router.get(
    "/meal-plans/{meal_plan_id}",
    response_model=MealNutritionResponse,
)
def get_meal_plan_nutrition(
    meal_plan_id: UUID,
    current_user: User = Depends(
        get_current_user
    ),
    service: NutritionService = Depends(
        get_nutrition_service
    ),
):
    try:
        return service.get_meal_plan_nutrition(
            meal_plan_id=meal_plan_id,
            current_user=current_user,
        )

    except ValueError as exc:

        if "permission" in str(exc).lower():
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=str(exc),
            )

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )