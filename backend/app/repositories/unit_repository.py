from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.unit import Unit


class UnitRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_symbol(
        self,
        symbol: str,
    ) -> Unit | None:
        normalized_symbol = symbol.strip().lower()

        if not normalized_symbol:
            return None

        statement = select(Unit).where(
            Unit.symbol.ilike(normalized_symbol),
        )

        return self.db.scalar(statement)

    def get_all(self) -> list[Unit]:
        statement = (
            select(Unit)
            .order_by(Unit.name)
        )

        return list(self.db.scalars(statement).all())