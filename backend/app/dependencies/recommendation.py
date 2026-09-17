from fastapi import Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.repositories.recommendation_repository import RecommendationRepository
from app.services.recommendation_service import RecommendationService


def get_recommendation_service(
    db: Session = Depends(get_db),
) -> RecommendationService:
    repository = RecommendationRepository(db)
    return RecommendationService(repository)