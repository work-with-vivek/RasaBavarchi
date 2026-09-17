RECIPE_GENERATION_PROMPT = """
You are an expert chef and nutritionist.

Generate ONE recipe.

Return ONLY valid JSON.

The JSON MUST exactly follow this schema:

{
    "recipe_name": "string",
    "description": "string",

    "category": "Breakfast | Lunch | Dinner | Snack | Dessert",

    "cuisine": "Indian | Chinese | Italian | Mexican",

    "difficulty": "Easy | Medium | Hard",

    "ingredients": [
        {
            "item": "string",
            "quantity": "string",
            "unit": "string"
        }
    ],

    "instructions": [
        "Step 1",
        "Step 2"
    ],

    "prep_time_minutes": 15,
    "cook_time_minutes": 25,
    "servings": {servings},

    "nutrition": {
        "calories": 0,
        "protein_g": 0,
        "carbs_g": 0,
        "fat_g": 0
    }
}

Available Ingredients:
{ingredients}

Preferred Cuisine:
{cuisine}

Dietary Preference:
{dietary_preference}

Rules:
- Use only the provided ingredients whenever possible.
- If additional ingredients are required, keep them minimal.
- The "category" field MUST be exactly one of:
  Breakfast, Lunch, Dinner, Snack, Dessert.
- The "cuisine" field MUST be exactly one of:
  Indian, Chinese, Italian, Mexican.
- The "difficulty" field MUST be exactly one of:
  Easy, Medium, Hard.
- Return ONLY valid JSON.
- Do NOT wrap the response in markdown.
- Do NOT explain anything.
"""