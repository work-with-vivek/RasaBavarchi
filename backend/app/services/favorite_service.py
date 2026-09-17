from fastapi import HTTPException, status

from app.models.favorite import Favorite
from app.models.user import User
from app.repositories.favorite_repository import FavoriteRepository
from app.schemas.favorite import (
    FavoriteCreate,
    FavoriteListResponse,
    FavoriteResponse,
    FavoriteStatusResponse,
)


class FavoriteService:
    def __init__(
        self,
        favorite_repository: FavoriteRepository,
    ):
        self.favorite_repository = favorite_repository

    # ---------------------------------------------------------
    # Add Favorite
    # ---------------------------------------------------------

    def add_favorite(
        self,
        request: FavoriteCreate,
        current_user: User,
    ) -> FavoriteResponse:

        if self.favorite_repository.exists(
            current_user.id,
            request.recipe_id,
        ):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Recipe is already in favorites.",
            )

        favorite = Favorite(
            user_id=current_user.id,
            recipe_id=request.recipe_id,
        )

        favorite = self.favorite_repository.create(
            favorite,
        )

        return FavoriteResponse.model_validate(
            favorite,
        )

    # ---------------------------------------------------------
    # Remove Favorite
    # ---------------------------------------------------------

    def remove_favorite(
        self,
        recipe_id,
        current_user: User,
    ) -> None:

        favorite = self.favorite_repository.get_by_user_and_recipe(
            current_user.id,
            recipe_id,
        )

        if favorite is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Favorite not found.",
            )

        self.favorite_repository.delete(
            favorite,
        )

    # ---------------------------------------------------------
    # List Favorites
    # ---------------------------------------------------------

    def get_my_favorites(
        self,
        current_user: User,
    ) -> FavoriteListResponse:

        favorites = self.favorite_repository.get_user_favorites(
            current_user.id,
        )

        return FavoriteListResponse(
            items=[
                FavoriteResponse.model_validate(
                    favorite,
                )
                for favorite in favorites
            ],
            total=len(favorites),
        )

    # ---------------------------------------------------------
    # Favorite Status
    # ---------------------------------------------------------

    def is_favorite(
        self,
        recipe_id,
        current_user: User,
    ) -> FavoriteStatusResponse:

        exists = self.favorite_repository.exists(
            current_user.id,
            recipe_id,
        )

        return FavoriteStatusResponse(
            is_favorite=exists,
        )

    # ---------------------------------------------------------
    # Favorite Count
    # ---------------------------------------------------------

    def get_my_favorite_count(
        self,
        current_user: User,
    ) -> int:

        return self.favorite_repository.count_user_favorites(
            current_user.id,
        )