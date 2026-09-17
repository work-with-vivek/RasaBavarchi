from pydantic import BaseModel


class RecipeVideoResponse(BaseModel):
    status: str
    video_url: str | None
    duration: int | None
    message: str