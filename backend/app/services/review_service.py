from uuid import UUID

from app.models.review import Review
from app.models.user import User
from app.repositories.recipe_repository import RecipeRepository
from app.repositories.review_repository import ReviewRepository
from app.schemas.review import (
    ReviewCreate,
    ReviewUpdate,
)


class ReviewService:
    def __init__(
        self,
        review_repository: ReviewRepository,
        recipe_repository: RecipeRepository,
    ):
        self.review_repository = review_repository
        self.recipe_repository = recipe_repository

    # =========================================================
    # CREATE REVIEW
    # =========================================================

    def create_review(
        self,
        recipe_id: UUID,
        request: ReviewCreate,
        current_user: User,
    ):
        recipe = self.recipe_repository.get_by_id(recipe_id)

        if recipe is None:
            raise ValueError("Recipe not found")

        existing = self.review_repository.get_by_user_and_recipe(
            current_user.id,
            recipe_id,
        )

        if existing:
            raise ValueError(
                "You have already reviewed this recipe."
            )

        review = Review(
            rating=request.rating,
            comment=request.comment,
            user_id=current_user.id,
            recipe_id=recipe_id,
        )

        return self.review_repository.create(review)

    # =========================================================
    # GET REVIEWS
    # =========================================================

    def get_reviews(
        self,
        recipe_id: UUID,
    ):
        recipe = self.recipe_repository.get_by_id(recipe_id)

        if recipe is None:
            raise ValueError("Recipe not found")

        return self.review_repository.get_by_recipe(recipe_id)

    # =========================================================
    # UPDATE REVIEW
    # =========================================================

    def update_review(
        self,
        review_id: UUID,
        request: ReviewUpdate,
        current_user: User,
    ):
        review = self.review_repository.get_by_id(review_id)

        if review is None:
            raise ValueError("Review not found")

        if review.user_id != current_user.id:
            raise PermissionError(
                "You can only update your own review."
            )

        if request.rating is not None:
            review.rating = request.rating

        if request.comment is not None:
            review.comment = request.comment

        return self.review_repository.update(review)

    # =========================================================
    # DELETE REVIEW
    # =========================================================

    def delete_review(
        self,
        review_id: UUID,
        current_user: User,
    ):
        review = self.review_repository.get_by_id(review_id)

        if review is None:
            raise ValueError("Review not found")

        if review.user_id != current_user.id:
            raise PermissionError(
                "You can only delete your own review."
            )

        self.review_repository.delete(review)

    # =========================================================
    # GET RATING SUMMARY
    # =========================================================

    def get_rating_summary(
        self,
        recipe_id: UUID,
    ):
        recipe = self.recipe_repository.get_by_id(recipe_id)

        if recipe is None:
            raise ValueError("Recipe not found")

        average_rating = self.review_repository.get_average_rating(
            recipe_id
        )

        total_reviews = self.review_repository.get_review_count(
            recipe_id
        )

        return {
            "average_rating": average_rating,
            "total_reviews": total_reviews,
        }