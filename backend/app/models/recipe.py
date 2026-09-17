import uuid
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel

if TYPE_CHECKING:
    from app.models.category import Category
    from app.models.cuisine import Cuisine
    from app.models.difficulty import Difficulty
    from app.models.favorite import Favorite
    from app.models.meal import Meal
    from app.models.recipe_ingredient import RecipeIngredient
    from app.models.review import Review
    from app.models.user import User


class Recipe(BaseModel):
    __tablename__ = "recipes"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    external_id: Mapped[int | None] = mapped_column(
        Integer,
        unique=True,
        nullable=True,
        index=True,
    )

    title: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
    )

    description: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    instructions: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    prep_time: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    cook_time: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    servings: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    calories: Mapped[float] = mapped_column(
        Float,
        default=0,
        nullable=False,
    )

    protein_g: Mapped[float] = mapped_column(
        Float,
        default=0,
        nullable=False,
    )

    carbs_g: Mapped[float] = mapped_column(
        Float,
        default=0,
        nullable=False,
    )

    fat_g: Mapped[float] = mapped_column(
        Float,
        default=0,
        nullable=False,
    )

    image_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    is_published: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
    )

    is_vegetarian: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
    )

    is_vegan: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
    )

    # ---------------------------------------------------------
    # FOOD TYPE CLASSIFICATION
    # ---------------------------------------------------------

    food_type: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="UNKNOWN",
        server_default="UNKNOWN",
        index=True,
    )

    category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("categories.id"),
        nullable=False,
    )

    cuisine_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("cuisines.id"),
        nullable=False,
    )

    difficulty_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("difficulties.id"),
        nullable=False,
    )

    author_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id"),
        nullable=False,
    )

    # ---------------------------------------------------------
    # Relationships
    # ---------------------------------------------------------

    category: Mapped["Category"] = relationship(
        back_populates="recipes",
    )

    cuisine: Mapped["Cuisine"] = relationship(
        back_populates="recipes",
    )

    difficulty: Mapped["Difficulty"] = relationship(
        back_populates="recipes",
    )

    author: Mapped["User"] = relationship(
        back_populates="recipes",
    )

    ingredients: Mapped[list["RecipeIngredient"]] = relationship(
        back_populates="recipe",
        cascade="all, delete-orphan",
    )

    favorites: Mapped[list["Favorite"]] = relationship(
        back_populates="recipe",
        cascade="all, delete-orphan",
    )

    reviews: Mapped[list["Review"]] = relationship(
        back_populates="recipe",
        cascade="all, delete-orphan",
    )

    meals: Mapped[list["Meal"]] = relationship(
        back_populates="recipe",
        lazy="selectin",
    )