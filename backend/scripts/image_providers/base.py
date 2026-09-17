from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass(frozen=True)
class ImageResult:
    """
    Result returned by an image provider.
    """

    url: str
    mime_type: str


class ImageProvider(ABC):
    """
    Base interface for image providers.

    The same interface is used for:
    - recipe image providers
    - ingredient image providers
    """

    @abstractmethod
    def search(
        self,
        query: str,
    ) -> ImageResult | None:
        """
        Find a suitable image for the supplied query.

        Returns:
            ImageResult when a suitable image is found.
            None when no suitable image is available.
        """
        raise NotImplementedError