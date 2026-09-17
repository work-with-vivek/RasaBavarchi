from pydantic import BaseModel, ConfigDict


class NutritionSummary(BaseModel):
    calories: float = 0
    protein_g: float = 0
    carbs_g: float = 0
    fat_g: float = 0


class MealNutritionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    breakfast: NutritionSummary
    lunch: NutritionSummary
    dinner: NutritionSummary
    snack: NutritionSummary
    total: NutritionSummary


class RecipeNutritionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    recipe_id: str
    recipe_name: str

    calories: float
    protein_g: float
    carbs_g: float
    fat_g: float