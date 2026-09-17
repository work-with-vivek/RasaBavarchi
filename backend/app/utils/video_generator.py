from pathlib import Path
from uuid import uuid4

from moviepy import AudioFileClip, ImageClip


class VideoGenerator:
    def __init__(self):
        self.output_dir = Path("media/videos")
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def generate(
        self,
        image_path: str,
        audio_path: str,
    ) -> str:
        """
        Create an MP4 video from an image and narration audio.

        Returns:
            Path to generated video.
        """

        audio = AudioFileClip(audio_path)

        video = (
            ImageClip(image_path)
            .with_duration(audio.duration)
            .with_audio(audio)
        )

        output_path = self.output_dir / f"{uuid4()}.mp4"

        video.write_videofile(
            str(output_path),
            fps=24,
            codec="libx264",
            audio_codec="aac",
        )

        audio.close()
        video.close()

        return str(output_path)