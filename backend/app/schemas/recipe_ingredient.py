from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, Field


# ---------------------------------------------------------
# Create
# ---------------------------------------------------------

class RecipeIngredientCreate(BaseModel):
    ingredient_id: UUID

    quantity: Decimal = Field(
        ...,
        gt=0,
    )

    unit_id: UUID

    is_optional: bool = False


# ---------------------------------------------------------
# Update
# ---------------------------------------------------------

class RecipeIngredientUpdate(BaseModel):
    ingredient_id: UUID | None = None

    quantity: Decimal | None = Field(
        default=None,
        gt=0,
    )

    unit_id: UUID | None = None

    is_optional: bool | None = None


# ---------------------------------------------------------
# Response
# ---------------------------------------------------------

class RecipeIngredientResponse(BaseModel):
    id: UUID
    recipe_id: UUID

    ingredient_id: UUID
    quantity: Decimal
    unit_id: UUID
    is_optional: bool

    created_at: datetime
    updated_at: datetime

    model_config = {
        "from_attributes": True,
    }