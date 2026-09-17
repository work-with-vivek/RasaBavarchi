from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # =========================================================
    # Application
    # =========================================================

    app_name: str
    app_version: str
    app_env: str
    debug: bool

    # =========================================================
    # Server
    # =========================================================

    host: str
    port: int

    # =========================================================
    # Database
    # =========================================================

    database_url: str
    master_database_url: str

    # =========================================================
    # JWT
    # =========================================================

    secret_key: str
    algorithm: str
    access_token_expire_minutes: int
    # =========================================================
    # Email / SMTP
    # =========================================================

    smtp_host: str
    smtp_port: int = 587
    smtp_username: str
    smtp_password: str
    smtp_from_email: str
    smtp_from_name: str = "RasaBavarchi"

    # =========================================================
    # Gemini
    # =========================================================

    gemini_api_key: str
    gemini_model: str = "models/gemini-3.6-flash"

    # =========================================================
    # ElevenLabs
    # =========================================================

    elevenlabs_api_key: str
    elevenlabs_voice_id: str

    # =========================================================
    # YouTube
    # =========================================================

    youtube_api_key: str
    youtube_base_url: str = (
        "https://www.googleapis.com/youtube/v3/search"
    )

    # =========================================================
    # Pexels
    # =========================================================

    pexels_api_key: str

    # =========================================================
    # Pydantic Settings
    # =========================================================

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


# =============================================================
# Cached Settings
# =============================================================

@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()