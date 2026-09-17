import httpx

from app.core.config import settings
from backend.app.schemas.recipe_video_schema import (
    RecipeVideo,
    RecipeVideoResponse,
)


class RecipeVideoService:
    async def search(
        self,
        recipe_name: str,
    ) -> RecipeVideoResponse:

        params = {
            "part": "snippet",
            "q": f"{recipe_name} recipe",
            "type": "video",
            "maxResults": 5,
            "key": settings.youtube_api_key,
        }

        async with httpx.AsyncClient() as client:
            response = await client.get(
                settings.youtube_base_url,
                params=params,
            )

            response.raise_for_status()

        data = response.json()

        videos = []

        for item in data.get("items", []):
            snippet = item["snippet"]

            videos.append(
                RecipeVideo(
                    title=snippet["title"],
                    video_id=item["id"]["videoId"],
                    thumbnail=snippet["thumbnails"]["high"]["url"],
                    channel=snippet["channelTitle"],
                )
            )

        return RecipeVideoResponse(
            videos=videos,
        )