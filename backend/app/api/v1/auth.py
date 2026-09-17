from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.dependencies.auth import get_current_user
from app.dependencies.database import get_db
from app.dependencies.otp import get_otp_service
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.auth import (
    ChangePasswordRequest,
    ForgotPasswordRequest,
    MessageResponse,
    ResendRegistrationOTP,
    ResetPassword,
    Token,
    UserLogin,
    UserRegister,
    UserResponse,
    VerifyRegistrationOTP,
)
from app.services.auth_service import AuthService
from app.services.otp_service import OTPService


router = APIRouter(
    prefix="/auth",
    tags=["Authentication"],
)


# =========================================================
# Registration
# =========================================================


@router.post(
    "/register",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
)
def register(
    user: UserRegister,
    db: Session = Depends(get_db),
    otp_service: OTPService = Depends(get_otp_service),
):
    repository = UserRepository(db)

    service = AuthService(
        user_repository=repository,
        otp_service=otp_service,
    )

    try:
        service.register_user(user)

        return MessageResponse(
            message="Verification code sent to your email.",
        )

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


# =========================================================
# Verify Registration OTP
# =========================================================


@router.post(
    "/register/verify",
    response_model=MessageResponse,
)
def verify_registration(
    data: VerifyRegistrationOTP,
    db: Session = Depends(get_db),
    otp_service: OTPService = Depends(get_otp_service),
):
    repository = UserRepository(db)

    service = AuthService(
        user_repository=repository,
        otp_service=otp_service,
    )

    try:
        service.verify_registration_otp(
            email=data.email,
            otp=data.otp,
        )

        return MessageResponse(
            message="Email verified successfully.",
        )

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


# =========================================================
# Resend Registration OTP
# =========================================================


@router.post(
    "/register/resend-otp",
    response_model=MessageResponse,
)
def resend_registration_otp(
    data: ResendRegistrationOTP,
    db: Session = Depends(get_db),
    otp_service: OTPService = Depends(get_otp_service),
):
    repository = UserRepository(db)

    service = AuthService(
        user_repository=repository,
        otp_service=otp_service,
    )

    service.resend_registration_otp(
        email=data.email,
    )

    return MessageResponse(
        message=(
            "If the account is eligible, "
            "a new verification code has been sent."
        ),
    )


# =========================================================
# Forgot Password
# =========================================================


@router.post(
    "/forgot-password",
    response_model=MessageResponse,
)
def forgot_password(
    data: ForgotPasswordRequest,
    db: Session = Depends(get_db),
    otp_service: OTPService = Depends(get_otp_service),
):
    repository = UserRepository(db)

    service = AuthService(
        user_repository=repository,
        otp_service=otp_service,
    )

    try:
        service.request_password_reset(
            email=data.email,
        )

        return MessageResponse(
            message=(
                "If an account exists with this email, "
                "a verification code has been sent."
            ),
        )

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


# =========================================================
# Reset Password
# =========================================================


@router.post(
    "/reset-password",
    response_model=MessageResponse,
)
def reset_password(
    data: ResetPassword,
    db: Session = Depends(get_db),
    otp_service: OTPService = Depends(get_otp_service),
):
    repository = UserRepository(db)

    service = AuthService(
        user_repository=repository,
        otp_service=otp_service,
    )

    try:
        service.reset_password(
            email=data.email,
            otp=data.otp,
            new_password=data.new_password,
        )

        return MessageResponse(
            message="Password reset successfully.",
        )

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
# =========================================================
# Change Password - Request OTP
# =========================================================


@router.post(
    "/change-password/request-otp",
    response_model=MessageResponse,
)
def request_change_password_otp(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    otp_service: OTPService = Depends(get_otp_service),
):
    repository = UserRepository(db)

    service = AuthService(
        user_repository=repository,
        otp_service=otp_service,
    )

    service.request_change_password_otp(
        user=current_user,
    )

    return MessageResponse(
        message="A verification code has been sent to your email.",
    )
# =========================================================
# Change Password
# =========================================================


@router.post(
    "/change-password",
    response_model=MessageResponse,
)
def change_password(
    data: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    otp_service: OTPService = Depends(get_otp_service),
):
    repository = UserRepository(db)

    service = AuthService(
        user_repository=repository,
        otp_service=otp_service,
    )

    service.change_password(
        user=current_user,
        otp=data.otp,
        new_password=data.new_password,
    )

    return MessageResponse(
        message="Password changed successfully.",
    )
# =========================================================
# Login
# =========================================================


@router.post(
    "/login",
    response_model=Token,
)
def login(
    user: UserLogin,
    db: Session = Depends(get_db),
):
    repository = UserRepository(db)

    service = AuthService(repository)

    try:
        return service.login_user(
            user.email,
            user.password,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )


# =========================================================
# Current User
# =========================================================


@router.get(
    "/me",
    response_model=UserResponse,
)
def get_me(
    current_user: User = Depends(get_current_user),
):
    return current_user