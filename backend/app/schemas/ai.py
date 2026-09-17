from uuid import UUID

from pydantic import BaseModel, Field
from pydantic import BaseModel, Field


class GenerateRecipeRequest(BaseModel):
    ingredients: list[str] = Field(
        ...,
        min_length=1,
        description="List of available ingredients",
    )

    cuisine: str | None = None
    dietary_preference: str | None = None

    servings: int = Field(
        default=2,
        ge=1,
        le=20,
    )


class AIIngredient(BaseModel):
    item: str
    quantity: str
    unit: str


class Nutrition(BaseModel):
    calories: int
    protein_g: float
    carbs_g: float
    fat_g: float


class GenerateRecipeResponse(BaseModel):
    recipe_name: str

    description: str

    # NEW FIELDS
    category: str
    cuisine: str
    difficulty: str

    ingredients: list[AIIngredient]

    instructions: list[str]

    prep_time_minutes: int

    cook_time_minutes: int

    servings: int

    nutrition: Nutrition


class SaveAIRecipeRequest(BaseModel):
    recipe: GenerateRecipeResponse


class ExplainRecipeRequest(BaseModel):
    question: str = Field(
        ...,
        min_length=5,
        max_length=1000,
    )


class ExplainRecipeResponse(BaseModel):
    answer: str


class IngredientSubstitutionRequest(BaseModel):
    ingredient: str
    recipe: str | None = None


class IngredientSubstitutionResponse(BaseModel):
    ingredient: str
    substitutes: list[str]
    notes: str


class GeneratePantryRecipeRequest(BaseModel):
    pantry_item_ids: list[UUID] | None = None

    cuisine: str | None = None

    dietary_preference: str | None = None

    servings: int = Field(
        default=2,
        ge=1,
        le=20,
    )

class PantryIngredient(BaseModel):
    name: str = Field(
        ...,
        description="Detected ingredient name.",
        examples=["Tomato"],
    )


class PantryScanResponse(BaseModel):
    ingredients: list[PantryIngredient] = Field(
        default_factory=list,
        description="List of detected ingredients.",
    )    