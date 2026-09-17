from uuid import UUID

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session, selectinload

from app.models.recipe import Recipe
from app.models.recipe_ingredient import RecipeIngredient


class RecipeRepository:
    def __init__(
        self,
        db: Session,
    ):
        self.db = db

    # =========================================================
    # CREATE
    # =========================================================

    def create(
        self,
        recipe: Recipe,
    ) -> Recipe:
        self.db.add(recipe)
        self.db.commit()
        self.db.refresh(recipe)

        return self.get_by_id(recipe.id)

    # =========================================================
    # GET BY ID
    # =========================================================

    def get_by_id(
        self,
        recipe_id: UUID,
    ) -> Recipe | None:
        statement = (
            select(Recipe)
            .options(
                selectinload(Recipe.category),
                selectinload(Recipe.cuisine),
                selectinload(Recipe.difficulty),
                selectinload(Recipe.author),
                selectinload(Recipe.reviews),
                selectinload(
                    Recipe.ingredients,
                ).selectinload(
                    RecipeIngredient.ingredient,
                ),
                selectinload(
                    Recipe.ingredients,
                ).selectinload(
                    RecipeIngredient.unit,
                ),
            )
            .where(
                Recipe.id == recipe_id,
            )
        )

        return self.db.scalar(statement)

    # =========================================================
    # GET PAGINATED
    # =========================================================

    def get_paginated(
        self,
        page: int = 1,
        page_size: int = 10,
        sort_by: str = "title",
        order: str = "asc",
        category_id: UUID | None = None,
        cuisine_id: UUID | None = None,
        difficulty_id: UUID | None = None,
        vegetarian: bool | None = None,
        vegan: bool | None = None,
        food_type: str | None = None,
    ) -> list[Recipe]:

        statement = (
            select(Recipe)
            .options(
                selectinload(Recipe.category),
                selectinload(Recipe.cuisine),
                selectinload(Recipe.difficulty),
                selectinload(Recipe.author),
                selectinload(Recipe.reviews),
                selectinload(
                    Recipe.ingredients,
                ).selectinload(
                    RecipeIngredient.ingredient,
                ),
                selectinload(
                    Recipe.ingredients,
                ).selectinload(
                    RecipeIngredient.unit,
                ),
            )
        )

        # ---------------------------------------------------------
        # Category
        # ---------------------------------------------------------

        if category_id:
            statement = statement.where(
                Recipe.category_id == category_id,
            )

        # ---------------------------------------------------------
        # Cuisine
        # ---------------------------------------------------------

        if cuisine_id:
            statement = statement.where(
                Recipe.cuisine_id == cuisine_id,
            )

        # ---------------------------------------------------------
        # Difficulty
        # ---------------------------------------------------------

        if difficulty_id:
            statement = statement.where(
                Recipe.difficulty_id == difficulty_id,
            )

        # ---------------------------------------------------------
        # Food Type
        # ---------------------------------------------------------
        #
        # New source of truth:
        #
        #     recipes.food_type
        #
        # Supported values:
        #
        #     VEGAN
        #     VEGETARIAN
        #     NON_VEGETARIAN
        #
        # The value is normalized to uppercase so callers can
        # safely provide:
        #
        #     vegan
        #     Vegan
        #     VEGAN
        #
        # ---------------------------------------------------------

        if food_type:
            normalized_food_type = food_type.strip().upper()

            valid_food_types = {
                "VEGAN",
                "VEGETARIAN",
                "NON_VEGETARIAN",
            }

            if normalized_food_type in valid_food_types:
                statement = statement.where(
                    Recipe.food_type == normalized_food_type,
                )

        # ---------------------------------------------------------
        # Legacy Vegetarian Filter
        # ---------------------------------------------------------
        #
        # Kept for backward compatibility.
        #
        # vegetarian=True:
        #     is_vegetarian = true
        #     OR
        #     is_vegan = true
        #
        # vegetarian=False:
        #     is_vegetarian = false
        #     AND
        #     is_vegan = false
        #
        # ---------------------------------------------------------

        if vegetarian is True:
            statement = statement.where(
                or_(
                    Recipe.is_vegetarian.is_(True),
                    Recipe.is_vegan.is_(True),
                )
            )

        elif vegetarian is False:
            statement = statement.where(
                Recipe.is_vegetarian.is_(False),
                Recipe.is_vegan.is_(False),
            )

        # ---------------------------------------------------------
        # Legacy Vegan Filter
        # ---------------------------------------------------------

        if vegan is not None:
            statement = statement.where(
                Recipe.is_vegan == vegan,
            )

        # ---------------------------------------------------------
        # Sorting
        # ---------------------------------------------------------
        
        if sort_by.lower() == "random":
            statement = statement.order_by(func.random())
        else:
            sort_columns = {
                "title": Recipe.title,
                "prep_time": Recipe.prep_time,
                "cook_time": Recipe.cook_time,
                "created_at": Recipe.created_at,
            }

            column = sort_columns.get(
                sort_by.lower(),
                Recipe.title,
            )

            if order.lower() == "desc":
                statement = statement.order_by(
                    column.desc(),
                )
            else:
                statement = statement.order_by(
                    column.asc(),
                )
        # ---------------------------------------------------------
        # Pagination
        # ---------------------------------------------------------

        offset = (page - 1) * page_size

        statement = (
            statement
            .offset(offset)
            .limit(page_size)
        )

        return self.db.scalars(statement).all()

    # =========================================================
    # SEARCH
    # =========================================================

    def search(
        self,
        title: str | None = None,
        category_id: UUID | None = None,
        cuisine_id: UUID | None = None,
        difficulty_id: UUID | None = None,
        vegetarian: bool | None = None,
        page: int = 1,
        page_size: int = 10,
        food_type: str | None = None,
    ) -> list[Recipe]:

        statement = (
            select(Recipe)
            .options(
                selectinload(Recipe.category),
                selectinload(Recipe.cuisine),
                selectinload(Recipe.difficulty),
                selectinload(Recipe.author),
                selectinload(Recipe.reviews),
                selectinload(
                    Recipe.ingredients,
                ).selectinload(
                    RecipeIngredient.ingredient,
                ),
                selectinload(
                    Recipe.ingredients,
                ).selectinload(
                    RecipeIngredient.unit,
                ),
            )
        )

        # ---------------------------------------------------------
        # Title
        # ---------------------------------------------------------

        if title:
            statement = statement.where(
                Recipe.title.ilike(
                    f"%{title}%"
                )
            )

        # ---------------------------------------------------------
        # Category
        # ---------------------------------------------------------

        if category_id:
            statement = statement.where(
                Recipe.category_id == category_id,
            )

        # ---------------------------------------------------------
        # Cuisine
        # ---------------------------------------------------------

        if cuisine_id:
            statement = statement.where(
                Recipe.cuisine_id == cuisine_id,
            )

        # ---------------------------------------------------------
        # Difficulty
        # ---------------------------------------------------------

        if difficulty_id:
            statement = statement.where(
                Recipe.difficulty_id == difficulty_id,
            )

        # ---------------------------------------------------------
        # Food Type
        # ---------------------------------------------------------

        if food_type:
            normalized_food_type = food_type.strip().upper()

            valid_food_types = {
                "VEGAN",
                "VEGETARIAN",
                "NON_VEGETARIAN",
            }

            if normalized_food_type in valid_food_types:
                statement = statement.where(
                    Recipe.food_type == normalized_food_type,
                )

        # ---------------------------------------------------------
        # Legacy Vegetarian Filter
        # ---------------------------------------------------------

        if vegetarian is True:
            statement = statement.where(
                or_(
                    Recipe.is_vegetarian.is_(True),
                    Recipe.is_vegan.is_(True),
                )
            )

        elif vegetarian is False:
            statement = statement.where(
                Recipe.is_vegetarian.is_(False),
                Recipe.is_vegan.is_(False),
            )

        # ---------------------------------------------------------
        # Pagination
        # ---------------------------------------------------------

        offset = (page - 1) * page_size

        statement = (
            statement
            .order_by(Recipe.title.asc())
            .offset(offset)
            .limit(page_size)
        )

        return self.db.scalars(statement).all()

    # =========================================================
    # UPDATE
    # =========================================================

    def update(
        self,
        recipe: Recipe,
        update_data: dict,
    ) -> Recipe:

        for field, value in update_data.items():
            setattr(
                recipe,
                field,
                value,
            )

        self.db.commit()
        self.db.refresh(recipe)

        return self.get_by_id(recipe.id)

    # =========================================================
    # DELETE
    # =========================================================

    def delete(
        self,
        recipe: Recipe,
    ) -> None:
        self.db.delete(recipe)
        self.db.commit()

    # =========================================================
    # COUNT
    # =========================================================

    def count(self) -> int:
        statement = (
            select(func.count())
            .select_from(Recipe)
        )

        return self.db.scalar(statement) or 0