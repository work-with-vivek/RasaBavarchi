from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.recipe import Recipe
from app.models.weight_loss_profile import WeightLossProfile


class WeightLossRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_user_id(
        self,
        user_id: UUID,
    ) -> WeightLossProfile | None:
        statement = select(WeightLossProfile).where(
            WeightLossProfile.user_id == user_id
        )

        return self.db.scalar(statement)

    def create(
        self,
        profile: WeightLossProfile,
    ) -> WeightLossProfile:
        self.db.add(profile)
        self.db.commit()
        self.db.refresh(profile)

        return profile

    def update(
        self,
        profile: WeightLossProfile,
    ) -> WeightLossProfile:
        self.db.commit()
        self.db.refresh(profile)

        return profile

    def get_weight_loss_recipes(
        self,
        max_calories: float,
        limit: int = 12,
        vegetarian: bool | None = None,
        vegan: bool | None = None,
    ) -> list[Recipe]:
        statement = (
            select(Recipe)
            .options(
                selectinload(Recipe.category),
                selectinload(Recipe.cuisine),
                selectinload(Recipe.difficulty),
            )
            .where(
                Recipe.is_published.is_(True),
                Recipe.calories > 0,
                Recipe.protein_g > 0,
                Recipe.carbs_g > 0,
                Recipe.fat_g > 0,
                Recipe.calories <= max_calories,
            )
        )

        if vegetarian is True:
            statement = statement.where(
                Recipe.is_vegetarian.is_(True)
                | Recipe.is_vegan.is_(True)
            )

        if vegan is True:
            statement = statement.where(
                Recipe.is_vegan.is_(True)
            )

        statement = (
            statement
            .order_by(
                Recipe.calories.asc(),
                Recipe.protein_g.desc(),
                Recipe.title.asc(),
            )
            .limit(limit)
        )

        return self.db.scalars(statement).all()