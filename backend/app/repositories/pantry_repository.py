from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.pantry import Pantry
from app.models.pantry_item import PantryItem


class PantryRepository:
    def __init__(
        self,
        db: Session,
    ):
        self.db = db

    # ---------------------------------------------------------
    # Pantry
    # ---------------------------------------------------------

    def get_by_user_id(
        self,
        user_id: UUID,
    ) -> Pantry | None:
        statement = (
            select(Pantry)
            .where(Pantry.user_id == user_id)
        )

        return self.db.scalar(statement)

    def create(
        self,
        pantry: Pantry,
    ) -> Pantry:
        self.db.add(pantry)
        self.db.commit()
        self.db.refresh(pantry)

        return pantry

    # ---------------------------------------------------------
    # Pantry Items
    # ---------------------------------------------------------

    def get_item_by_ingredient(
        self,
        pantry_id: UUID,
        ingredient_id: UUID,
    ) -> PantryItem | None:

        statement = (
            select(PantryItem)
            .options(
                selectinload(PantryItem.ingredient),
                selectinload(PantryItem.unit),
            )
            .where(
                PantryItem.pantry_id == pantry_id,
                PantryItem.ingredient_id == ingredient_id,
            )
        )

        return self.db.scalar(statement)

    def add_item(
        self,
        item: PantryItem,
    ) -> PantryItem:

        self.db.add(item)
        self.db.commit()
        self.db.refresh(item)

        return self.get_item_by_id(item.id)

    def get_item_by_id(
        self,
        item_id: UUID,
    ) -> PantryItem | None:

        statement = (
            select(PantryItem)
            .options(
                selectinload(PantryItem.ingredient),
                selectinload(PantryItem.unit),
            )
            .where(PantryItem.id == item_id)
        )

        return self.db.scalar(statement)

    def update_item(
        self,
        item: PantryItem,
    ) -> PantryItem:

        self.db.commit()
        self.db.refresh(item)

        return self.get_item_by_id(item.id)

    def delete_item(
        self,
        item: PantryItem,
    ) -> None:

        self.db.delete(item)
        self.db.commit()

    def get_items_by_pantry_id(
        self,
        pantry_id: UUID,
    ) -> list[PantryItem]:

        statement = (
            select(PantryItem)
            .options(
                selectinload(PantryItem.ingredient),
                selectinload(PantryItem.unit),
            )
            .where(PantryItem.pantry_id == pantry_id)
        )

        return self.db.scalars(statement).all()