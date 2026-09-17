from fastapi import status

from app.exceptions.base import AppException


class FavoriteAlreadyExistsError(AppException):
    def __init__(self):
        super().__init__(
            message="Recipe is already in favorites.",
            status_code=status.HTTP_409_CONFLICT,
        )


class FavoriteNotFoundError(AppException):
    def __init__(self):
        super().__init__(
            message="Favorite not found.",
            status_code=status.HTTP_404_NOT_FOUND,
        )