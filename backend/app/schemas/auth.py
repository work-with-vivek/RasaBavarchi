from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


# =========================================================
# Registration
# =========================================================


class UserRegister(BaseModel):
    email: EmailStr
    username: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=8)


class VerifyRegistrationOTP(BaseModel):
    email: EmailStr
    otp: str = Field(min_length=6, max_length=6)


class ResendRegistrationOTP(BaseModel):
    email: EmailStr


# =========================================================
# Login
# =========================================================


class UserLogin(BaseModel):
    email: EmailStr
    password: str


# =========================================================
# Forgot Password
# =========================================================


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class VerifyForgotPasswordOTP(BaseModel):
    email: EmailStr
    otp: str = Field(min_length=6, max_length=6)


class ResetPassword(BaseModel):
    email: EmailStr
    otp: str = Field(min_length=6, max_length=6)
    new_password: str = Field(min_length=8)


# =========================================================
# Change Password
# =========================================================


class ChangePasswordRequest(BaseModel):
    otp: str = Field(min_length=6, max_length=6)
    new_password: str = Field(min_length=8)


# =========================================================
# Authentication Response
# =========================================================


class Token(BaseModel):
    access_token: str
    token_type: str


class TokenPayload(BaseModel):
    sub: str


# =========================================================
# User Response
# =========================================================


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    email: EmailStr
    username: str
    is_active: bool
    is_verified: bool


# =========================================================
# Generic Message Response
# =========================================================


class MessageResponse(BaseModel):
    message: str