from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.dependencies.auth import get_current_user
from app.dependencies.database import get_db
from app.models.user import User
from app.repositories.recipe_repository import RecipeRepository
from app.repositories.review_repository import ReviewRepository
from app.schemas.review import (
    ReviewCreate,
    ReviewResponse,
    ReviewUpdate,
    RecipeRatingResponse,
)
from app.services.review_service import ReviewService

router = APIRouter(
    prefix="/reviews",
    tags=["Reviews"],
)


@router.post(
    "/recipes/{recipe_id}",
    response_model=ReviewResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_review(
    recipe_id: UUID,
    request: ReviewCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = ReviewService(
        ReviewRepository(db),
        RecipeRepository(db),
    )

    try:
        return service.create_review(
            recipe_id,
            request,
            current_user,
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )


@router.get(
    "/recipes/{recipe_id}",
    response_model=list[ReviewResponse],
)
def get_reviews(
    recipe_id: UUID,
    db: Session = Depends(get_db),
):
    service = ReviewService(
        ReviewRepository(db),
        RecipeRepository(db),
    )

    try:
        return service.get_reviews(recipe_id)

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )


@router.put(
    "/{review_id}",
    response_model=ReviewResponse,
)
def update_review(
    review_id: UUID,
    request: ReviewUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = ReviewService(
        ReviewRepository(db),
        RecipeRepository(db),
    )

    try:
        return service.update_review(
            review_id,
            request,
            current_user,
        )

    except PermissionError as exc:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(exc),
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )


@router.delete(
    "/{review_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_review(
    review_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = ReviewService(
        ReviewRepository(db),
        RecipeRepository(db),
    )

    try:
        service.delete_review(
            review_id,
            current_user,
        )

    except PermissionError as exc:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(exc),
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )


@router.get(
    "/recipes/{recipe_id}/rating",
    response_model=RecipeRatingResponse,
)
def get_rating_summary(
    recipe_id: UUID,
    db: Session = Depends(get_db),
):
    service = ReviewService(
        ReviewRepository(db),
        RecipeRepository(db),
    )

    try:
        return service.get_rating_summary(recipe_id)

    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )