from app.utils.video_generator import VideoGenerator

generator = VideoGenerator()

video_path = generator.generate(
    image_path="media/images/paneer.jpg",
    audio_path="media/audio/b7b59693-8742-4c3f-93c2-1778aa121e6c.mp3",
)

print(video_path)