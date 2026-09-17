from fastapi import status

from app.exceptions.base import AppException


class MealPlanNotFoundError(AppException):
    def __init__(self):
        super().__init__(
            message="Meal plan not found.",
            status_code=status.HTTP_404_NOT_FOUND,
        )


class MealPlanAccessDeniedError(AppException):
    def __init__(self):
        super().__init__(
            message="You do not have permission to access this meal plan.",
            status_code=status.HTTP_403_FORBIDDEN,
        )


class MealNotFoundError(AppException):
    def __init__(self):
        super().__init__(
            message="Meal not found.",
            status_code=status.HTTP_404_NOT_FOUND,
        )


class RecipeNotFoundError(AppException):
    def __init__(self):
        super().__init__(
            message="Recipe not found.",
            status_code=status.HTTP_404_NOT_FOUND,
        )