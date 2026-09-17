from sqlalchemy import select

from app.db.session import SessionLocal

from app.models.unit import Unit
from app.models.category import Category
from app.models.cuisine import Cuisine
from app.models.difficulty import Difficulty
from app.models.ingredient import Ingredient
from app.models.ingredient_category import IngredientCategory


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

print("Seeding Units...")

units = [
    ("Piece", "pcs"),
    ("Gram", "g"),
    ("Kilogram", "kg"),
    ("Milliliter", "ml"),
    ("Liter", "l"),
]

for name, symbol in units:
    get_or_create(
        Unit,
        name=name,
        symbol=symbol,
    )

    print("Seeding Recipe Categories...")

for name in [
    "Breakfast",
    "Lunch",
    "Dinner",
    "Snack",
    "Dessert",
]:
    get_or_create(
        Category,
        name=name,
    )

    print("Seeding Cuisines...")

for name in [
    "Indian",
    "Chinese",
    "Italian",
    "Mexican",
]:
    get_or_create(
        Cuisine,
        name=name,
    )

    print("Seeding Difficulties...")

for name in [
    "Easy",
    "Medium",
    "Hard",
]:
    get_or_create(
        Difficulty,
        name=name,
    )

    print("Seeding Ingredient Categories...")

ingredient_categories = {}

for name in [
    "Vegetables",
    "Fruits",
    "Dairy",
    "Meat",
    "Grains",
    "Spices",
]:
    ingredient_categories[name] = get_or_create(
        IngredientCategory,
        name=name,
    )

    print("Seeding Ingredients...")

ingredients = [
    # Vegetables
    ("Onion", "Vegetables"),
    ("Tomato", "Vegetables"),
    ("Potato", "Vegetables"),
    ("Garlic", "Vegetables"),
    ("Ginger", "Vegetables"),
    ("Green Chili", "Vegetables"),
    ("Carrot", "Vegetables"),
    ("Cabbage", "Vegetables"),
    ("Cauliflower", "Vegetables"),
    ("Capsicum", "Vegetables"),
    ("Spinach", "Vegetables"),
    ("Peas", "Vegetables"),
    ("Beans", "Vegetables"),
    ("Cucumber", "Vegetables"),

    # Fruits
    ("Apple", "Fruits"),
    ("Banana", "Fruits"),
    ("Mango", "Fruits"),
    ("Orange", "Fruits"),
    ("Lemon", "Fruits"),

    # Dairy
    ("Milk", "Dairy"),
    ("Butter", "Dairy"),
    ("Paneer", "Dairy"),
    ("Cheese", "Dairy"),
    ("Curd", "Dairy"),

    # Meat
    ("Chicken", "Meat"),
    ("Egg", "Meat"),
    ("Fish", "Meat"),
    ("Mutton", "Meat"),

    # Grains
    ("Rice", "Grains"),
    ("Wheat Flour", "Grains"),
    ("Maida", "Grains"),
    ("Poha", "Grains"),
    ("Oats", "Grains"),

    # Spices
    ("Salt", "Spices"),
    ("Sugar", "Spices"),
    ("Turmeric Powder", "Spices"),
    ("Red Chili Powder", "Spices"),
    ("Coriander Powder", "Spices"),
    ("Cumin Seeds", "Spices"),
    ("Black Pepper", "Spices"),
    ("Garam Masala", "Spices"),
    ("Oil", "Spices"),
]
for ingredient_name, category_name in ingredients:

    get_or_create(
        Ingredient,
        name=ingredient_name,
        category=ingredient_categories[category_name],
    )

print("Database seeded successfully!")