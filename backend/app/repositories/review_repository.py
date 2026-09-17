from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.models.review import Review


class ReviewRepository:
    def __init__(
        self,
        db: Session,
    ):
        self.db = db

    # =========================================================
    # CREATE
    # =========================================================

    def create(
        self,
        review: Review,
    ) -> Review:
        self.db.add(review)
        self.db.commit()
        self.db.refresh(review)

        return self.get_by_id(review.id)

    # =========================================================
    # GET BY ID
    # =========================================================

    def get_by_id(
        self,
        review_id: UUID,
    ) -> Review | None:
        statement = (
            select(Review)
            .options(
                selectinload(Review.user),
                selectinload(Review.recipe),
            )
            .where(
                Review.id == review_id,
            )
        )

        return self.db.scalar(statement)

    # =========================================================
    # GET BY USER + RECIPE
    # =========================================================

    def get_by_user_and_recipe(
        self,
        user_id: UUID,
        recipe_id: UUID,
    ) -> Review | None:
        statement = (
            select(Review)
            .where(
                Review.user_id == user_id,
                Review.recipe_id == recipe_id,
            )
        )

        return self.db.scalar(statement)

    # =========================================================
    # GET RECIPE REVIEWS
    # =========================================================

    def get_by_recipe(
        self,
        recipe_id: UUID,
    ) -> list[Review]:
        statement = (
            select(Review)
            .options(
                selectinload(Review.user),
            )
            .where(
                Review.recipe_id == recipe_id,
            )
            .order_by(
                Review.created_at.desc(),
            )
        )

        return self.db.scalars(statement).all()

    # =========================================================
    # UPDATE
    # =========================================================

    def update(
        self,
        review: Review,
    ) -> Review:
        self.db.commit()
        self.db.refresh(review)

        return self.get_by_id(review.id)

    # =========================================================
    # DELETE
    # =========================================================

    def delete(
        self,
        review: Review,
    ) -> None:
        self.db.delete(review)
        self.db.commit()

    # =========================================================
    # AVERAGE RATING
    # =========================================================

    def get_average_rating(
        self,
        recipe_id: UUID,
    ) -> float:
        statement = (
            select(
                func.avg(Review.rating),
            )
            .where(
                Review.recipe_id == recipe_id,
            )
        )

        result = self.db.scalar(statement)

        return float(result or 0)

    # =========================================================
    # REVIEW COUNT
    # =========================================================

    def get_review_count(
        self,
        recipe_id: UUID,
    ) -> int:
        statement = (
            select(func.count())
            .select_from(Review)
            .where(
                Review.recipe_id == recipe_id,
            )
        )

        return self.db.scalar(statement) or 0