from datetime import datetime, timedelta, timezone

from app.exceptions.auth import (
    AccountAlreadyVerifiedError,
    EmailAlreadyExistsError,
    EmailNotVerifiedError,
    InvalidCredentialsError,
    LoginTemporarilyLockedError,
    UsernameAlreadyExistsError,
)
from app.exceptions.base import AppException
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.auth import Token, UserRegister
from app.services.otp_service import OTPService
from app.utils.jwt import create_access_token
from app.utils.security import hash_password, verify_password


class AuthService:
    # =====================================================
    # Login Security Configuration
    # =====================================================

    MAX_FAILED_LOGIN_ATTEMPTS = 5
    LOGIN_LOCK_MINUTES = 15

    # =====================================================
    # OTP Purposes
    # =====================================================

    REGISTRATION_OTP_PURPOSE = "registration"
    FORGOT_PASSWORD_OTP_PURPOSE = "forgot_password"
    CHANGE_PASSWORD_OTP_PURPOSE = "change_password"

    # =====================================================
    # Constructor
    # =====================================================

    def __init__(
        self,
        user_repository: UserRepository,
        otp_service: OTPService | None = None,
    ):
        self.user_repository = user_repository
        self.otp_service = otp_service

    # =====================================================
    # Registration
    # =====================================================

    def register_user(
        self,
        user_data: UserRegister,
    ) -> User:
        email = user_data.email.strip().lower()
        username = user_data.username.strip()

        # Check email.
        if self.user_repository.get_by_email(email):
            raise EmailAlreadyExistsError()

        # Check username.
        if self.user_repository.get_by_username(username):
            raise UsernameAlreadyExistsError()

        # Create unverified user.
        user = User(
            email=email,
            username=username,
            hashed_password=hash_password(
                user_data.password
            ),
            is_verified=False,
        )

        created_user = self.user_repository.create(user)

        # Send registration OTP.
        if self.otp_service is not None:
            self.otp_service.send_otp(
                email=created_user.email,
                purpose=self.REGISTRATION_OTP_PURPOSE,
            )

        return created_user

    # =====================================================
    # Verify Registration OTP
    # =====================================================

    def verify_registration_otp(
        self,
        email: str,
        otp: str,
    ) -> None:
        email = email.strip().lower()

        user = self.user_repository.get_by_email(email)

        if user is None:
            raise InvalidCredentialsError()

        if user.is_verified:
            raise AccountAlreadyVerifiedError()

        if self.otp_service is None:
            raise AppException(
                message="OTP service is not available.",
                status_code=500,
            )

        self.otp_service.verify_otp(
            email=email,
            purpose=self.REGISTRATION_OTP_PURPOSE,
            otp=otp,
        )

        user.is_verified = True

        self.user_repository.update(user)

    # =====================================================
    # Resend Registration OTP
    # =====================================================

    def resend_registration_otp(
        self,
        email: str,
    ) -> None:
        email = email.strip().lower()

        user = self.user_repository.get_by_email(email)

        # Do not reveal whether the account exists.
        if user is None:
            return

        # Verified accounts do not need registration OTP.
        if user.is_verified:
            return

        if self.otp_service is None:
            raise AppException(
                message="OTP service is not available.",
                status_code=500,
            )

        # Prevent repeated OTP requests.
        if not self.otp_service.can_resend_otp(
            email=email,
            purpose=self.REGISTRATION_OTP_PURPOSE,
        ):
            raise AppException(
                message=(
                    "Please wait before requesting another "
                    "verification code."
                ),
                status_code=429,
            )

        self.otp_service.send_otp(
            email=email,
            purpose=self.REGISTRATION_OTP_PURPOSE,
        )

    # =====================================================
    # Forgot Password
    # =====================================================

    def request_password_reset(
        self,
        email: str,
    ) -> None:
        email = email.strip().lower()

        user = self.user_repository.get_by_email(email)

        # Do not reveal whether the email exists.
        if user is None:
            return

        if self.otp_service is None:
            raise AppException(
                message="OTP service is not available.",
                status_code=500,
            )

        self.otp_service.send_otp(
            email=email,
            purpose=self.FORGOT_PASSWORD_OTP_PURPOSE,
        )

    # =====================================================
    # Reset Password
    # =====================================================

    def reset_password(
        self,
        email: str,
        otp: str,
        new_password: str,
    ) -> None:
        email = email.strip().lower()

        user = self.user_repository.get_by_email(email)

        if user is None:
            raise InvalidCredentialsError()

        if self.otp_service is None:
            raise AppException(
                message="OTP service is not available.",
                status_code=500,
            )

        self.otp_service.verify_otp(
            email=email,
            purpose=self.FORGOT_PASSWORD_OTP_PURPOSE,
            otp=otp,
        )

        user.hashed_password = hash_password(
            new_password
        )

        # Reset login security state.
        user.failed_login_attempts = 0
        user.locked_until = None

        self.user_repository.update(user)

    # =====================================================
    # Request Change Password OTP
    # =====================================================

    def request_change_password_otp(
        self,
        user: User,
    ) -> None:
        if self.otp_service is None:
            raise AppException(
                message="OTP service is not available.",
                status_code=500,
            )

        email = user.email.strip().lower()

        # Prevent repeated OTP requests.
        if not self.otp_service.can_resend_otp(
            email=email,
            purpose=self.CHANGE_PASSWORD_OTP_PURPOSE,
        ):
            raise AppException(
                message=(
                    "Please wait before requesting another "
                    "verification code."
                ),
                status_code=429,
            )

        self.otp_service.send_otp(
            email=email,
            purpose=self.CHANGE_PASSWORD_OTP_PURPOSE,
        )

    # =====================================================
    # Change Password
    # =====================================================

    def change_password(
        self,
        user: User,
        otp: str,
        new_password: str,
    ) -> None:
        if self.otp_service is None:
            raise AppException(
                message="OTP service is not available.",
                status_code=500,
            )

        email = user.email.strip().lower()

        # Verify OTP first.
        self.otp_service.verify_otp(
            email=email,
            purpose=self.CHANGE_PASSWORD_OTP_PURPOSE,
            otp=otp,
        )

        # Change password.
        user.hashed_password = hash_password(
            new_password
        )

        # Reset login security state.
        user.failed_login_attempts = 0
        user.locked_until = None

        self.user_repository.update(user)

    # =====================================================
    # Login
    # =====================================================

    def login_user(
        self,
        email: str,
        password: str,
    ) -> Token:
        email = email.strip().lower()

        user = self.user_repository.get_by_email(email)

        # Do not reveal whether account exists.
        if user is None:
            raise InvalidCredentialsError()

        # Block unverified accounts.
        if not user.is_verified:
            raise EmailNotVerifiedError()

        now = datetime.now(timezone.utc)

        # =================================================
        # Check temporary lock
        # =================================================

        if user.locked_until is not None:
            if user.locked_until > now:
                raise LoginTemporarilyLockedError()

            # Lock expired.
            user.failed_login_attempts = 0
            user.locked_until = None

        # =================================================
        # Verify password
        # =================================================

        if not verify_password(
            password,
            user.hashed_password,
        ):
            user.failed_login_attempts += 1

            if (
                user.failed_login_attempts
                >= self.MAX_FAILED_LOGIN_ATTEMPTS
            ):
                user.locked_until = (
                    now
                    + timedelta(
                        minutes=self.LOGIN_LOCK_MINUTES
                    )
                )

                user.failed_login_attempts = (
                    self.MAX_FAILED_LOGIN_ATTEMPTS
                )

                self.user_repository.update(user)

                raise LoginTemporarilyLockedError()

            self.user_repository.update(user)

            raise InvalidCredentialsError()

        # =================================================
        # Successful login
        # =================================================

        user.failed_login_attempts = 0
        user.locked_until = None

        self.user_repository.update(user)

        access_token = create_access_token(
            {
                "sub": str(user.id),
            }
        )

        return Token(
            access_token=access_token,
            token_type="bearer",
        )