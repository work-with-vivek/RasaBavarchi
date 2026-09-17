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
    summary="Get Recipe Recommendations",
    description="Returns recipe recommendations based on the user's pantry.",
)
def get_recommendations(
    vegetarian: bool | None = None,
    vegan: bool | None = None,
    current_user: User = Depends(get_current_user),
    service: RecommendationService = Depends(
        get_recommendation_service,
    ),
):
    return service.get_recommendations(
        user_id=current_user.id,
        vegetarian=vegetarian,
        vegan=vegan,
    )