from uuid import UUID

from app.models.recipe import Recipe
from app.models.user import User
from app.models.weight_loss_profile import WeightLossProfile
from app.repositories.weight_loss_repository import WeightLossRepository
from app.schemas.weight_loss import (
    WeightLossCalculationResponse,
    WeightLossProfileCreate,
    WeightLossProfileResponse,
)


class WeightLossService:
    def __init__(
        self,
        weight_loss_repository: WeightLossRepository,
    ):
        self.weight_loss_repository = weight_loss_repository

    # =========================================================
    # PROFILE
    # =========================================================

    def get_profile(
        self,
        user_id: UUID,
    ) -> WeightLossProfileResponse | None:
        profile = (
            self.weight_loss_repository.get_by_user_id(
                user_id
            )
        )

        if profile is None:
            return None

        return WeightLossProfileResponse(
            id=str(profile.id),
            user_id=str(profile.user_id),
            age=profile.age,
            gender=profile.gender,
            height_cm=profile.height_cm,
            weight_kg=profile.weight_kg,
            activity_level=profile.activity_level,
            goal_weight_kg=profile.goal_weight_kg,
        )

    def create_or_update_profile(
        self,
        user: User,
        profile_data: WeightLossProfileCreate,
    ) -> WeightLossProfileResponse:
        profile = (
            self.weight_loss_repository.get_by_user_id(
                user.id
            )
        )

        if profile is None:
            profile = WeightLossProfile(
                user_id=user.id,
                age=profile_data.age,
                gender=profile_data.gender.strip().lower(),
                height_cm=profile_data.height_cm,
                weight_kg=profile_data.weight_kg,
                activity_level=(
                    profile_data.activity_level
                    .strip()
                    .lower()
                ),
                goal_weight_kg=profile_data.goal_weight_kg,
            )

            profile = (
                self.weight_loss_repository.create(
                    profile
                )
            )

        else:
            profile.age = profile_data.age

            profile.gender = (
                profile_data.gender.strip().lower()
            )

            profile.height_cm = profile_data.height_cm

            profile.weight_kg = profile_data.weight_kg

            profile.activity_level = (
                profile_data.activity_level
                .strip()
                .lower()
            )

            profile.goal_weight_kg = (
                profile_data.goal_weight_kg
            )

            profile = (
                self.weight_loss_repository.update(
                    profile
                )
            )

        return WeightLossProfileResponse(
            id=str(profile.id),
            user_id=str(profile.user_id),
            age=profile.age,
            gender=profile.gender,
            height_cm=profile.height_cm,
            weight_kg=profile.weight_kg,
            activity_level=profile.activity_level,
            goal_weight_kg=profile.goal_weight_kg,
        )

    # =========================================================
    # CALCULATIONS
    # =========================================================

    def calculate(
        self,
        user_id: UUID,
    ) -> WeightLossCalculationResponse:
        profile = (
            self.weight_loss_repository.get_by_user_id(
                user_id
            )
        )

        if profile is None:
            raise ValueError(
                "Weight loss profile not found."
            )

        bmi = self._calculate_bmi(
            weight_kg=profile.weight_kg,
            height_cm=profile.height_cm,
        )

        bmr = self._calculate_bmr(
            age=profile.age,
            gender=profile.gender,
            weight_kg=profile.weight_kg,
            height_cm=profile.height_cm,
        )

        activity_multiplier = (
            self._get_activity_multiplier(
                profile.activity_level
            )
        )

        tdee = bmr * activity_multiplier

        # Moderate calorie deficit.
        daily_calorie_target = max(
            tdee - 500,
            1200,
        )

        weight_to_lose = max(
            profile.weight_kg
            - profile.goal_weight_kg,
            0,
        )

        return WeightLossCalculationResponse(
            bmi=round(bmi, 2),
            bmr=round(bmr, 2),
            tdee=round(tdee, 2),
            daily_calorie_target=round(
                daily_calorie_target,
                2,
            ),
            current_weight_kg=profile.weight_kg,
            goal_weight_kg=profile.goal_weight_kg,
            weight_to_lose_kg=round(
                weight_to_lose,
                2,
            ),
        )

    # =========================================================
    # WEIGHT LOSS RECIPES
    # =========================================================

    def get_weight_loss_recipes(
        self,
        user_id: UUID,
        vegetarian: bool | None = None,
        vegan: bool | None = None,
        limit: int = 12,
    ) -> list[Recipe]:
        profile = (
            self.weight_loss_repository.get_by_user_id(
                user_id
            )
        )

        if profile is None:
            raise ValueError(
                "Weight loss profile has not been created yet."
            )

        calculation = self.calculate(user_id)

        # Keep recommendations comfortably below the
        # estimated daily calorie target.
        #
        # This is a software recommendation heuristic,
        # not a medical prescription.
        max_recipe_calories = (
            calculation.daily_calorie_target * 0.45
        )

        return (
            self.weight_loss_repository
            .get_weight_loss_recipes(
                max_calories=max_recipe_calories,
                limit=limit,
                vegetarian=vegetarian,
                vegan=vegan,
            )
        )

    # =========================================================
    # BMI
    # =========================================================

    @staticmethod
    def _calculate_bmi(
        weight_kg: float,
        height_cm: float,
    ) -> float:
        height_m = height_cm / 100

        if height_m <= 0:
            raise ValueError(
                "Height must be greater than zero."
            )

        return weight_kg / (
            height_m * height_m
        )

    # =========================================================
    # BMR
    # =========================================================

    @staticmethod
    def _calculate_bmr(
        age: int,
        gender: str,
        weight_kg: float,
        height_cm: float,
    ) -> float:
        # Mifflin-St Jeor equation.
        base = (
            10 * weight_kg
            + 6.25 * height_cm
            - 5 * age
        )

        if gender.lower() in {
            "male",
            "m",
        }:
            return base + 5

        if gender.lower() in {
            "female",
            "f",
        }:
            return base - 161

        raise ValueError(
            "Gender must be male or female "
            "for BMR calculation."
        )

    # =========================================================
    # ACTIVITY LEVEL
    # =========================================================

    @staticmethod
    def _get_activity_multiplier(
        activity_level: str,
    ) -> float:
        levels = {
            "sedentary": 1.2,
            "light": 1.375,
            "lightly_active": 1.375,
            "moderate": 1.55,
            "moderately_active": 1.55,
            "very_active": 1.725,
            "extra_active": 1.9,
        }

        multiplier = levels.get(
            activity_level.lower()
        )

        if multiplier is None:
            raise ValueError(
                "Invalid activity level."
            )

        return multiplier