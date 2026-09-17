from uuid import UUID

from pydantic import BaseModel, ConfigDict


class RecommendationIngredientResponse(BaseModel):
    ingredient_id: UUID
    name: str

    model_config = ConfigDict(from_attributes=True)


class RecommendationItemResponse(BaseModel):
    recipe_id: UUID
    title: str
    match_percentage: float
    available_ingredients: list[RecommendationIngredientResponse]
    missing_ingredients: list[RecommendationIngredientResponse]
    reason: str

    model_config = ConfigDict(from_attributes=True)


class RecommendationListResponse(BaseModel):
    recommendations: list[RecommendationItemResponse]