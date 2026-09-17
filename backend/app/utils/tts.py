from pathlib import Path
from uuid import uuid4

from elevenlabs.client import ElevenLabs

from app.core.config import settings


class TextToSpeech:
    def __init__(self):
        self.client = ElevenLabs(
            api_key=settings.elevenlabs_api_key,
        )

        self.voice_id = settings.elevenlabs_voice_id

        self.output_dir = Path("media/audio")
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def generate(self, text: str) -> str:
        """
        Convert text to speech and save it as an MP3.

        Returns:
            Path to the generated audio file.
        """

        audio = self.client.text_to_speech.convert(
            voice_id=self.voice_id,
            text=text,
            model_id="eleven_multilingual_v2",
            output_format="mp3_44100_128",
        )

        file_path = self.output_dir / f"{uuid4()}.mp3"

        with open(file_path, "wb") as f:
            for chunk in audio:
                if chunk:
                    f.write(chunk)

        return str(file_path)