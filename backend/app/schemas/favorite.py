from uuid import UUID

from pydantic import BaseModel, ConfigDict


class FavoriteCreate(BaseModel):
    recipe_id: UUID


class FavoriteResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    recipe_id: UUID


class FavoriteStatusResponse(BaseModel):
    is_favorite: bool


class FavoriteListResponse(BaseModel):
    items: list[FavoriteResponse]
    total: int