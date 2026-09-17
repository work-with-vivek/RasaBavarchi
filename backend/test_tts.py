from app.utils.tts import TextToSpeech

tts = TextToSpeech()

path = tts.generate(
    """
    Welcome to RasaBavarchi.

    Today we are going to prepare delicious Paneer Butter Masala.

    First heat oil.

    Add onions.

    Cook until golden brown.

    Add tomatoes and spices.

    Finally add paneer and simmer for five minutes.

    Your delicious Paneer Butter Masala is ready.
    """
)

print(path)