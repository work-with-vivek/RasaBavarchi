from uuid import UUID

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Response,
    status,
)
from sqlalchemy.orm import Session

from app.dependencies.auth import get_current_user
from app.dependencies.database import get_db

from app.models.user import User

from app.repositories.meal_plan_repository import (
    MealPlanRepository,
)
from app.repositories.recipe_repository import (
    RecipeRepository,
)

from app.schemas.meal_plan import (
    MealCreate,
    MealPlanCreate,
    MealPlanResponse,
    MealPlanUpdate,
)

from app.services.meal_plan_service import (
    MealPlanService,
)

router = APIRouter(
    prefix="/meal-plans",
    tags=["Meal Plans"],
)


def get_meal_plan_service(
    db: Session = Depends(get_db),
) -> MealPlanService:
    return MealPlanService(
        meal_plan_repository=MealPlanRepository(db),
        recipe_repository=RecipeRepository(db),
    )


@router.post(
    "",
    response_model=MealPlanResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_meal_plan(
    request: MealPlanCreate,
    current_user: User = Depends(get_current_user),
    service: MealPlanService = Depends(
        get_meal_plan_service
    ),
):
    try:
        return service.create_meal_plan(
            request,
            current_user,
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )


@router.get(
    "",
    response_model=list[MealPlanResponse],
)
def get_meal_plans(
    current_user: User = Depends(get_current_user),
    service: MealPlanService = Depends(
        get_meal_plan_service
    ),
):
    return service.get_meal_plans(
        current_user,
    )


@router.get(
    "/{meal_plan_id}",
    response_model=MealPlanResponse,
)
def get_meal_plan(
    meal_plan_id: UUID,
    current_user: User = Depends(get_current_user),
    service: MealPlanService = Depends(
        get_meal_plan_service
    ),
):
    try:
        return service.get_meal_plan(
            meal_plan_id,
            current_user,
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )


@router.put(
    "/{meal_plan_id}",
    response_model=MealPlanResponse,
)
def update_meal_plan(
    meal_plan_id: UUID,
    request: MealPlanUpdate,
    current_user: User = Depends(get_current_user),
    service: MealPlanService = Depends(
        get_meal_plan_service
    ),
):
    try:
        return service.update_meal_plan(
            meal_plan_id,
            request,
            current_user,
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )


@router.delete(
    "/{meal_plan_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_meal_plan(
    meal_plan_id: UUID,
    current_user: User = Depends(get_current_user),
    service: MealPlanService = Depends(
        get_meal_plan_service
    ),
):
    try:
        service.delete_meal_plan(
            meal_plan_id,
            current_user,
        )

        return Response(
            status_code=status.HTTP_204_NO_CONTENT,
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )


@router.post(
    "/{meal_plan_id}/meals",
    status_code=status.HTTP_201_CREATED,
)
def add_meal(
    meal_plan_id: UUID,
    request: MealCreate,
    current_user: User = Depends(get_current_user),
    service: MealPlanService = Depends(
        get_meal_plan_service
    ),
):
    try:
        return service.add_meal(
            meal_plan_id,
            request,
            current_user,
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )


@router.delete(
    "/meals/{meal_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_meal(
    meal_id: UUID,
    current_user: User = Depends(get_current_user),
    service: MealPlanService = Depends(
        get_meal_plan_service
    ),
):
    try:
        service.remove_meal(
            meal_id,
            current_user,
        )

        return Response(
            status_code=status.HTTP_204_NO_CONTENT,
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )