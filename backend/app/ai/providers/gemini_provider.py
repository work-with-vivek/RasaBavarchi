import json

from google import genai
from google.genai import types
from google.genai.errors import ClientError

from app.ai.prompts.pantry_scan import PANTRY_SCAN_PROMPT
from app.ai.prompts.recipe_explanation import (
    RECIPE_EXPLANATION_PROMPT,
)
from app.core.config import settings
from app.exceptions.ai import (
    AIConfigurationError,
    AIConnectionError,
    AIResponseError,
)


class GeminiProvider:
    def __init__(self):
        self.client = genai.Client(
            api_key=settings.gemini_api_key,
        )
        self.model = settings.gemini_model

    def _generate_json(
        self,
        prompt: str,
    ) -> dict:
        try:
            response = self.client.models.generate_content(
                model=self.model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                ),
            )

            return json.loads(response.text)

        except ClientError as exc:
            raise AIConfigurationError(str(exc)) from exc

        except json.JSONDecodeError as exc:
            raise AIResponseError(
                "Gemini returned invalid JSON."
            ) from exc

        except Exception as exc:
            raise AIConnectionError(str(exc)) from exc

    def _generate_json_from_image(
        self,
        prompt: str,
        image_bytes: bytes,
        mime_type: str,
    ) -> dict:
        try:
            response = self.client.models.generate_content(
                model=self.model,
                contents=[
                    prompt,
                    types.Part.from_bytes(
                        data=image_bytes,
                        mime_type=mime_type,
                    ),
                ],
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                ),
            )

            return json.loads(response.text)

        except ClientError as exc:
            raise AIConfigurationError(str(exc)) from exc

        except json.JSONDecodeError as exc:
            raise AIResponseError(
                "Gemini returned invalid JSON."
            ) from exc

        except Exception as exc:
            raise AIConnectionError(str(exc)) from exc

    def generate_recipe(
        self,
        ingredients: list[str],
        cuisine: str | None,
        dietary_preference: str | None,
        servings: int,
    ) -> dict:
        prompt = f"""
You are an expert chef and nutritionist.

Generate ONE delicious recipe.

Return ONLY valid JSON.

The JSON MUST exactly follow this schema:

{{
    "recipe_name": "string",
    "description": "string",
    "category": "Main Course",
    "cuisine": "Indian",
    "difficulty": "Easy",
    "ingredients": [
        {{
            "item": "string",
            "quantity": "string",
            "unit": "string"
        }}
    ],
    "instructions": [
        "Step 1",
        "Step 2"
    ],
    "prep_time_minutes": 15,
    "cook_time_minutes": 25,
    "servings": {servings},
    "nutrition": {{
        "calories": 0,
        "protein_g": 0,
        "carbs_g": 0,
        "fat_g": 0
    }}
}}

Available Ingredients:

{", ".join(ingredients)}

Cuisine:

{cuisine or "Any"}

Dietary Preference:

{dietary_preference or "None"}

Rules:

- Use only the provided ingredients whenever possible.
- If additional ingredients are required, keep them minimal.
- Recipe name should be unique and appetizing.
- Return ONLY JSON.
- Do NOT wrap the response in markdown.
- Do NOT explain anything.

Category:

Choose EXACTLY one from:
- Breakfast
- Lunch
- Dinner
- Snack
- Dessert
- Beverage
- Main Course
- Side Dish

Cuisine:

Choose the most appropriate cuisine.

Difficulty:

Choose EXACTLY one from:
- Easy
- Medium
- Hard
"""

        return self._generate_json(prompt)

    def generate_recipe_from_pantry(
        self,
        ingredients: list[str],
        cuisine: str | None,
        dietary_preference: str | None,
        servings: int,
    ) -> dict:
        prompt = f"""
You are an expert chef and nutritionist.

The user already has these ingredients in their pantry:

{", ".join(ingredients)}

Generate ONE recipe.

Return ONLY valid JSON.

The JSON MUST exactly follow this schema:

{{
    "recipe_name": "string",
    "description": "string",
    "category": "Dinner",
    "cuisine": "Indian",
    "difficulty": "Easy",
    "ingredients": [
        {{
            "item": "string",
            "quantity": "string",
            "unit": "string"
        }}
    ],
    "instructions": [
        "Step 1",
        "Step 2"
    ],
    "prep_time_minutes": 15,
    "cook_time_minutes": 25,
    "servings": {servings},
    "nutrition": {{
        "calories": 0,
        "protein_g": 0,
        "carbs_g": 0,
        "fat_g": 0
    }}
}}

Cuisine preference:

{cuisine or "Any"}

Dietary Preference:

{dietary_preference or "None"}

Rules:

- Use ONLY the ingredients from the pantry whenever possible.
- If something essential is missing, add at most 3 common pantry staples.
- Allowed pantry staples:
    - Water
    - Salt
    - Black Pepper
    - Cooking Oil
- Never introduce expensive or specialty ingredients.
- Recipe name should be unique and appetizing.
- Return ONLY JSON.
- Do NOT wrap the response in markdown.
- Do NOT explain anything.

Category:

Choose EXACTLY one from:
- Breakfast
- Lunch
- Dinner
- Snack
- Dessert

IMPORTANT:
- Do NOT use "Main Course".
- Do NOT use "Side Dish".
- Do NOT use "Beverage".
- The category MUST exactly match one of the five values above.

Cuisine:

Choose EXACTLY one from:
- Indian
- Chinese
- Italian
- Mexican

IMPORTANT:
- The cuisine MUST exactly match one of the four values above.
- Do NOT use any other cuisine.
- Do NOT return Mediterranean, American, Thai, French, Continental, or any other cuisine.
- If the ingredients could fit multiple cuisines, choose the most appropriate cuisine from the four allowed cuisines.
- If the user provided a cuisine preference and it is one of the four allowed cuisines, use that cuisine.

Difficulty:

Choose EXACTLY one from:
- Easy
- Medium
- Hard

The final JSON MUST contain only the allowed values specified above.
"""

        return self._generate_json(prompt)

    def generate_nutrition(
        self,
        recipe_name: str,
        servings: int,
        ingredients: list[str],
    ) -> dict:
        prompt = f"""
You are an expert nutritionist specializing in recipe nutrition analysis.

Calculate the estimated nutritional values for the recipe below.

Recipe name:

{recipe_name}

Number of servings:

{servings}

Ingredients:

{chr(10).join(f"- {ingredient}" for ingredient in ingredients)}

Return ONLY valid JSON.

The JSON MUST exactly follow this schema:

{{
    "calories": 0,
    "protein_g": 0,
    "carbs_g": 0,
    "fat_g": 0
}}

Rules:

- Estimate nutrition from the actual ingredients and their quantities.
- Use the provided quantities and units when calculating nutrition.
- Calculate nutrition for the ENTIRE recipe.
- The values must represent the complete recipe.
- Do NOT return per-serving values.
- calories must be in kcal.
- protein_g, carbs_g, and fat_g must be in grams.
- All values must be numeric.
- All values must be greater than or equal to 0.
- Do not return null values.
- Do not invent ingredients that are not listed.
- Make reasonable nutritional estimates when exact nutritional information is unavailable.
- Return ONLY JSON.
- Do NOT wrap the response in markdown.
- Do NOT explain anything.
"""

        return self._generate_json(prompt)

    def explain_recipe(
        self,
        question: str,
    ) -> str:
        prompt = RECIPE_EXPLANATION_PROMPT.format(
            question=question,
        )

        try:
            response = self.client.models.generate_content(
                model=self.model,
                contents=prompt,
            )

            return response.text.strip()

        except ClientError as exc:
            raise AIConfigurationError(str(exc)) from exc

        except Exception as exc:
            raise AIConnectionError(str(exc)) from exc

    def scan_pantry(
        self,
        image_bytes: bytes,
        mime_type: str,
    ) -> dict:
        return self._generate_json_from_image(
            prompt=PANTRY_SCAN_PROMPT,
            image_bytes=image_bytes,
            mime_type=mime_type,
        )