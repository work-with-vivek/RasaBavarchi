from fastapi import status

from app.exceptions.base import AppException


class EmailAlreadyExistsError(AppException):
    def __init__(self):
        super().__init__(
            message="Email already exists.",
            status_code=status.HTTP_409_CONFLICT,
        )


class UsernameAlreadyExistsError(AppException):
    def __init__(self):
        super().__init__(
            message="Username already exists.",
            status_code=status.HTTP_409_CONFLICT,
        )


class InvalidCredentialsError(AppException):
    def __init__(self):
        super().__init__(
            message="Invalid email or password.",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )


class LoginTemporarilyLockedError(AppException):
    def __init__(self):
        super().__init__(
            message=(
                "Too many failed login attempts. "
                "Please try again later."
            ),
            status_code=status.HTTP_401_UNAUTHORIZED,
        )


class AccountAlreadyVerifiedError(AppException):
    def __init__(self):
        super().__init__(
            message="Account is already verified.",
            status_code=status.HTTP_400_BAD_REQUEST,
        )


class EmailNotVerifiedError(AppException):
    def __init__(self):
        super().__init__(
            message="Email address is not verified.",
            status_code=status.HTTP_403_FORBIDDEN,
        )