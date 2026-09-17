from fastapi import Depends
from sqlalchemy.orm import Session

from app.dependencies.database import get_db
from app.repositories.weight_loss_repository import (
    WeightLossRepository,
)
from app.services.weight_loss_service import (
    WeightLossService,
)


def get_weight_loss_service(
    db: Session = Depends(get_db),
) -> WeightLossService:

    return WeightLossService(
        weight_loss_repository=WeightLossRepository(db),
    )