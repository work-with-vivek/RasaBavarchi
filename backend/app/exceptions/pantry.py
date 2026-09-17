from fastapi import status

from app.exceptions.base import AppException


class PantryItemNotFoundError(AppException):
    def __init__(self):
        super().__init__(
            message="Pantry item not found.",
            status_code=status.HTTP_404_NOT_FOUND,
        )


class PantryAccessDeniedError(AppException):
    def __init__(self):
        super().__init__(
            message="You do not have permission to access this pantry item.",
            status_code=status.HTTP_403_FORBIDDEN,
        )