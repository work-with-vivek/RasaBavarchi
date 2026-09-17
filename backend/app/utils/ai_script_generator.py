from app.core.ai import AIClient


class AIScriptGenerator:
    def __init__(self):
        self.ai = AIClient()

    def generate(
        self,
        recipe_title: str,
        recipe_steps: list[str],
    ) -> str:
        steps = "\n".join(
            f"{index + 1}. {step}"
            for index, step in enumerate(recipe_steps)
        )

        prompt = f"""
You are a professional cooking instructor.

Create a friendly narration for a cooking video.

Recipe: {recipe_title}

Steps:
{steps}

Rules:
- Explain each step clearly.
- Keep the narration engaging.
- Use simple English.
- Do not use markdown.
- Keep it under 250 words.
"""

        return self.ai.generate(prompt)