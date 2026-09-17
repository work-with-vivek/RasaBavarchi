from fastapi import Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.repositories.recipe_video_repository import (
    RecipeVideoRepository,
)
from app.services.recipe_video_service import (
    RecipeVideoService,
)


def get_recipe_video_service(
    db: Session = Depends(get_db),
):
    repository = RecipeVideoRepository(db)

    return RecipeVideoService(repository)