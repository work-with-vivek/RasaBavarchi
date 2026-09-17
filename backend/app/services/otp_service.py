import secrets
from datetime import datetime, timedelta, timezone

from app.exceptions.base import AppException
from app.models.email_otp import EmailOTP
from app.repositories.email_otp_repository import EmailOTPRepository
from app.services.email_service import send_email
from app.utils.security import hash_password, verify_password


# =========================================================
# OTP Configuration
# =========================================================

OTP_EXPIRATION_MINUTES = 10
MAX_OTP_ATTEMPTS = 5
RESEND_COOLDOWN_SECONDS = 60


# =========================================================
# OTP Exceptions
# =========================================================


class InvalidOTPError(AppException):
    def __init__(self):
        super().__init__(
            message="Invalid or expired verification code.",
            status_code=400,
        )


class OTPTooManyAttemptsError(AppException):
    def __init__(self):
        super().__init__(
            message=(
                "Too many incorrect verification attempts. "
                "Please request a new code."
            ),
            status_code=400,
        )


# =========================================================
# OTP Service
# =========================================================


class OTPService:
    def __init__(
        self,
        repository: EmailOTPRepository,
    ):
        self.repository = repository

    # =====================================================
    # Generate OTP
    # =====================================================

    def generate_otp(self) -> str:
        return f"{secrets.randbelow(1_000_000):06d}"

    # =====================================================
    # Check Resend Cooldown
    # =====================================================

    def can_resend_otp(
        self,
        email: str,
        purpose: str,
    ) -> bool:
        email = email.strip().lower()

        latest_otp = self.repository.get_latest_otp(
            email=email,
            purpose=purpose,
        )

        if latest_otp is None:
            return True

        now = datetime.now(timezone.utc)

        elapsed_seconds = (
            now - latest_otp.created_at
        ).total_seconds()

        return elapsed_seconds >= RESEND_COOLDOWN_SECONDS

    # =====================================================
    # Send OTP
    # =====================================================

    def send_otp(
        self,
        email: str,
        purpose: str,
    ) -> None:
        email = email.strip().lower()

        # Invalidate previous active OTPs.
        self.repository.invalidate_active_otps(
            email=email,
            purpose=purpose,
        )

        # Generate new OTP.
        otp = self.generate_otp()

        # Create OTP database record.
        otp_record = EmailOTP(
            email=email,
            purpose=purpose,
            otp_hash=hash_password(otp),
            expires_at=(
                datetime.now(timezone.utc)
                + timedelta(minutes=OTP_EXPIRATION_MINUTES)
            ),
            attempts=0,
            is_used=False,
        )

        self.repository.create(otp_record)

        # Email content.
        subject = "Your RasaBavarchi verification code"

        body = (
            "Hello,\n\n"
            f"Your RasaBavarchi verification code is: {otp}\n\n"
            "This code will expire in 10 minutes.\n\n"
            "If you did not request this code, please ignore this email.\n\n"
            "Regards,\n"
            "RasaBavarchi"
        )

        send_email(
            recipient=email,
            subject=subject,
            body=body,
        )

    # =====================================================
    # Verify OTP
    # =====================================================

    def verify_otp(
        self,
        email: str,
        purpose: str,
        otp: str,
    ) -> None:
        email = email.strip().lower()
        otp = otp.strip()

        otp_record = self.repository.get_active_otp(
            email=email,
            purpose=purpose,
        )

        if otp_record is None:
            raise InvalidOTPError()

        # Protect against excessive attempts.
        if otp_record.attempts >= MAX_OTP_ATTEMPTS:
            raise OTPTooManyAttemptsError()

        # Verify code.
        if not verify_password(
            otp,
            otp_record.otp_hash,
        ):
            otp_record.attempts += 1

            if otp_record.attempts >= MAX_OTP_ATTEMPTS:
                otp_record.is_used = True

                self.repository.update(otp_record)

                raise OTPTooManyAttemptsError()

            self.repository.update(otp_record)

            raise InvalidOTPError()

        # OTP successfully verified.
        otp_record.is_used = True

        self.repository.update(otp_record)