from fastapi import APIRouter

from app.api.v1.ai import router as ai_router
from app.api.v1.auth import router as auth_router
from app.api.v1.categories import router as categories_router
from app.api.v1.favorites import router as favorite_router
from app.api.v1.meal_plan import router as meal_plan_router
from app.api.v1.nutrition import router as nutrition_router
from app.api.v1.pantry import router as pantry_router
from app.api.v1.recipe_ingredients import (
    router as recipe_ingredients_router,
)
from app.api.v1.recipes import router as recipes_router
from app.api.v1.recommendation import (
    router as recommendation_router,
)
from app.api.v1.reviews import router as reviews_router
from app.api.v1.ingredients import router as ingredients_router
from app.api.v1.units import router as units_router
from app.api.v1.ingredients import router as ingredients_router
api_router = APIRouter()
api_router.include_router(units_router)
api_router.include_router(ingredients_router)
api_router.include_router(auth_router)
api_router.include_router(recipes_router)
api_router.include_router(categories_router)
api_router.include_router(recipe_ingredients_router)
api_router.include_router(favorite_router)
api_router.include_router(reviews_router)
api_router.include_router(pantry_router)
api_router.include_router(ai_router)
api_router.include_router(meal_plan_router)
api_router.include_router(nutrition_router)
api_router.include_router(recommendation_router)
api_router.include_router(ingredients_router)