from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


# =========================================================
# CREATE POST
# =========================================================


class CommunityPostCreate(BaseModel):
    content: str = Field(
        min_length=1,
        max_length=5000,
    )

    recipe_id: UUID | None = None


# =========================================================
# CREATE COMMENT
# =========================================================


class CommunityCommentCreate(BaseModel):
    content: str = Field(
        min_length=1,
        max_length=2000,
    )


# =========================================================
# AUTHOR
# =========================================================


class CommunityAuthorResponse(BaseModel):
    id: UUID
    username: str


# =========================================================
# RECIPE SUMMARY
# =========================================================


class CommunityRecipeResponse(BaseModel):
    id: UUID
    title: str
    image_url: str | None = None


# =========================================================
# COMMENT RESPONSE
# =========================================================


class CommunityCommentResponse(BaseModel):
    id: UUID
    content: str
    author: CommunityAuthorResponse
    created_at: datetime

    model_config = ConfigDict(
        from_attributes=True,
    )


# =========================================================
# POST RESPONSE
# =========================================================


class CommunityPostResponse(BaseModel):
    id: UUID
    content: str
    author: CommunityAuthorResponse
    recipe: CommunityRecipeResponse | None = None

    like_count: int
    comment_count: int
    is_liked: bool

    created_at: datetime
    updated_at: datetime


# =========================================================
# POST DETAIL RESPONSE
# =========================================================


class CommunityPostDetailResponse(CommunityPostResponse):
    comments: list[CommunityCommentResponse]