import uuid

from app.schemas.recipe_video.response import RecipeVideoResponse
from app.utils.ai_script_generator import AIScriptGenerator
from app.utils.tts import TextToSpeech
from app.utils.video_generator import VideoGenerator


class RecipeVideoService:
    def __init__(self, repository):
        self.repository = repository
        self.script_generator = AIScriptGenerator()
        self.tts = TextToSpeech()
        self.video_generator = VideoGenerator()

    def generate_video(
        self,
        recipe_id: uuid.UUID,
    ) -> RecipeVideoResponse:

        recipe = self.repository.get_recipe(recipe_id)

        if recipe is None:
            return RecipeVideoResponse(
                status="failed",
                video_url=None,
                duration=None,
                message="Recipe not found.",
            )

        recipe_steps = [
            step.strip()
            for step in recipe.instructions.split("\n")
            if step.strip()
        ]

        script = self.script_generator.generate(
            recipe_title=recipe.title,
            recipe_steps=recipe_steps,
        )

        audio_path = self.tts.generate(script)

        # TODO: Replace this with recipe.image_url later.
        image_path = "media/images/paneer.jpg"

        video_path = self.video_generator.generate(
            image_path=image_path,
            audio_path=audio_path,
        )

        return RecipeVideoResponse(
            status="completed",
            video_url=video_path,
            duration=None,
            message=(
                "Recipe explanation video generated "
                "successfully."
            ),
        )