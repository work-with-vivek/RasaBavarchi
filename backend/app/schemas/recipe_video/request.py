from pydantic import BaseModel


class RecipeVideoRequest(BaseModel):
    language: str = "en"
    voice: str = "female"