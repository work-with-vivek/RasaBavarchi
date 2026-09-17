import uuid

from fastapi import APIRouter, Depends

from app.dependencies.recipe_video import (
    get_recipe_video_service,
)
from app.schemas.recipe_video.request import RecipeVideoRequest
from app.schemas.recipe_video.response import RecipeVideoResponse
from app.services.recipe_video_service import RecipeVideoService


router = APIRouter(
    prefix="/recipes",
    tags=["Recipe Video"],
)


@router.post(
    "/{recipe_id}/explain-video",
    response_model=RecipeVideoResponse,
)
def generate_recipe_video(
    recipe_id: uuid.UUID,
    request: RecipeVideoRequest,
    service: RecipeVideoService = Depends(
        get_recipe_video_service,
    ),
):
    return service.generate_video(recipe_id)