from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.dependencies.auth import get_current_user
from app.dependencies.database import get_db
from app.models.user import User
from app.repositories.recipe_repository import RecipeRepository
from app.schemas.recipe import (
    RecipeCreate,
    RecipeResponse,
    RecipeUpdate,
)
from app.schemas.recipe_page import RecipePageResponse
from app.services.recipe_service import RecipeService

router = APIRouter(
    prefix="/recipes",
    tags=["Recipes"],
)


def get_recipe_service(
    db: Session = Depends(get_db),
) -> RecipeService:
    return RecipeService(
        RecipeRepository(db),
    )


# ---------------------------------------------------------
# Create Recipe
# ---------------------------------------------------------


@router.post(
    "",
    response_model=RecipeResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_recipe(
    recipe: RecipeCreate,
    current_user: User = Depends(get_current_user),
    service: RecipeService = Depends(get_recipe_service),
):
    return service.create_recipe(
        recipe,
        current_user,
    )


# ---------------------------------------------------------
# List Recipes
# ---------------------------------------------------------


@router.get(
    "",
    response_model=RecipePageResponse,
)
def get_recipes(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=10, ge=1, le=100),
    sort_by: str = Query(default="random"),
    order: str = Query(default="asc"),
    category_id: UUID | None = None,
    cuisine_id: UUID | None = None,
    difficulty_id: UUID | None = None,
    vegetarian: bool | None = None,
    vegan: bool | None = None,
    food_type: str | None = Query(
        default=None,
        description=(
            "Filter recipes by food classification. "
            "Supported values: VEGAN, VEGETARIAN, NON_VEGETARIAN."
        ),
    ),
    service: RecipeService = Depends(get_recipe_service),
):
    return service.get_recipe_page(
        page=page,
        page_size=page_size,
        sort_by=sort_by,
        order=order,
        category_id=category_id,
        cuisine_id=cuisine_id,
        difficulty_id=difficulty_id,
        vegetarian=vegetarian,
        vegan=vegan,
        food_type=food_type,
    )


# ---------------------------------------------------------
# Recipe Count
# ---------------------------------------------------------


@router.get(
    "/count",
)
def get_recipe_count(
    service: RecipeService = Depends(get_recipe_service),
):
    return {
        "total": service.get_recipe_count(),
    }


# ---------------------------------------------------------
# Search Recipes
# ---------------------------------------------------------


@router.get(
    "/search",
    response_model=list[RecipeResponse],
)
def search_recipes(
    title: str | None = None,
    category_id: UUID | None = None,
    cuisine_id: UUID | None = None,
    difficulty_id: UUID | None = None,
    vegetarian: bool | None = None,
    food_type: str | None = Query(
        default=None,
        description=(
            "Filter recipes by food classification. "
            "Supported values: VEGAN, VEGETARIAN, NON_VEGETARIAN."
        ),
    ),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=10, ge=1, le=100),
    service: RecipeService = Depends(get_recipe_service),
):
    return service.search_recipes(
        title=title,
        category_id=category_id,
        cuisine_id=cuisine_id,
        difficulty_id=difficulty_id,
        vegetarian=vegetarian,
        food_type=food_type,
        page=page,
        page_size=page_size,
    )


# ---------------------------------------------------------
# Get Recipe By ID
# ---------------------------------------------------------


@router.get(
    "/{recipe_id}",
    response_model=RecipeResponse,
)
def get_recipe(
    recipe_id: UUID,
    service: RecipeService = Depends(get_recipe_service),
):
    return service.get_recipe(
        recipe_id,
    )


# ---------------------------------------------------------
# Update Recipe
# ---------------------------------------------------------


@router.put(
    "/{recipe_id}",
    response_model=RecipeResponse,
)
def update_recipe(
    recipe_id: UUID,
    recipe: RecipeUpdate,
    current_user: User = Depends(get_current_user),
    service: RecipeService = Depends(get_recipe_service),
):
    return service.update_recipe(
        recipe_id,
        recipe,
        current_user,
    )


# ---------------------------------------------------------
# Delete Recipe
# ---------------------------------------------------------


@router.delete(
    "/{recipe_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_recipe(
    recipe_id: UUID,
    current_user: User = Depends(get_current_user),
    service: RecipeService = Depends(get_recipe_service),
):
    service.delete_recipe(
        recipe_id,
        current_user,
    )