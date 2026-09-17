from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.repositories.shopping_repository import ShoppingRepository
from app.schemas.shopping import ShoppingListResponse
from app.services.shopping_service import ShoppingService

router = APIRouter(
    prefix="/shopping-list",
    tags=["Shopping List"],
)


def get_shopping_service(
    db: Session = Depends(get_db),
) -> ShoppingService:
    repository = ShoppingRepository(db)
    return ShoppingService(repository)


@router.get(
    "/{meal_plan_id}",
    response_model=ShoppingListResponse,
)
def generate_shopping_list(
    meal_plan_id: UUID,
    service: ShoppingService = Depends(
        get_shopping_service
    ),
):
    return service.generate_shopping_list(
        meal_plan_id
    )