from fastapi import APIRouter, Request
from app.core.config import settings

router = APIRouter()

@router.get("/check")
def check_updates(request: Request):
    base_url = str(request.base_url)
    apk_url = f"{base_url}media/Vault_v{settings.LATEST_VERSION}.apk"
    return {
        "latest_version": settings.LATEST_VERSION,
        "minimum_supported_version": settings.MINIMUM_SUPPORTED_VERSION,
        "apk_download_url": apk_url,
        "apk_sha256": settings.APK_SHA256,
        "release_notes": settings.UPDATE_MESSAGE,
        "force_update": settings.FORCE_UPDATE
    }
