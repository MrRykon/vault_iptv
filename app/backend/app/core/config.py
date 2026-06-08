import os
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
    IPTV_SOURCE_URL: str = "https://raw.githubusercontent.com/MrRykon/vault_iptv/refs/heads/main/channels.m3u"

    # Updates
    LATEST_VERSION: str = "1.0.6"
    UPDATE_MESSAGE: str = "Plex VOD Tracking, Offline Live TV, Universal Search natively, and Picture-in-Picture."
    MINIMUM_SUPPORTED_VERSION: str = "0.9.0"
    APK_DOWNLOAD_URL: str = "http://10.29.148.140:8000/media/Vault_v0.0.0.apk"
    APK_SHA256: str = ""
    FORCE_UPDATE: bool = False

    class Config:
        env_file = ".env"
        extra = "ignore" # ignores extra variables in the .env rather than raising error.

settings = Settings()
