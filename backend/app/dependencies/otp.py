from fastapi import Depends
from sqlalchemy.orm import Session

from app.dependencies.database import get_db
from app.repositories.email_otp_repository import EmailOTPRepository
from app.services.otp_service import OTPService


def get_otp_service(
    db: Session = Depends(get_db),
) -> OTPService:
    repository = EmailOTPRepository(db)

    return OTPService(repository)