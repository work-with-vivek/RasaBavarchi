from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.models.email_otp import EmailOTP


class EmailOTPRepository:
    def __init__(self, db: Session):
        self.db = db

    # =====================================================
    # Get active OTP
    # =====================================================

    def get_active_otp(
        self,
        email: str,
        purpose: str,
    ) -> EmailOTP | None:
        statement = (
            select(EmailOTP)
            .where(
                EmailOTP.email == email,
                EmailOTP.purpose == purpose,
                EmailOTP.is_used.is_(False),
                EmailOTP.expires_at > datetime.now(timezone.utc),
            )
            .order_by(EmailOTP.created_at.desc())
        )

        return self.db.scalar(statement)

    # =====================================================
    # Get latest OTP
    # =====================================================

    def get_latest_otp(
        self,
        email: str,
        purpose: str,
    ) -> EmailOTP | None:
        statement = (
            select(EmailOTP)
            .where(
                EmailOTP.email == email,
                EmailOTP.purpose == purpose,
            )
            .order_by(EmailOTP.created_at.desc())
            .limit(1)
        )

        return self.db.scalar(statement)

    # =====================================================
    # Create
    # =====================================================

    def create(
        self,
        otp: EmailOTP,
    ) -> EmailOTP:
        try:
            self.db.add(otp)
            self.db.commit()
            self.db.refresh(otp)

            return otp

        except SQLAlchemyError:
            self.db.rollback()
            raise

    # =====================================================
    # Update
    # =====================================================

    def update(
        self,
        otp: EmailOTP,
    ) -> EmailOTP:
        try:
            self.db.commit()
            self.db.refresh(otp)

            return otp

        except SQLAlchemyError:
            self.db.rollback()
            raise

    # =====================================================
    # Invalidate active OTPs
    # =====================================================

    def invalidate_active_otps(
        self,
        email: str,
        purpose: str,
    ) -> None:
        try:
            statement = (
                select(EmailOTP)
                .where(
                    EmailOTP.email == email,
                    EmailOTP.purpose == purpose,
                    EmailOTP.is_used.is_(False),
                )
            )

            otps = self.db.scalars(statement).all()

            for otp in otps:
                otp.is_used = True

            self.db.commit()

        except SQLAlchemyError:
            self.db.rollback()
            raise

    # =====================================================
    # Delete
    # =====================================================

    def delete(
        self,
        otp: EmailOTP,
    ) -> None:
        try:
            self.db.delete(otp)
            self.db.commit()

        except SQLAlchemyError:
            self.db.rollback()
            raise