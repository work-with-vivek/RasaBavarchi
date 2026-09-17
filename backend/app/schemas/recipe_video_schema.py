from pydantic import BaseModel, Field


class RecipeVideo(BaseModel):
    title: str = Field(
        ...,
        description="Video title.",
    )

    video_id: str = Field(
        ...,
        description="YouTube video ID.",
    )

    thumbnail: str = Field(
        ...,
        description="Thumbnail URL.",
    )

    channel: str = Field(
        ...,
        description="Channel name.",
    )


class RecipeVideoResponse(BaseModel):
    videos: list[RecipeVideo] = Field(
        default_factory=list,
        description="Recipe videos.",
    )