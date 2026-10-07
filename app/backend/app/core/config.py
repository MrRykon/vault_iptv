import os
from pathlib import Path
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "sqlite:///./vault.db"

    # Security
    SECRET_KEY: str = "replace_with_long_random_secret"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 43200
    REFRESH_TOKEN_EXPIRE_MINUTES: int = 43200

    # App Bootstrap
    SEED_ADMIN_ON_FIRST_RUN: bool = True
    SEED_ADMIN_USERNAME: str = "admin"
    SEED_ADMIN_PASSWORD: str = "change_this_immediately"

    # Plex
    MOCK_PLEX: bool = True
    PLEX_BASE_URL: str = ""
    PLEX_TOKEN: str = ""

    # IPTV
    IPTV_SOURCE_URL: str = ""
    PLAYLISTS_DIR: str = "../playlists"
    PLAYLIST_REFRESH_SECONDS: int = 30
    RELEASES_DIR: str = "../releases"
    ALLOW_PUBLIC_REGISTRATION: bool = False
    WEB_CLIENT_DIR: str = str(Path(__file__).resolve().parents[4] / "web")

    # Updates
    LATEST_VERSION: str = "0.0.5"
    UPDATE_MESSAGE: str = "Centro de administración y mejoras de diseño."
    MINIMUM_SUPPORTED_VERSION: str = "0.0.5"
    APK_SHA256: str = ""
    FORCE_UPDATE: bool = False

    class Config:
        env_file = ".env"
        extra = "ignore" # ignores extra variables in the .env rather than raising error.

settings = Settings()
