from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class PantryItemCreate(BaseModel):
    ingredient_id: UUID
    quantity: float
    unit_id: UUID
    expires_at: datetime | None = None


class PantryItemUpdate(BaseModel):
    quantity: float | None = None
    unit_id: UUID | None = None
    expires_at: datetime | None = None


class IngredientResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str


class UnitResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    symbol: str


class PantryItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID

    ingredient: IngredientResponse
    quantity: float
    unit: UnitResponse

    expires_at: datetime | None


class PantryResponse(BaseModel):
    items: list[PantryItemResponse]