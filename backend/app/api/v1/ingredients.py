from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.dependencies.database import get_db
from app.repositories.ingredient_repository import IngredientRepository
from app.schemas.ingredient import IngredientResponse

router = APIRouter(
    prefix="/ingredients",
    tags=["Ingredients"],
)


def get_ingredient_repository(
    db: Session = Depends(get_db),
) -> IngredientRepository:
    return IngredientRepository(db)


@router.get(
    "/search",
    response_model=list[IngredientResponse],
)
def search_ingredients(
    name: str = Query(
        ...,
        min_length=1,
        max_length=100,
    ),
    limit: int = Query(
        default=10,
        ge=1,
        le=50,
    ),
    repository: IngredientRepository = Depends(
        get_ingredient_repository,
    ),
):
    return repository.search_by_name(
        name=name,
        limit=limit,
    )


@router.get(
    "/by-name",
    response_model=IngredientResponse,
)
def get_ingredient_by_name(
    name: str = Query(
        ...,
        min_length=1,
        max_length=100,
    ),
    repository: IngredientRepository = Depends(
        get_ingredient_repository,
    ),
):
    ingredient = repository.get_by_name(name)

    if ingredient is None:
        raise HTTPException(
            status_code=404,
            detail=f"Ingredient '{name}' not found.",
        )

    return ingredient