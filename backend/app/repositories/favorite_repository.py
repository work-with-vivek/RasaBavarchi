from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.favorite import Favorite


class FavoriteRepository:
    def __init__(
        self,
        db: Session,
    ):
        self.db = db

    # ---------------------------------------------------------
    # Create
    # ---------------------------------------------------------

    def create(
        self,
        favorite: Favorite,
    ) -> Favorite:
        self.db.add(favorite)
        self.db.commit()
        self.db.refresh(favorite)

        return self.get_by_id(favorite.id)

    # ---------------------------------------------------------
    # Read
    # ---------------------------------------------------------

    def get_by_id(
        self,
        favorite_id: UUID,
    ) -> Favorite | None:
        statement = (
            select(Favorite)
            .options(
                selectinload(Favorite.recipe),
                selectinload(Favorite.user),
            )
            .where(Favorite.id == favorite_id)
        )

        return self.db.scalar(statement)

    def get_by_user_and_recipe(
        self,
        user_id: UUID,
        recipe_id: UUID,
    ) -> Favorite | None:

        statement = (
            select(Favorite)
            .where(
                Favorite.user_id == user_id,
                Favorite.recipe_id == recipe_id,
            )
        )

        return self.db.scalar(statement)

    def get_user_favorites(
        self,
        user_id: UUID,
    ) -> list[Favorite]:

        statement = (
            select(Favorite)
            .options(
                selectinload(Favorite.recipe),
            )
            .where(Favorite.user_id == user_id)
            .order_by(Favorite.created_at.desc())
        )

        return self.db.scalars(statement).all()

    # ---------------------------------------------------------
    # Delete
    # ---------------------------------------------------------

    def delete(
        self,
        favorite: Favorite,
    ) -> None:

        self.db.delete(favorite)
        self.db.commit()

    # ---------------------------------------------------------
    # Utility
    # ---------------------------------------------------------

    def exists(
        self,
        user_id: UUID,
        recipe_id: UUID,
    ) -> bool:

        return (
            self.get_by_user_and_recipe(
                user_id,
                recipe_id,
            )
            is not None
        )

    def count_user_favorites(
        self,
        user_id: UUID,
    ) -> int:

        return len(
            self.get_user_favorites(user_id)
        )