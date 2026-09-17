from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.meal import Meal
from app.models.meal_plan import MealPlan


class MealPlanRepository:
    def __init__(self, db: Session):
        self.db = db

    # ------------------------
    # Meal Plan
    # ------------------------

    def create(
        self,
        meal_plan: MealPlan,
    ) -> MealPlan:
        self.db.add(meal_plan)
        self.db.commit()
        self.db.refresh(meal_plan)
        return meal_plan

    def get_by_id(
        self,
        meal_plan_id: UUID,
    ) -> MealPlan | None:
        stmt = (
            select(MealPlan)
            .options(
                selectinload(
                    MealPlan.meals
                ).selectinload(
                    Meal.recipe
                )
            )
            .where(
                MealPlan.id == meal_plan_id
            )
        )

        return self.db.scalar(stmt)

    def get_by_user(
        self,
        user_id: UUID,
    ) -> list[MealPlan]:
        stmt = (
            select(MealPlan)
            .where(
                MealPlan.user_id == user_id
            )
            .order_by(
                MealPlan.created_at.desc()
            )
        )

        return list(
            self.db.scalars(stmt).all()
        )

    def update(
        self,
        meal_plan: MealPlan,
    ) -> MealPlan:
        self.db.commit()
        self.db.refresh(meal_plan)
        return meal_plan

    def delete(
        self,
        meal_plan: MealPlan,
    ) -> None:
        self.db.delete(meal_plan)
        self.db.commit()

    # ------------------------
    # Meals
    # ------------------------

    def add_meal(
        self,
        meal: Meal,
    ) -> Meal:
        self.db.add(meal)
        self.db.commit()
        self.db.refresh(meal)
        return meal

    def get_meal_by_id(
        self,
        meal_id: UUID,
    ) -> Meal | None:
        stmt = select(Meal).where(
            Meal.id == meal_id
        )

        return self.db.scalar(stmt)

    def get_meals_by_plan(
        self,
        meal_plan_id: UUID,
    ) -> list[Meal]:
        stmt = (
            select(Meal)
            .where(
                Meal.meal_plan_id == meal_plan_id
            )
            .order_by(
                Meal.meal_date,
                Meal.meal_type,
            )
        )

        return list(
            self.db.scalars(stmt).all()
        )

    def update_meal(
        self,
        meal: Meal,
    ) -> Meal:
        self.db.commit()
        self.db.refresh(meal)
        return meal

    def delete_meal(
        self,
        meal: Meal,
    ) -> None:
        self.db.delete(meal)
        self.db.commit()