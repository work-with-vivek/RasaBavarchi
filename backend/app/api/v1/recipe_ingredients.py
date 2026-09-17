from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.dependencies.database import get_db
from app.repositories.recipe_ingredient_repository import (
    RecipeIngredientRepository,
)
from app.repositories.recipe_repository import (
    RecipeRepository,
)
from app.schemas.recipe_ingredient import (
    RecipeIngredientCreate,
    RecipeIngredientResponse,
    RecipeIngredientUpdate,
)
from app.services.recipe_ingredient_service import (
    RecipeIngredientService,
)

router = APIRouter(
    prefix="/recipe-ingredients",
    tags=["Recipe Ingredients"],
)


@router.post(
    "/recipes/{recipe_id}",
    response_model=RecipeIngredientResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_ingredient(
    recipe_id: UUID,
    request: RecipeIngredientCreate,
    db: Session = Depends(get_db),
):
    service = RecipeIngredientService(
        RecipeRepository(db),
        RecipeIngredientRepository(db),
    )

    try:
        return service.create_ingredient(
            recipe_id,
            request,
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )


@router.get(
    "/recipes/{recipe_id}",
    response_model=list[RecipeIngredientResponse],
)
def get_ingredients(
    recipe_id: UUID,
    db: Session = Depends(get_db),
):
    service = RecipeIngredientService(
        RecipeRepository(db),
        RecipeIngredientRepository(db),
    )

    try:
        return service.get_ingredients(recipe_id)

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )


@router.put(
    "/{ingredient_id}",
    response_model=RecipeIngredientResponse,
)
def update_ingredient(
    ingredient_id: UUID,
    request: RecipeIngredientUpdate,
    db: Session = Depends(get_db),
):
    service = RecipeIngredientService(
        RecipeRepository(db),
        RecipeIngredientRepository(db),
    )

    try:
        return service.update_ingredient(
            ingredient_id,
            request,
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )


@router.delete(
    "/{ingredient_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_ingredient(
    ingredient_id: UUID,
    db: Session = Depends(get_db),
):
    service = RecipeIngredientService(
        RecipeRepository(db),
        RecipeIngredientRepository(db),
    )

    try:
        service.delete_ingredient(
            ingredient_id,
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )