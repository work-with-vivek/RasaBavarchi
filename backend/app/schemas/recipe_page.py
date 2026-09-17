from pydantic import BaseModel

from app.schemas.pagination import PaginationResponse
from app.schemas.recipe import RecipeResponse


class RecipePageResponse(PaginationResponse):
    items: list[RecipeResponse]