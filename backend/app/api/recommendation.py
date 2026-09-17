from fastapi import APIRouter, Depends

from app.dependencies.auth import get_current_user
from app.dependencies.recommendation import (
    get_recommendation_service,
)
from app.models.user import User
from app.schemas.recommendation.response import (
    RecommendationListResponse,
)
from app.services.recommendation_service import (
    RecommendationService,
)

router = APIRouter(
    prefix="/recommendations",
    tags=["Recommendations"],
)


@router.get(
    "/",
    response_model=RecommendationListResponse,
    summary="Get recipe recommendations",
    description="Returns recipes ranked by pantry ingredient availability.",
)
def get_recommendations(
    current_user: User = Depends(get_current_user),
    service: RecommendationService = Depends(
        get_recommendation_service
    ),
):
    return service.get_recommendations(current_user.id)