import secrets

from sqlalchemy import select

from app.db.session import SessionLocal
from app.models.category import Category
from app.models.cuisine import Cuisine
from app.models.difficulty import Difficulty
from app.models.ingredient import Ingredient
from app.models.ingredient_category import IngredientCategory
from app.models.unit import Unit
from app.models.user import User
from app.utils.security import hash_password


db = SessionLocal()


def get_or_create(model, **kwargs):
    obj = db.scalar(select(model).filter_by(**kwargs))

    if obj:
        return obj

    obj = model(**kwargs)
    db.add(obj)
    db.commit()
    db.refresh(obj)

    return obj


try:
    print("Seeding recipe categories...")

    for name in [
        "Breakfast",
        "Lunch",
        "Dinner",
        "Snack",
        "Dessert",
    ]:
        get_or_create(Category, name=name)

    print("Seeding cuisines...")

    for name in [
        "Indian",
        "Chinese",
        "Italian",
        "Mexican",
    ]:
        get_or_create(Cuisine, name=name)

    print("Seeding difficulties...")

    for name in [
        "Easy",
        "Medium",
        "Hard",
    ]:
        get_or_create(Difficulty, name=name)

    print("Seeding ingredient categories...")

    for name in [
        "Vegetables",
        "Fruits",
        "Dairy",
        "Meat",
        "Grains",
        "Spices",
        "Legumes",
        "Nuts",
        "Other",
        "Seafood",
    ]:
        get_or_create(
            IngredientCategory,
            name=name,
        )

    print("Seeding units...")

    units = [
        ("Cup", "cup"),
        ("Gram", "g"),
        ("Kilogram", "kg"),
        ("Liter", "L"),
        ("Milliliter", "ml"),
        ("Piece", "pc"),
        ("Pinch", "pinch"),
        ("Tablespoon", "tbsp"),
        ("Teaspoon", "tsp"),
        ("Unknown", "unk"),
    ]

    for name, symbol in units:
        get_or_create(
            Unit,
            name=name,
            symbol=symbol,
        )

    print("Seeding system user...")

    system_user = db.scalar(
        select(User).where(
            User.email == "recipes@rasabavarchi.com"
        )
    )

    if system_user is None:
        system_password = secrets.token_urlsafe(32)

        system_user = User(
            email="recipes@rasabavarchi.com",
            username="recipe_importer",
            hashed_password=hash_password(system_password),
            is_active=True,
            is_verified=True,
        )

        db.add(system_user)
        db.commit()

        print("System user created.")
    else:
        print("System user already exists.")

    print("Database seeded successfully!")

finally:
    db.close()