from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.dependencies.auth import get_current_user
from app.dependencies.database import get_db
from app.models.user import User
from app.repositories.pantry_repository import PantryRepository
from app.schemas.pantry import (
    PantryItemCreate,
    PantryItemResponse,
    PantryItemUpdate,
)
from app.services.pantry_service import PantryService

router = APIRouter(
    prefix="/pantry",
    tags=["Pantry"],
)


def get_pantry_service(
    db: Session = Depends(get_db),
) -> PantryService:
    return PantryService(
        PantryRepository(db),
    )


@router.post(
    "/items",
    response_model=PantryItemResponse,
    status_code=status.HTTP_201_CREATED,
)
def add_pantry_item(
    data: PantryItemCreate,
    current_user: User = Depends(get_current_user),
    service: PantryService = Depends(get_pantry_service),
):
    return service.add_item(
        user_id=current_user.id,
        ingredient_id=data.ingredient_id,
        quantity=data.quantity,
        unit_id=data.unit_id,
        expires_at=data.expires_at,
    )


@router.get(
    "/items",
    response_model=list[PantryItemResponse],
)
def get_pantry_items(
    current_user: User = Depends(get_current_user),
    service: PantryService = Depends(get_pantry_service),
):
    return service.get_items(current_user.id)


@router.put(
    "/items/{item_id}",
    response_model=PantryItemResponse,
)
def update_pantry_item(
    item_id: UUID,
    data: PantryItemUpdate,
    current_user: User = Depends(get_current_user),
    service: PantryService = Depends(get_pantry_service),
):
    try:
        return service.update_item(
            user_id=current_user.id,
            item_id=item_id,
            quantity=data.quantity,
            unit_id=data.unit_id,
            expires_at=data.expires_at,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )


@router.delete(
    "/items/{item_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_pantry_item(
    item_id: UUID,
    current_user: User = Depends(get_current_user),
    service: PantryService = Depends(get_pantry_service),
):
    try:
        service.delete_item(
            user_id=current_user.id,
            item_id=item_id,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )