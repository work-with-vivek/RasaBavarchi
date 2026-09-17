from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.repositories.pantry_repository import PantryRepository
from app.schemas.pantry import PantryItemCreate
from app.services.pantry_service import PantryService

router = APIRouter(
    prefix="/pantry",
    tags=["Pantry"],
)
@router.post("/items")
def add_pantry_item(
    data: PantryItemCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    repository = PantryRepository(db)
    service = PantryService(repository)

    item = service.add_item(
        user_id=current_user.id,
        ingredient_id=data.ingredient_id,
        quantity=data.quantity,
        unit_id=data.unit_id,
        expires_at=data.expires_at,
    )

    return {
        "message": "Ingredient added successfully.",
        "item_id": item.id,
    }