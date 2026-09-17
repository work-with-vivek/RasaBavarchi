from uuid import UUID

from pydantic import BaseModel, ConfigDict


class CategoryInfo(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str


class CuisineInfo(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str


class DifficultyInfo(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str