from fastapi import APIRouter, Depends, BackgroundTasks, Request, Response, HTTPException
import hashlib
from urllib.parse import urlparse
import httpx
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.core.dependencies import get_current_user, require_admin
from app.db.models import User, IPTVChannelCache
from app.schemas.iptv import IPTVChannelResponse
from app.services.epg_service import get_channel_epg

router = APIRouter()

@router.get("/channels", response_model=List[IPTVChannelResponse])
def get_channels(request: Request, response: Response, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    revision = iptv_service.sync_status['revision']
    headers = {'Cache-Control': 'private, no-cache', 'Vary': 'Authorization'}
    if revision:
        # Authentication happens before checking validators. Child catalogues have their own ETag.
        etag = '"' + hashlib.sha256(f'{revision}:{current_user.profile_type}'.encode()).hexdigest() + '"'
        headers['ETag'] = etag
        validators = [value.strip().removeprefix('W/') for value in request.headers.get('if-none-match', '').split(',')]
        if etag in validators or '*' in validators:
            return Response(status_code=304, headers=headers)
    response.headers.update(headers)
    query = db.query(IPTVChannelCache).filter(IPTVChannelCache.is_active == True)
    
    # Enforce kids filter securely at db query level
    if current_user.profile_type == "kids":
        query = query.filter(IPTVChannelCache.is_kids_safe == True)
        
    channels = query.all()
    results = []
    for c in channels:
        epg = get_channel_epg(c.channel_id, c.channel_name, c.category, c.stream_url)
        results.append(IPTVChannelResponse(
            channel_id=c.channel_id,
            channel_name=c.channel_name,
            country=c.country,
            category=c.category,
            stream_url=c.stream_url,
            logo_url=c.logo_url,
            language=c.language,
            is_kids_safe=c.is_kids_safe,
            current_program=epg["current_program"],
            program_time=epg["program_time"],
            is_online=epg["is_online"]
        ))
    return results

from app.services import iptv_service
import asyncio

@router.post("/refresh")
async def admin_refresh_channels(db: Session = Depends(get_db), current_user: User = Depends(require_admin)):
    success = await iptv_service.sync_iptv_channels(db)
    return {"success": success, **iptv_service.sync_status}

@router.get("/status")
def playlist_status(current_user: User = Depends(require_admin)):
    return iptv_service.sync_status

class ParseURLRequest(BaseModel):
    url: str = Field(min_length=1, max_length=2000)
    name: str = Field(default="", max_length=200)


@router.post("/parse-url")
async def parse_playlist_url(payload: ParseURLRequest):
    url = payload.url.strip()
    parsed = urlparse(url)
    if parsed.scheme not in ("http", "https") or not parsed.netloc:
        raise HTTPException(status_code=400, detail="URL inválida. Debe iniciar con http:// o https://")

    list_name = payload.name.strip() or parsed.hostname or "Lista IPTV"
    try:
        async with httpx.AsyncClient(timeout=20, follow_redirects=True) as client:
            resp = await client.get(url)
            resp.raise_for_status()
            text = resp.text
    except httpx.HTTPError:
        raise HTTPException(status_code=502, detail="No se pudo descargar la lista desde la URL proporcionada")

    channels = []
    if "#EXTINF:" in text:
        for ch in iptv_service.parse_m3u(text, default_country=None, default_source_url=url):
            epg = get_channel_epg(ch["channel_id"], ch["channel_name"], ch["category"], ch["stream_url"])
            channels.append({**ch, **epg})
    elif "#EXT-X-" in text or any(url.lower().split("?")[0].endswith(ext) for ext in (".m3u8", ".mp4", ".ts", ".mkv")):
        cid = hashlib.sha256(url.encode()).hexdigest()[:24]
        epg = get_channel_epg(cid, list_name, "General", url)
        channels.append({
            "channel_id": cid,
            "channel_name": list_name,
            "country": "Internacional",
            "category": "General",
            "stream_url": url,
            "logo_url": None,
            "language": None,
            "is_kids_safe": False,
            **epg,
        })

    if not channels:
        raise HTTPException(status_code=422, detail="La URL no contiene canales IPTV válidos")

    return {"channels": channels}


@router.get("/vod")
def get_vod_catalog(current_user: User = Depends(get_current_user)):
    import os
    from urllib.parse import quote
    
    MOVIES_DIR = r"D:\Movies"
    movies = []
    
    # Map physical files securely into the native VOD array natively gracefully
    if os.path.exists(MOVIES_DIR):
        for i, file in enumerate(os.listdir(MOVIES_DIR)):
            if file.endswith(('.mkv', '.mp4', '.avi')):
                title = os.path.splitext(file)[0].replace(".", " ").title()
                encoded_file = quote(file)
                movies.append({
                    "id": f"loc-{i}",
                    "title": title,
                    "poster_url": "https://image.tmdb.org/t/p/w500/ju10W5jqEPGJeQ0XQ64X2qJj3yU.jpg",
                    "stream_url": f"http://10.29.148.140:8000/vod/stream?filename={encoded_file}&quality=original",
                })
                
    return movies
