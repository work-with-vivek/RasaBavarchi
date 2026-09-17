from fastapi import APIRouter, Depends

from sqlalchemy.orm import Session

from app.dependencies.database import get_db
from app.repositories.category_repository import CategoryRepository
from app.schemas.common import CategoryInfo
from app.services.category_service import CategoryService


router = APIRouter(
    prefix="/categories",
    tags=["Categories"],
)


def get_category_service(
    db: Session = Depends(get_db),
) -> CategoryService:
    return CategoryService(
        CategoryRepository(db),
    )


# ---------------------------------------------------------
# Get All Categories
# ---------------------------------------------------------

@router.get(
    "",
    response_model=list[CategoryInfo],
)
def get_categories(
    service: CategoryService = Depends(get_category_service),
):
    return service.get_categories()