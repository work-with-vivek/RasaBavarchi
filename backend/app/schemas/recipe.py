from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.common import (
    CategoryInfo,
    CuisineInfo,
    DifficultyInfo,
)


# ---------------------------------------------------------
# Request Schemas
# ---------------------------------------------------------


class RecipeCreate(BaseModel):
    title: str = Field(min_length=3, max_length=200)
    description: str
    instructions: str

    prep_time: int = Field(gt=0)
    cook_time: int = Field(gt=0)
    servings: int = Field(gt=0)

    image_url: str | None = None

    is_published: bool = False
    is_vegetarian: bool = False
    is_vegan: bool = False

    category_id: UUID
    cuisine_id: UUID
    difficulty_id: UUID


class RecipeUpdate(BaseModel):
    title: str | None = Field(
        default=None,
        min_length=3,
        max_length=200,
    )

    description: str | None = None
    instructions: str | None = None

    prep_time: int | None = Field(
        default=None,
        gt=0,
    )

    cook_time: int | None = Field(
        default=None,
        gt=0,
    )

    servings: int | None = Field(
        default=None,
        gt=0,
    )

    image_url: str | None = None

    is_published: bool | None = None
    is_vegetarian: bool | None = None
    is_vegan: bool | None = None

    category_id: UUID | None = None
    cuisine_id: UUID | None = None
    difficulty_id: UUID | None = None


# ---------------------------------------------------------
# Nested Response Schemas
# ---------------------------------------------------------


class IngredientInfo(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    image_url: str | None = None


class UnitInfo(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    symbol: str


class RecipeIngredientResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID

    ingredient: IngredientInfo

    quantity: float

    unit: UnitInfo

    is_optional: bool


# ---------------------------------------------------------
# Recipe Response
# ---------------------------------------------------------


class RecipeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID

    title: str
    description: str
    instructions: str

    prep_time: int
    cook_time: int
    servings: int

    calories: float
    protein_g: float
    carbs_g: float
    fat_g: float

    image_url: str | None

    is_published: bool
    is_vegetarian: bool
    is_vegan: bool

    # -----------------------------------------------------
    # Food Classification
    # -----------------------------------------------------
    #
    # Source of truth:
    # recipes.food_type
    #
    # Possible values:
    # VEGAN
    # VEGETARIAN
    # NON_VEGETARIAN
    # UNKNOWN
    #
    # This value is calculated from the ingredient
    # classifications by the classification pipeline.
    # -----------------------------------------------------

    food_type: str

    category: CategoryInfo
    cuisine: CuisineInfo
    difficulty: DifficultyInfo

    author_id: UUID
    external_id: int | None = None

    ingredients: list[RecipeIngredientResponse] = []