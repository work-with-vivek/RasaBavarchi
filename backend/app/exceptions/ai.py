class AIServiceError(Exception):
    """Base exception for AI service."""


class AIResponseError(AIServiceError):
    """Raised when AI returns an invalid response."""


class AIConnectionError(AIServiceError):
    """Raised when AI provider cannot be reached."""


class AIConfigurationError(AIServiceError):
    """Raised when AI provider is misconfigured."""