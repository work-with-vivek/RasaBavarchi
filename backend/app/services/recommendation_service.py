from uuid import UUID

from app.repositories.recommendation_repository import (
    RecommendationRepository,
)
from app.schemas.recommendation.response import (
    RecommendationIngredientResponse,
    RecommendationItemResponse,
    RecommendationListResponse,
)


class RecommendationService:
    def __init__(
        self,
        recommendation_repository: RecommendationRepository,
    ):
        self.recommendation_repository = recommendation_repository

    def get_recommendations(
        self,
        user_id: UUID,
        vegetarian: bool | None = None,
        vegan: bool | None = None,
    ) -> RecommendationListResponse:

        pantry = self.recommendation_repository.get_user_pantry(
            user_id
        )

        if pantry is None:
            return RecommendationListResponse(
                recommendations=[]
            )

        recipes = (
            self.recommendation_repository.get_published_recipes(
                vegetarian=vegetarian,
                vegan=vegan,
            )
        )

        pantry_ingredient_ids = {
            item.ingredient_id
            for item in pantry.pantry_items
        }

        recommendations = []

        for recipe in recipes:

            available = []
            missing = []
            required_count = 0

            for recipe_ingredient in recipe.ingredients:

                if recipe_ingredient.is_optional:
                    continue

                required_count += 1

                ingredient_response = (
                    RecommendationIngredientResponse(
                        ingredient_id=recipe_ingredient.ingredient.id,
                        name=recipe_ingredient.ingredient.name,
                    )
                )

                if (
                    recipe_ingredient.ingredient_id
                    in pantry_ingredient_ids
                ):
                    available.append(
                        ingredient_response
                    )
                else:
                    missing.append(
                        ingredient_response
                    )

            if required_count == 0:
                match_percentage = 100.0
            else:
                match_percentage = round(
                    (
                        len(available)
                        / required_count
                    )
                    * 100,
                    2,
                )

            if match_percentage == 100:
                reason = (
                    "All required ingredients are available."
                )
            elif len(missing) == 1:
                reason = (
                    "Only one required ingredient is missing."
                )
            elif match_percentage >= 75:
                reason = (
                    "You have most of the required ingredients."
                )
            elif match_percentage >= 50:
                reason = (
                    "You have about half of the required ingredients."
                )
            else:
                reason = (
                    "Several required ingredients are missing."
                )

            recommendations.append(
                RecommendationItemResponse(
                    recipe_id=recipe.id,
                    title=recipe.title,
                    match_percentage=match_percentage,
                    available_ingredients=available,
                    missing_ingredients=missing,
                    reason=reason,
                )
            )

        recommendations.sort(
            key=lambda recommendation: (
                -recommendation.match_percentage,
                len(
                    recommendation.missing_ingredients
                ),
                recommendation.title.lower(),
            )
        )

        return RecommendationListResponse(
            recommendations=recommendations
        )