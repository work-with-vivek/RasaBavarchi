from pydantic import BaseModel


class RecommendationFilterRequest(BaseModel):
    min_match: float = 0
    vegetarian: bool | None = None
    vegan: bool |None = None