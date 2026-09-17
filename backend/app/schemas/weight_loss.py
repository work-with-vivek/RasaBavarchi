from pydantic import BaseModel, ConfigDict, Field


class WeightLossProfileCreate(BaseModel):
    age: int = Field(
        ge=13,
        le=100,
    )

    gender: str = Field(
        min_length=1,
        max_length=20,
    )

    height_cm: float = Field(
        gt=50,
        le=300,
    )

    weight_kg: float = Field(
        gt=20,
        le=500,
    )

    activity_level: str = Field(
        min_length=1,
        max_length=30,
    )

    goal_weight_kg: float = Field(
        gt=20,
        le=500,
    )


class WeightLossProfileResponse(BaseModel):
    id: str
    user_id: str
    age: int
    gender: str
    height_cm: float
    weight_kg: float
    activity_level: str
    goal_weight_kg: float

    model_config = ConfigDict(
        from_attributes=True,
    )


class WeightLossCalculationResponse(BaseModel):
    bmi: float
    bmr: float
    tdee: float
    daily_calorie_target: float
    current_weight_kg: float
    goal_weight_kg: float
    weight_to_lose_kg: float