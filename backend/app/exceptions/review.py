from fastapi import status

from app.exceptions.base import AppException


class ReviewNotFoundError(AppException):
    def __init__(self):
        super().__init__(
            message="Review not found.",
            status_code=status.HTTP_404_NOT_FOUND,
        )


class ReviewAlreadyExistsError(AppException):
    def __init__(self):
        super().__init__(
            message="You have already reviewed this recipe.",
            status_code=status.HTTP_409_CONFLICT,
        )


class ReviewPermissionDeniedError(AppException):
    def __init__(self):
        super().__init__(
            message="You can only modify your own review.",
            status_code=status.HTTP_403_FORBIDDEN,
        )