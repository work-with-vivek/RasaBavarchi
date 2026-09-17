from __future__ import annotations

from .base import ImageResult


class IngredientProviderManager:
    """
    Coordinates ingredient image providers.

    Providers are tried in order.

    Example:
        Pexels
            ↓
        Wikimedia
            ↓
        no image

    Each provider is responsible for returning only an acceptable
    ingredient image according to its own quality rules.
    """

    def __init__(
        self,
        providers: list,
    ) -> None:
        self.providers = providers

    def search(
        self,
        ingredient_name: str,
    ) -> ImageResult | None:
        """
        Try ingredient providers in configured order.

        The first successful result is returned.
        Provider failures are isolated so a broken provider does
        not stop the complete ingredient import.
        """

        name = (
            ingredient_name or ""
        ).strip()

        if not name:
            return None

        for provider in self.providers:

            provider_name = (
                provider.__class__.__name__
            )

            print(
                f"  Trying {provider_name}..."
            )

            try:

                result = provider.search(
                    name
                )

            except Exception as exc:

                print(
                    f"  {provider_name} failed: "
                    f"{exc}"
                )

                continue

            if result is not None:

                print(
                    f"  {provider_name} "
                    "found a suitable image."
                )

                return result

            print(
                f"  {provider_name}: "
                "no suitable image."
            )

        return None