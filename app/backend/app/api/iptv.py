from fastapi import APIRouter, Depends, BackgroundTasks, Request, Response
import hashlib
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.core.dependencies import get_current_user, require_admin
from app.db.models import User, IPTVChannelCache
from app.schemas.iptv import IPTVChannelResponse

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
        
    return query.all()

from app.services import iptv_service
import asyncio

@router.post("/refresh")
async def admin_refresh_channels(db: Session = Depends(get_db), current_user: User = Depends(require_admin)):
    success = await iptv_service.sync_iptv_channels(db)
    return {"success": success, **iptv_service.sync_status}

@router.get("/status")
def playlist_status(current_user: User = Depends(require_admin)):
    return iptv_service.sync_status

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
                
    # Fallback bounds gracefully conditionally
    if not movies:
        movies = [
           {
               "id": "vod-fallback",
               "title": "Tears of Steel (Fallback Array)",
               "poster_url": "https://image.tmdb.org/t/p/w500/ju10W5jqEPGJeQ0XQ64X2qJj3yU.jpg",
               "stream_url": "http://demo.unified-streaming.com/video/tears-of-steel/tears-of-steel.ism/.m3u8",
           }
        ]
        
    return movies
