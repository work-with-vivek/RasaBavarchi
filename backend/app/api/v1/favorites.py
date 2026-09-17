from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.dependencies.auth import get_current_user
from app.dependencies.database import get_db
from app.models.user import User
from app.repositories.favorite_repository import FavoriteRepository
from app.schemas.favorite import (
    FavoriteCreate,
    FavoriteListResponse,
    FavoriteResponse,
    FavoriteStatusResponse,
)
from app.services.favorite_service import FavoriteService

router = APIRouter(
    prefix="/favorites",
    tags=["Favorites"],
)


def get_favorite_service(
    db: Session = Depends(get_db),
) -> FavoriteService:
    return FavoriteService(
        FavoriteRepository(db),
    )


# ---------------------------------------------------------
# Add Favorite
# ---------------------------------------------------------

@router.post(
    "",
    response_model=FavoriteResponse,
    status_code=status.HTTP_201_CREATED,
)
def add_favorite(
    favorite: FavoriteCreate,
    current_user: User = Depends(get_current_user),
    service: FavoriteService = Depends(get_favorite_service),
):
    return service.add_favorite(
        favorite,
        current_user,
    )


# ---------------------------------------------------------
# My Favorites
# ---------------------------------------------------------

@router.get(
    "",
    response_model=FavoriteListResponse,
)
def get_my_favorites(
    current_user: User = Depends(get_current_user),
    service: FavoriteService = Depends(get_favorite_service),
):
    return service.get_my_favorites(
        current_user,
    )


# ---------------------------------------------------------
# Favorite Count
# ---------------------------------------------------------

@router.get(
    "/count",
)
def get_my_favorite_count(
    current_user: User = Depends(get_current_user),
    service: FavoriteService = Depends(get_favorite_service),
):
    return {
        "total": service.get_my_favorite_count(
            current_user,
        )
    }


# ---------------------------------------------------------
# Favorite Status
# ---------------------------------------------------------

@router.get(
    "/{recipe_id}",
    response_model=FavoriteStatusResponse,
)
def is_favorite(
    recipe_id: UUID,
    current_user: User = Depends(get_current_user),
    service: FavoriteService = Depends(get_favorite_service),
):
    return service.is_favorite(
        recipe_id,
        current_user,
    )


# ---------------------------------------------------------
# Remove Favorite
# ---------------------------------------------------------

@router.delete(
    "/{recipe_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def remove_favorite(
    recipe_id: UUID,
    current_user: User = Depends(get_current_user),
    service: FavoriteService = Depends(get_favorite_service),
):
    service.remove_favorite(
        recipe_id,
        current_user,
    )