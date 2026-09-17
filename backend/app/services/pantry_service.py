from datetime import datetime
from decimal import Decimal
from uuid import UUID

from app.models.pantry import Pantry
from app.models.pantry_item import PantryItem
from app.repositories.pantry_repository import PantryRepository


class PantryService:
    def __init__(
        self,
        repository: PantryRepository,
    ):
        self.repository = repository

    def get_or_create_pantry(
        self,
        user_id: UUID,
    ) -> Pantry:
        pantry = self.repository.get_by_user_id(user_id)

        if pantry is None:
            pantry = Pantry(user_id=user_id)
            pantry = self.repository.create(pantry)

        return pantry

    def add_item(
        self,
        user_id: UUID,
        ingredient_id: UUID,
        quantity: float,
        unit_id: UUID,
        expires_at: datetime | None = None,
    ) -> PantryItem:

        pantry = self.get_or_create_pantry(user_id)

        existing_item = self.repository.get_item_by_ingredient(
            pantry.id,
            ingredient_id,
        )

        if existing_item is not None:
            existing_item.quantity += Decimal(str(quantity))
            existing_item.unit_id = unit_id
            existing_item.expires_at = expires_at

            saved_item = self.repository.update_item(
                existing_item
            )
        else:
            pantry_item = PantryItem(
                pantry_id=pantry.id,
                ingredient_id=ingredient_id,
                quantity=Decimal(str(quantity)),
                unit_id=unit_id,
                expires_at=expires_at,
            )

            saved_item = self.repository.add_item(
                pantry_item
            )

        self.repository.db.refresh(saved_item)

        return saved_item

    def get_items(
        self,
        user_id: UUID,
    ) -> list[PantryItem]:

        pantry = self.get_or_create_pantry(user_id)

        return self.repository.get_items_by_pantry_id(
            pantry.id,
        )

    def update_item(
        self,
        user_id: UUID,
        item_id: UUID,
        quantity: float | None = None,
        unit_id: UUID | None = None,
        expires_at: datetime | None = None,
    ) -> PantryItem:

        pantry = self.get_or_create_pantry(user_id)

        item = self.repository.get_item_by_id(
            item_id
        )

        if item is None or item.pantry_id != pantry.id:
            raise ValueError(
                "Item not found in user's pantry."
            )

        if quantity is not None:
            item.quantity = Decimal(str(quantity))

        if unit_id is not None:
            item.unit_id = unit_id

        item.expires_at = expires_at

        updated_item = self.repository.update_item(
            item
        )

        self.repository.db.refresh(updated_item)

        return updated_item

    def delete_item(
        self,
        user_id: UUID,
        item_id: UUID,
    ) -> None:

        pantry = self.get_or_create_pantry(user_id)

        item = self.repository.get_item_by_id(
            item_id
        )

        if item is None or item.pantry_id != pantry.id:
            raise ValueError(
                "Item not found in user's pantry."
            )

        self.repository.delete_item(item)