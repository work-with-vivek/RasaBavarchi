import os
import re
import sys

# =========================================================
# IMPORT PATH
# =========================================================

sys.path.append(
    os.path.dirname(
        os.path.dirname(__file__)
    )
)

from app.dependencies.database import SessionLocal
from app.models.ingredient import Ingredient


# =========================================================
# FOOD TYPES
# =========================================================

VEGAN = "VEGAN"
VEGETARIAN = "VEGETARIAN"
NON_VEGETARIAN = "NON_VEGETARIAN"
UNKNOWN = "UNKNOWN"


# =========================================================
# NORMALIZATION
# =========================================================

def normalize(name: str) -> str:
    name = name.lower().strip()

    name = name.replace("&", " and ")
    name = name.replace("%", " percent ")
    name = name.replace('"', " ")
    name = name.replace("'", " ")

    name = re.sub(r"[^a-z0-9\s]", " ", name)
    name = re.sub(r"\s+", " ", name)

    return name.strip()


# =========================================================
# EXPLICIT VEGAN SUBSTITUTES
# =========================================================

VEGAN_SUBSTITUTES = {
    "vegetarian chicken",
    "vegetarian beef",
    "vegetarian pork",
    "vegetarian sausage",
    "vegetarian pepperoni",
    "vegetarian bacon",

    "vegan chicken",
    "vegan beef",
    "vegan pork",
    "vegan sausage",
    "vegan pepperoni",
    "vegan bacon",

    "soy chorizo",
    "soy sausage",
    "soy pepperoni",

    "plant based chicken",
    "plant based beef",
    "plant based sausage",
    "plant based pepperoni",

    "meatless chicken",
    "meatless beef",
    "meatless sausage",
}


# =========================================================
# EXPLICIT NON-VEGETARIAN PHRASES
# =========================================================

NON_VEGETARIAN_PHRASES = {
    "chicken broth",
    "chicken stock",

    "beef broth",
    "beef stock",

    "pork broth",
    "pork stock",

    "turkey broth",
    "turkey stock",

    "fish sauce",
    "fish stock",
    "fish broth",

    "oyster sauce",

    "anchovy paste",
    "anchovy fillet",
    "anchovy fillets",
    "anchovy essence",

    "bacon fat",
    "bacon grease",
    "bacon drippings",

    "chicken sausage",
    "turkey sausage",
    "pork sausage",
    "beef sausage",

    "chicken liver",
    "beef liver",
    "pork liver",

    "beef wieners",
    "all beef wieners",
}


# =========================================================
# NON-VEGETARIAN EXACT
# =========================================================

NON_VEGETARIAN_EXACT = {
    "beef",
    "ground beef",
    "steak",
    "veal",
    "pork",
    "ham",
    "bacon",
    "lamb",
    "mutton",
    "goat meat",
    "venison",
    "rabbit",
    "duck",
    "turkey",

    "chicken",
    "chicken breast",
    "chicken breasts",
    "chicken thigh",
    "chicken thighs",
    "chicken wing",
    "chicken wings",
    "chicken liver",

    "fish",
    "salmon",
    "tuna",
    "ahi",
    "anchovy",
    "anchovies",
    "sardine",
    "sardines",
    "cod",
    "trout",
    "haddock",
    "halibut",
    "mackerel",

    "shrimp",
    "prawn",
    "prawns",
    "crab",
    "crab meat",
    "lobster",
    "clam",
    "clams",
    "mussel",
    "mussels",
    "oyster",
    "oysters",
    "octopus",
    "squid",
    "scallop",
    "scallops",

    "gelatin",
    "gelatine",
    "lard",
    "beef tallow",
    "suet",

    "sausage",
    "hot dog",
    "hot dogs",
    "pepperoni",
    "salami",
    "prosciutto",
    "mortadella",
    "bologna",
    "chorizo",
    "meatball",
    "meatballs",

    "egg",
    "eggs",
    "egg white",
    "egg whites",
    "egg yolk",
    "egg yolks",
}


# =========================================================
# VEGAN EXACT
# =========================================================

VEGAN_EXACT = {
    # Basic
    "sugar",
    "white sugar",
    "brown sugar",
    "granulated sugar",
    "powdered sugar",
    "confectioners sugar",

    "flour",
    "all purpose flour",
    "whole wheat flour",
    "bread flour",
    "cake flour",
    "corn flour",
    "cornmeal",
    "corn starch",
    "cornstarch",

    # Grains
    "rice",
    "white rice",
    "brown rice",
    "basmati rice",
    "wild rice",
    "jasmine rice",
    "quinoa",
    "barley",
    "oats",
    "rolled oats",
    "oatmeal",
    "couscous",

    # Vegetables
    "onion",
    "onions",
    "red onion",
    "green onion",
    "green onions",
    "yellow onion",
    "white onion",

    "garlic",
    "garlic clove",
    "garlic cloves",
    "garlic powder",

    "ginger",
    "fresh ginger",
    "ground ginger",

    "potato",
    "potatoes",

    "tomato",
    "tomatoes",
    "diced tomatoes",

    "carrot",
    "carrots",

    "celery",

    "broccoli",
    "cauliflower",
    "cabbage",
    "spinach",
    "kale",
    "lettuce",
    "zucchini",

    "eggplant",
    "aubergine",

    "cucumber",

    "bell pepper",
    "red bell pepper",
    "green bell pepper",
    "yellow bell pepper",

    "jalapeno",
    "jalapenos",

    "mushroom",
    "mushrooms",

    "oyster mushroom",
    "oyster mushrooms",

    "avocado",

    # Fruits
    "apple",
    "apples",
    "banana",
    "bananas",
    "orange",
    "oranges",
    "lemon",
    "lemons",
    "lime",
    "limes",
    "mango",
    "mangoes",
    "pineapple",

    "strawberry",
    "strawberries",
    "blueberry",
    "blueberries",
    "raspberry",
    "raspberries",
    "blackberry",
    "blackberries",

    "peach",
    "peaches",
    "pear",
    "pears",
    "cherry",
    "cherries",

    "grape",
    "grapes",
    "raisins",

    "apricot",
    "apricots",

    # Beans
    "black beans",
    "kidney beans",
    "pinto beans",
    "navy beans",
    "cannellini beans",

    "chickpea",
    "chickpeas",

    "lentils",
    "red lentils",
    "green lentils",

    "split peas",
    "peas",

    # Nuts
    "almond",
    "almonds",
    "cashew",
    "cashews",
    "walnut",
    "walnuts",
    "pecan",
    "pecans",
    "pistachio",
    "pistachios",
    "peanut",
    "peanuts",

    # Seeds
    "chia seeds",
    "flax seeds",
    "flaxseed",
    "sunflower seeds",
    "pumpkin seeds",
    "sesame seeds",

    # Oils
    "oil",
    "vegetable oil",
    "olive oil",
    "extra virgin olive oil",
    "canola oil",
    "avocado oil",
    "coconut oil",
    "sesame oil",
    "sunflower oil",

    # Herbs / spices
    "salt",
    "pepper",
    "black pepper",
    "fresh ground black pepper",
    "ground black pepper",

    "cinnamon",
    "ground cinnamon",

    "cumin",
    "ground cumin",

    "turmeric",
    "paprika",
    "chili powder",
    "cayenne pepper",

    "oregano",
    "dried oregano",

    "basil",
    "fresh basil",
    "dried basil",

    "parsley",
    "fresh parsley",

    "cilantro",
    "fresh cilantro",

    "thyme",
    "dried thyme",

    "bay leaf",
    "bay leaves",

    "cardamom",
    "nutmeg",

    # Baking
    "baking powder",
    "baking soda",
    "active dry yeast",
    "yeast",
    "vanilla",
    "vanilla extract",
    "cocoa powder",

    # Sauces / acids
    "soy sauce",
    "tomato sauce",
    "tomato paste",
    "ketchup",
    "mustard",
    "dijon mustard",

    "balsamic vinegar",
    "red wine vinegar",
    "white vinegar",
    "vinegar",
    "apple cider vinegar",

    "lemon juice",
    "fresh lemon juice",
    "lime juice",
    "fresh lime juice",
    "orange juice",

    # Plant protein
    "tofu",
    "tempeh",
    "seitan",

    "agar",
    "agar agar",

    "agave",
    "agave nectar",
    "agave syrup",

    "acorn",
    "acorn squash",
    "artichoke",
    "asparagus",
    "beet",
    "beets",
    "brussels sprouts",
}


# =========================================================
# VEGETARIAN EXACT
# =========================================================

VEGETARIAN_EXACT = {
    "milk",
    "whole milk",
    "low fat milk",
    "skim milk",
    "buttermilk",

    "cream",
    "heavy cream",
    "sour cream",
    "whipping cream",

    "cheese",
    "cheddar cheese",
    "mozzarella cheese",
    "parmesan cheese",
    "cream cheese",
    "ricotta cheese",
    "cottage cheese",
    "swiss cheese",
    "american cheese",
    "goat cheese",
    "feta cheese",

    "paneer",
    "non fat paneer",
    "amul paneer",

    "butter",
    "unsalted butter",
    "margarine",

    "yogurt",
    "yoghurt",
    "greek yogurt",

    "ice cream",

    "honey",
}


# =========================================================
# UNKNOWN EXACT
# =========================================================

UNKNOWN_EXACT = {
    "mayonnaise",
    "worcestershire sauce",

    "caesar dressing",
    "caesar salad dressing",

    "ranch dressing",

    "aioli",

    "marshmallow",
    "marshmallows",

    "pie crust",
    "pie shell",
    "pastry",

    "stuffing mix",

    "graham cracker",
    "graham crackers",

    "oreo",
    "oreo cookie",

    "cake mix",
    "cookie mix",
}


# =========================================================
# SAFE COMPOUND VEGAN RULES
# =========================================================
#
# These are deliberately conservative.
#
# We only classify a compound as vegan when its wording
# strongly indicates a plant ingredient or simple product.
#
# =========================================================

VEGAN_COMPOUND_PATTERNS = (

    # Fruits
    "apple juice",
    "apple juice concentrate",
    "apple cider",
    "apple peel",
    "apple chips",
    "apple rings",
    "apple jelly",
    "apple syrup",
    "apple butter",

    "banana chips",
    "banana flower",
    "banana flowers",
    "banana leaf",
    "banana leaves",
    "banana pulp",
    "banana puree",

    "orange juice",
    "orange juice concentrate",

    "lemon juice",
    "lime juice",

    # Vegetables
    "baby onion",
    "baby spinach",
    "baby spinach leaves",
    "baby red potato",
    "baking apple",
    "baking potato",

    # Rice
    "basmati rice",
    "brown rice",
    "white rice",
    "rice flour",
    "rice noodles",

    # Beans
    "bean mix",
    "bean soup mix",
    "bean salad",

    # Flour
    "bread flour",
    "cake flour",
    "whole wheat flour",
    "flour tortilla",
    "flour tortillas",
    "corn tortilla",
    "corn tortillas",
    "whole wheat tortilla",
    "whole wheat tortillas",

    # Pita
    "whole wheat pita",
    "whole wheat pitas",
    "pita bread",
    "pitas",

    # Herbs
    "basil leaves",
    "basil sprig",
    "basil sprigs",
    "basil seeds",

    # Oils
    "basil oil",
    "basil olive oil",

    # Sauces
    "tomato sauce",
    "tomato paste",
    "barbecue sauce",

    # Spices
    "achiote",
    "achiote oil",
    "achiote paste",
    "achiote powder",
    "achiote seeds",

    "adobo seasoning",
    "adobo sauce",

    "aleppo pepper",
    "african bird pepper",

    # Plant products
    "almond milk",
    "soy milk",
    "soya milk",
    "oat milk",
    "rice milk",
    "coconut milk",

    "almond butter",
    "peanut butter",

    "apple sweetened fortified soya milk",

    # Baking
    "active dry yeast",
    "baking powder",
    "baking soda",
)


# =========================================================
# SAFE COMPOUND VEGETARIAN RULES
# =========================================================

VEGETARIAN_COMPOUND_PATTERNS = (

    "cheese sauce",
    "cheese spread",
    "cream cheese",

    "parmesan cheese",
    "cheddar cheese",
    "mozzarella cheese",

    "cottage cheese",
    "ricotta cheese",

    "paneer cheese",
    "paneer",

    "milk chocolate",
    "chocolate milk",

    "cream sauce",
    "cream soup",

    "yogurt sauce",
    "yoghurt sauce",

    "almond butter",
    "peanut butter",
)


# =========================================================
# DAIRY INDICATORS
# =========================================================

DAIRY_WORDS = (
    "milk",
    "cream",
    "cheese",
    "yogurt",
    "yoghurt",
    "buttermilk",
)


# =========================================================
# CLASSIFIER
# =========================================================

def classify_ingredient(name: str) -> str:

    n = normalize(name)

    if not n:
        return UNKNOWN
        # =====================================================
    # MUSHROOM SAFETY OVERRIDE
    # =====================================================

    if n in {
        "oyster mushroom",
        "oyster mushrooms",
    }:
        return VEGAN

    # =====================================================
    # 1. VEGAN SUBSTITUTES
    # =====================================================

    if n in VEGAN_SUBSTITUTES:
        return VEGAN

    # =====================================================
    # 2. NON-VEGETARIAN PHRASES
    # =====================================================

    if n in NON_VEGETARIAN_PHRASES:
        return NON_VEGETARIAN

    # =====================================================
    # 3. EXPLICIT NON-VEGETARIAN EXACT
    # =====================================================

    if n in NON_VEGETARIAN_EXACT:
        return NON_VEGETARIAN

    # =====================================================
    # 4. ANIMAL WORD DETECTION
    # =====================================================

    meat_words = {
        "beef",
        "pork",
        "chicken",
        "ham",
        "bacon",
        "lamb",
        "mutton",
        "veal",
        "turkey",
        "duck",
        "venison",

        "salami",
        "pepperoni",
        "prosciutto",
        "mortadella",
        "bologna",

        "sausage",
        "chorizo",
        "meatball",
        "meatballs",

        "anchovy",
        "anchovies",
        "tuna",
        "salmon",
        "sardine",
        "sardines",
        "shrimp",
        "prawn",
        "prawns",
        "crab",
        "lobster",
        "clam",
        "clams",
        "mussel",
        "mussels",
        "oyster",
        "oysters",
        "octopus",
        "squid",
        "scallop",
        "scallops",

        "gelatin",
        "gelatine",
        "lard",
        "suet",
    }

    words = set(n.split())

    if words.intersection(meat_words):
        return NON_VEGETARIAN

    # =====================================================
    # 5. EGG
    # =====================================================

    if (
        n == "egg"
        or n == "eggs"
        or "egg white" in n
        or "egg whites" in n
        or "egg yolk" in n
        or "egg yolks" in n
    ):
        return NON_VEGETARIAN

    # =====================================================
    # 6. VEGAN EXACT
    # =====================================================

    if n in VEGAN_EXACT:
        return VEGAN

    # =====================================================
    # 7. VEGAN COMPOUND
    # =====================================================

    for pattern in VEGAN_COMPOUND_PATTERNS:

        if pattern in n:
            return VEGAN

    # =====================================================
    # 8. VEGETARIAN EXACT
    # =====================================================

    if n in VEGETARIAN_EXACT:
        return VEGETARIAN

    # =====================================================
    # 9. VEGETARIAN COMPOUND
    # =====================================================

    for pattern in VEGETARIAN_COMPOUND_PATTERNS:

        if pattern in n:
            return VEGETARIAN

    # =====================================================
    # 10. DAIRY DETECTION
    # =====================================================

    # Plant milk has already been handled above.
    if any(word in n for word in DAIRY_WORDS):

        return VEGETARIAN

    # =====================================================
    # 11. UNKNOWN PRODUCTS
    # =====================================================

    if n in UNKNOWN_EXACT:
        return UNKNOWN

    # =====================================================
    # 12. UNKNOWN
    # =====================================================

    return UNKNOWN


# =========================================================
# SAFETY TESTS
# =========================================================

SAFETY_TESTS = {

    "Egg": NON_VEGETARIAN,
    "Eggs": NON_VEGETARIAN,
    "Eggplant": VEGAN,

    "Chicken": NON_VEGETARIAN,
    "Chicken Broth": NON_VEGETARIAN,

    "Vegetarian Chicken": VEGAN,
    "Vegan Chicken": VEGAN,

    "Oyster": NON_VEGETARIAN,
    "Oyster Mushroom": VEGAN,
    "Oyster Mushrooms": VEGAN,

    "Paneer": VEGETARIAN,
    "Milk": VEGETARIAN,
    "Butter": VEGETARIAN,

    "Tofu": VEGAN,
    "Tempeh": VEGAN,
    "Seitan": VEGAN,

    "Soy Chorizo": VEGAN,
    "Vegetarian Pepperoni": VEGAN,

    "Ground Beef": NON_VEGETARIAN,

    "Gelatin": NON_VEGETARIAN,

    "Honey": VEGETARIAN,

    "Sugar": VEGAN,
    "Brown Sugar": VEGAN,
    "Flour": VEGAN,
    "All-Purpose Flour": VEGAN,

    "Olive Oil": VEGAN,

    "Vanilla Extract": VEGAN,

    "Mayonnaise": UNKNOWN,
    "Worcestershire Sauce": UNKNOWN,
}


# =========================================================
# COMPOUND TESTS
# =========================================================

COMPOUND_TESTS = {

    "Apple Juice": VEGAN,
    "Apple Chips": VEGAN,
    "Apple Butter": VEGAN,

    "Basmati Rice": VEGAN,
    "Brown Rice": VEGAN,

    "Basil Leaves": VEGAN,
    "Basil Oil": VEGAN,

    "Flour Tortilla": VEGAN,
    "Corn Tortilla": VEGAN,

    "Whole Wheat Pita": VEGAN,

    "Almond Milk": VEGAN,
    "Soy Milk": VEGAN,
    "Oat Milk": VEGAN,

    "Paneer Cheese": VEGETARIAN,
    "Cheese Sauce": VEGETARIAN,
}


# =========================================================
# MAIN
# =========================================================

def main():

    db = SessionLocal()

    try:

        ingredients = (
            db.query(Ingredient)
            .order_by(Ingredient.name.asc())
            .all()
        )

        print()
        print("=" * 70)
        print("INGREDIENT CLASSIFICATION - V9 DRY RUN")
        print("=" * 70)

        print()
        print(
            f"Total ingredients: "
            f"{len(ingredients):,}"
        )

        # =================================================
        # CLASSIFICATION
        # =================================================

        

        counts = {
            VEGAN: 0,
            VEGETARIAN: 0,
            NON_VEGETARIAN: 0,
            UNKNOWN: 0,
        }

        results = []

        changed = 0

        for ingredient in ingredients:

            new_type = classify_ingredient(
                ingredient.name
            )

            counts[new_type] += 1

            if ingredient.food_type != new_type:
                changed += 1

            results.append(
                (
                    ingredient.name,
                    ingredient.food_type,
                    new_type,
                )
            )
            

        # =================================================
        # RESULTS
        # =================================================

        print()
        print("-" * 70)
        print("CLASSIFICATION RESULTS")
        print("-" * 70)

        print(
            f"VEGAN:                   "
            f"{counts[VEGAN]:,}"
        )

        print(
            f"VEGETARIAN:              "
            f"{counts[VEGETARIAN]:,}"
        )

        print(
            f"NON-VEGETARIAN:          "
            f"{counts[NON_VEGETARIAN]:,}"
        )

        print(
            f"UNKNOWN:                 "
            f"{counts[UNKNOWN]:,}"
        )

        print()
        print(
            f"Rows that would change:  "
            f"{changed:,}"
        )

        # =================================================
        # SAFETY TESTS
        # =================================================

        print()
        print("=" * 70)
        print("IMPORTANT SAFETY TESTS")
        print("=" * 70)

        safety_failed = []

        for name, expected in SAFETY_TESTS.items():

            actual = classify_ingredient(name)

            if actual == expected:
                status = "PASS"
            else:
                status = "FAIL"

                safety_failed.append(
                    (
                        name,
                        expected,
                        actual,
                    )
                )

            print(
                f"{status:<6} "
                f"{name:<35} "
                f"-> {actual}"
            )

        # =================================================
        # COMPOUND TESTS
        # =================================================

        print()
        print("=" * 70)
        print("COMPOUND INGREDIENT TESTS")
        print("=" * 70)

        compound_failed = []

        for name, expected in COMPOUND_TESTS.items():

            actual = classify_ingredient(name)

            if actual == expected:
                status = "PASS"
            else:
                status = "FAIL"

                compound_failed.append(
                    (
                        name,
                        expected,
                        actual,
                    )
                )

            print(
                f"{status:<6} "
                f"{name:<35} "
                f"-> {actual}"
            )

        # =================================================
        # CHANGED SAMPLE
        # =================================================

        print()
        print("=" * 70)
        print("CHANGED CLASSIFICATION SAMPLE")
        print("=" * 70)

        displayed = 0

        for (
            name,
            old_type,
            new_type,
        ) in results:

            if old_type != new_type:

                print(
                    f"{name:<55} "
                    f"{str(old_type):<18} "
                    f"-> {new_type}"
                )

                displayed += 1

                if displayed >= 100:
                    break

        # =================================================
        # UNKNOWN SAMPLE
        # =================================================

        print()
        print("=" * 70)
        print("UNKNOWN SAMPLE")
        print("=" * 70)

        displayed = 0

        for (
            name,
            old_type,
            new_type,
        ) in results:

            if new_type == UNKNOWN:

                print(
                    f"  {name}"
                )

                displayed += 1

                if displayed >= 100:
                    break

        # =================================================
        # FINAL
        # =================================================

        print()
        print("=" * 70)

        if safety_failed or compound_failed:

            print(
                "TESTS FAILED"
            )

            print("=" * 70)

            if safety_failed:

                print()
                print(
                    "SAFETY TEST FAILURES:"
                )

                for (
                    name,
                    expected,
                    actual,
                ) in safety_failed:

                    print(
                        f"  {name}: "
                        f"expected={expected}, "
                        f"actual={actual}"
                    )

            if compound_failed:

                print()
                print(
                    "COMPOUND TEST FAILURES:"
                )

                for (
                    name,
                    expected,
                    actual,
                ) in compound_failed:

                    print(
                        f"  {name}: "
                        f"expected={expected}, "
                        f"actual={actual}"
                    )

            print()
            print(
                "DATABASE WAS NOT MODIFIED."
            )

        else:

            print(
                "ALL TESTS PASSED"
            )

            print("=" * 70)

            print()
            print(
                "DATABASE WAS NOT MODIFIED."
            )

            print(
                "No UPDATE was executed."
            )

            print(
                "No COMMIT was executed."
            )

        print("=" * 70)

    except Exception:

        db.rollback()

        raise

    finally:

        db.close()


# =========================================================
# ENTRY POINT
# =========================================================

if __name__ == "__main__":
    main()