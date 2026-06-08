from fastapi import APIRouter
from app.core.config import settings

router = APIRouter()

@router.get("/check")
def check_updates():
    return {
        "latest_version": settings.LATEST_VERSION,
        "minimum_supported_version": settings.MINIMUM_SUPPORTED_VERSION,
        "apk_download_url": settings.APK_DOWNLOAD_URL,
        "apk_sha256": settings.APK_SHA256,
        "release_notes": "New layout and bug fixes.",
        "force_update": settings.FORCE_UPDATE
    }
