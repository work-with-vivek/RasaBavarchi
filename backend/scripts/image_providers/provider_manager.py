from __future__ import annotations

from .base import ImageProvider, ImageResult


class ImageProviderManager:
    """
    Coordinates multiple image providers.

    Providers are tried in the supplied order.

    The first provider that returns a non-None ImageResult
    wins.

    This class is intentionally generic so it can be used for
    both recipe images and ingredient images.
    """

    def __init__(
        self,
        providers: list[ImageProvider],
    ) -> None:
        self.providers = providers

    # =========================================================
    # SEARCH
    # =========================================================

    def search(
        self,
        query: str,
    ) -> ImageResult | None:
        """
        Try each configured provider until one returns an image.

        Provider failures are isolated so one broken provider
        does not prevent fallback providers from being tried.
        """

        for provider in self.providers:

            provider_name = (
                provider.__class__.__name__
            )

            print(
                f"  Trying {provider_name}..."
            )

            try:

                result = provider.search(
                    query
                )

            except Exception as exc:

                print(
                    f"  {provider_name} failed: "
                    f"{exc}"
                )

                continue

            if result is not None:

                print(
                    f"  {provider_name} found "
                    "a suitable image."
                )

                return result

            print(
                f"  {provider_name}: "
                "no suitable image."
            )

        return None