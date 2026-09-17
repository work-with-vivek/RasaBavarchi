from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.dependencies.database import get_db
from app.repositories.unit_repository import UnitRepository
from app.schemas.unit import UnitResponse

router = APIRouter(
    prefix="/units",
    tags=["Units"],
)


def get_unit_repository(
    db: Session = Depends(get_db),
) -> UnitRepository:
    return UnitRepository(db)


@router.get(
    "",
    response_model=list[UnitResponse],
)
def get_units(
    repository: UnitRepository = Depends(
        get_unit_repository,
    ),
):
    return repository.get_all()


@router.get(
    "/by-symbol",
    response_model=UnitResponse,
)
def get_unit_by_symbol(
    symbol: str = Query(
        ...,
        min_length=1,
        max_length=10,
    ),
    repository: UnitRepository = Depends(
        get_unit_repository,
    ),
):
    unit = repository.get_by_symbol(symbol)

    if unit is None:
        raise HTTPException(
            status_code=404,
            detail=f"Unit '{symbol}' not found.",
        )

    return unit