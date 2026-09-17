from datetime import date
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class MealCreate(BaseModel):
    recipe_id: UUID
    meal_date: date
    meal_type: str = Field(
        pattern="^(Breakfast|Lunch|Dinner|Snack)$"
    )
    notes: str | None = None


class MealResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    recipe_id: UUID
    meal_date: date
    meal_type: str
    notes: str | None


class MealPlanCreate(BaseModel):
    name: str = Field(
        min_length=2,
        max_length=100,
    )
    description: str | None = Field(
        default=None,
        max_length=500,
    )


class MealPlanUpdate(BaseModel):
    name: str | None = Field(
        default=None,
        min_length=2,
        max_length=100,
    )
    description: str | None = Field(
        default=None,
        max_length=500,
    )


class MealPlanResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    description: str | None
    user_id: UUID
    meals: list[MealResponse]