from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


# ---------------------------------------------------------
# Request Schemas
# ---------------------------------------------------------

class ReviewCreate(BaseModel):
    rating: int = Field(ge=1, le=5)
    comment: str = Field(min_length=1, max_length=2000)
    recipe_id: UUID


class ReviewUpdate(BaseModel):
    rating: int | None = Field(default=None, ge=1, le=5)
    comment: str | None = Field(default=None, min_length=1, max_length=2000)


# ---------------------------------------------------------
# Response Schemas
# ---------------------------------------------------------

class ReviewResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    recipe_id: UUID
    user_id: UUID

    rating: int
    comment: str


class ReviewListResponse(BaseModel):
    items: list[ReviewResponse]
    total: int


class RecipeRatingResponse(BaseModel):
    average_rating: float
    total_reviews: int