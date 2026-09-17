from pydantic import BaseModel, ConfigDict


class ShoppingItemResponse(BaseModel):
    ingredient: str
    quantity: float
    unit: str


class ShoppingListResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    meal_plan_id: str
    meal_plan_name: str

    items: list[ShoppingItemResponse]