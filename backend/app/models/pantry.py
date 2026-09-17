import uuid
from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel

if TYPE_CHECKING:
    from app.models.pantry_item import PantryItem
    from app.models.user import User


class Pantry(BaseModel):
    __tablename__ = "pantries"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id"),
        unique=True,
        nullable=False,
    )

    # ---------------------------------------------------------
    # Relationships
    # ---------------------------------------------------------

    user: Mapped["User"] = relationship(
        back_populates="pantry",
    )

    pantry_items: Mapped[list["PantryItem"]] = relationship(
        back_populates="pantry",
        cascade="all, delete-orphan",
    )