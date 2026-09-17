from sqlalchemy import select

from app.db.session import SessionLocal
from app.models.ingredient import Ingredient
from app.models.unit import Unit

db = SessionLocal()

print("===== INGREDIENTS =====")
ingredients = db.scalars(select(Ingredient)).all()

if not ingredients:
    print("No ingredients found.")
else:
    for ingredient in ingredients:
        print(ingredient.id, "-", ingredient.name)

print("\n===== UNITS =====")
units = db.scalars(select(Unit)).all()

if not units:
    print("No units found.")
else:
    for unit in units:
        print(unit.id, "-", unit.name, "-", unit.symbol)

db.close()