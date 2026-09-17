from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.dependencies.auth import get_current_user
from app.dependencies.weight_loss import get_weight_loss_service
from app.models.user import User
from app.schemas.weight_loss import (
    WeightLossCalculationResponse,
    WeightLossProfileCreate,
    WeightLossProfileResponse,
)
from app.services.weight_loss_service import WeightLossService

router = APIRouter(
    prefix="/weight-loss",
    tags=["Weight Loss"],
)


@router.get(
    "/profile",
    response_model=WeightLossProfileResponse | None,
)
def get_weight_loss_profile(
    current_user: User = Depends(get_current_user),
    service: WeightLossService = Depends(
        get_weight_loss_service
    ),
):
    return service.get_profile(
        user_id=current_user.id
    )


@router.post(
    "/profile",
    response_model=WeightLossProfileResponse,
    status_code=status.HTTP_200_OK,
)
def create_or_update_weight_loss_profile(
    profile_data: WeightLossProfileCreate,
    current_user: User = Depends(get_current_user),
    service: WeightLossService = Depends(
        get_weight_loss_service
    ),
):
    try:
        return service.create_or_update_profile(
            user=current_user,
            profile_data=profile_data,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )


@router.get(
    "/calculate",
    response_model=WeightLossCalculationResponse,
)
def calculate_weight_loss(
    current_user: User = Depends(get_current_user),
    service: WeightLossService = Depends(
        get_weight_loss_service
    ),
):
    try:
        return service.calculate(
            user_id=current_user.id
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )


@router.get(
    "/recipes",
    response_model=list[dict],
)
def get_weight_loss_recipes(
    vegetarian: bool | None = Query(
        default=None
    ),
    vegan: bool | None = Query(
        default=None
    ),
    limit: int = Query(
        default=12,
        ge=1,
        le=50,
    ),
    current_user: User = Depends(get_current_user),
    service: WeightLossService = Depends(
        get_weight_loss_service
    ),
):
    try:
        recipes = service.get_weight_loss_recipes(
            user_id=current_user.id,
            vegetarian=vegetarian,
            vegan=vegan,
            limit=limit,
        )

        return [
            {
                "id": str(recipe.id),
                "title": recipe.title,
                "description": recipe.description,
                "instructions": recipe.instructions,
                "prep_time": recipe.prep_time,
                "cook_time": recipe.cook_time,
                "servings": recipe.servings,
                "calories": recipe.calories,
                "protein_g": recipe.protein_g,
                "carbs_g": recipe.carbs_g,
                "fat_g": recipe.fat_g,
                "image_url": recipe.image_url,
                "is_published": recipe.is_published,
                "is_vegetarian": recipe.is_vegetarian,
                "is_vegan": recipe.is_vegan,
                "food_type": recipe.food_type,
                "category": {
                    "id": str(recipe.category.id),
                    "name": recipe.category.name,
                },
                "cuisine": {
                    "id": str(recipe.cuisine.id),
                    "name": recipe.cuisine.name,
                },
                "difficulty": {
                    "id": str(recipe.difficulty.id),
                    "name": recipe.difficulty.name,
                },
                "author_id": str(recipe.author_id),
                "external_id": recipe.external_id,
                "ingredients": [],
            }
            for recipe in recipes
        ]
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )