from math import ceil
from uuid import UUID

from fastapi import HTTPException, status

from app.models.recipe import Recipe
from app.models.user import User
from app.repositories.recipe_repository import RecipeRepository
from app.schemas.recipe import (
    RecipeCreate,
    RecipeResponse,
    RecipeUpdate,
)
from app.schemas.recipe_page import RecipePageResponse


class RecipeService:
    def __init__(
        self,
        recipe_repository: RecipeRepository,
    ):
        self.recipe_repository = recipe_repository

    # =========================================================
    # CREATE
    # =========================================================

    def create_recipe(
        self,
        request: RecipeCreate,
        current_user: User,
    ) -> RecipeResponse:

        recipe = Recipe(
            title=request.title,
            description=request.description,
            instructions=request.instructions,
            prep_time=request.prep_time,
            cook_time=request.cook_time,
            servings=request.servings,
            image_url=request.image_url,
            is_published=request.is_published,
            is_vegetarian=request.is_vegetarian,
            is_vegan=request.is_vegan,
            category_id=request.category_id,
            cuisine_id=request.cuisine_id,
            difficulty_id=request.difficulty_id,
            author_id=current_user.id,
        )

        recipe = self.recipe_repository.create(
            recipe,
        )

        return RecipeResponse.model_validate(
            recipe,
        )

    # =========================================================
    # GET RECIPE
    # =========================================================

    def get_recipe(
        self,
        recipe_id: UUID,
    ) -> RecipeResponse:

        recipe = self.recipe_repository.get_by_id(
            recipe_id,
        )

        if recipe is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Recipe not found.",
            )

        return RecipeResponse.model_validate(
            recipe,
        )

    # =========================================================
    # GET RECIPE PAGE
    # =========================================================

    def get_recipe_page(
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
    ) -> RecipePageResponse:

        recipes = self.recipe_repository.get_paginated(
            page=page,
            page_size=page_size,
            sort_by=sort_by,
            order=order,
            category_id=category_id,
            cuisine_id=cuisine_id,
            difficulty_id=difficulty_id,
            vegetarian=vegetarian,
            vegan=vegan,
            food_type=food_type,
        )

        total = self.recipe_repository.count()

        return RecipePageResponse(
            items=[
                RecipeResponse.model_validate(
                    recipe,
                )
                for recipe in recipes
            ],
            page=page,
            page_size=page_size,
            total=total,
            total_pages=ceil(
                total / page_size
            ) if total else 1,
            has_next=page * page_size < total,
            has_previous=page > 1,
        )

    # =========================================================
    # COUNT
    # =========================================================

    def get_recipe_count(
        self,
    ) -> int:
        return self.recipe_repository.count()

    # =========================================================
    # SEARCH
    # =========================================================

    def search_recipes(
        self,
        title: str | None = None,
        category_id: UUID | None = None,
        cuisine_id: UUID | None = None,
        difficulty_id: UUID | None = None,
        vegetarian: bool | None = None,
        page: int = 1,
        page_size: int = 10,
        food_type: str | None = None,
    ) -> list[RecipeResponse]:

        recipes = self.recipe_repository.search(
            title=title,
            category_id=category_id,
            cuisine_id=cuisine_id,
            difficulty_id=difficulty_id,
            vegetarian=vegetarian,
            page=page,
            page_size=page_size,
            food_type=food_type,
        )

        return [
            RecipeResponse.model_validate(
                recipe,
            )
            for recipe in recipes
        ]

    # =========================================================
    # UPDATE
    # =========================================================

    def update_recipe(
        self,
        recipe_id: UUID,
        request: RecipeUpdate,
        current_user: User,
    ) -> RecipeResponse:

        recipe = self.recipe_repository.get_by_id(
            recipe_id,
        )

        if recipe is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Recipe not found.",
            )

        if recipe.author_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not allowed to edit this recipe.",
            )

        update_data = request.model_dump(
            exclude_unset=True,
        )

        recipe = self.recipe_repository.update(
            recipe,
            update_data,
        )

        return RecipeResponse.model_validate(
            recipe,
        )

    # =========================================================
    # DELETE
    # =========================================================

    def delete_recipe(
        self,
        recipe_id: UUID,
        current_user: User,
    ) -> None:

        recipe = self.recipe_repository.get_by_id(
            recipe_id,
        )

        if recipe is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Recipe not found.",
            )

        if recipe.author_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not allowed to delete this recipe.",
            )

        self.recipe_repository.delete(
            recipe,
        )