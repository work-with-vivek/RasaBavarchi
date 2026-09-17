from fastapi import status

from app.exceptions.base import AppException


class RecipeNotFoundError(AppException):
    def __init__(self):
        super().__init__(
            message="Recipe not found.",
            status_code=status.HTTP_404_NOT_FOUND,
        )


class RecipePermissionDeniedError(AppException):
    def __init__(self):
        super().__init__(
            message="You are not allowed to modify this recipe.",
            status_code=status.HTTP_403_FORBIDDEN,
        )