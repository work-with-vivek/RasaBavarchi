from elevenlabs.client import ElevenLabs

from app.core.config import settings

client = ElevenLabs(api_key=settings.elevenlabs_api_key)

voices = client.voices.get_all()

for voice in voices.voices:
    print(f"Name: {voice.name}")
    print(f"ID: {voice.voice_id}")
    print("-" * 40)