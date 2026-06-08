from fastapi import APIRouter, Depends, HTTPException, Response
from fastapi.responses import StreamingResponse
from typing import List
import httpx
import urllib.parse
from app.core.config import settings

from app.core.dependencies import get_current_user
from app.db.models import User
from app.services import plex_service

router = APIRouter()

@router.get("/status")
def get_plex_status(current_user: User = Depends(get_current_user)):
    return {"status": "online", "mock_mode": settings.MOCK_PLEX}

@router.get("/library")
async def get_plex_library(current_user: User = Depends(get_current_user)):
    return await plex_service.get_plex_library(current_user.profile_type)

@router.get("/search")
async def search_plex_library(q: str, current_user: User = Depends(get_current_user)):
    items = await plex_service.get_plex_library(current_user.profile_type)
    return [item for item in items if q.lower() in item["title"].lower()]

@router.get("/image")
async def proxy_plex_image(url: str, current_user: User = Depends(get_current_user)):
    """Secure reverse proxy for plex poster binaries with strict cache controls"""
    if settings.MOCK_PLEX:
        # Mock payload fallback
        return Response(content=b"", media_type="image/png", headers={"Cache-Control": "public, max-age=604800"})

    if not url:
        raise HTTPException(status_code=400, detail="Missing URL")
        
    try:
        # Reconstruct exactly with standard token header to obfuscate network
        headers = {"X-Plex-Token": settings.PLEX_TOKEN}
        target = f"{settings.PLEX_BASE_URL}{url}"
        
        client = httpx.AsyncClient()
        req = client.build_request("GET", target, headers=headers)
        res = await client.send(req, stream=True)
        
        async def stream_generator():
            async for chunk in res.aiter_raw():
                yield chunk
            await client.aclose()
            
        return StreamingResponse(
            stream_generator(), 
            media_type=res.headers.get("content-type", "image/jpeg"),
            headers={"Cache-Control": "public, max-age=604800"} # Cache natively!
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail="Image fetch failed")
