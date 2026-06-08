from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timezone

from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.db.models import User, WatchHistory, IPTVChannelCache
from app.schemas.history import HistoryRecord, HistoryResponse

router = APIRouter()

@router.get("/", response_model=List[HistoryResponse])
def get_user_history(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    query = db.query(WatchHistory).filter(WatchHistory.user_id == current_user.id)
    if current_user.profile_type == "kids":
       query = query.filter(WatchHistory.is_kids_safe == True)
    
    # Order by most recently watched
    return query.order_by(WatchHistory.watched_at.desc()).all()

@router.post("/record")
def record_watch_progress(payload: HistoryRecord, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    history_node = db.query(WatchHistory).filter(
        WatchHistory.user_id == current_user.id,
        WatchHistory.content_source == payload.content_source,
        WatchHistory.content_id == payload.content_id
    ).first()

    if history_node:
        history_node.position_seconds = payload.position_seconds
        history_node.watched_at = datetime.now(timezone.utc)
    else:
        new_node = WatchHistory(
            user_id=current_user.id,
            content_source=payload.content_source,
            content_id=payload.content_id,
            content_title=payload.content_title,
            position_seconds=payload.position_seconds,
            is_kids_safe=payload.is_kids_safe
        )
        db.add(new_node)
    
    db.commit()
    return {"status": "recorded"}

@router.get("/last_iptv")
def get_last_iptv_channel(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    last_watch = db.query(WatchHistory).filter(WatchHistory.user_id == current_user.id, WatchHistory.content_source == 'iptv').order_by(WatchHistory.watched_at.desc()).first()
    
    if not last_watch:
        return {"channel_name": None, "stream_url": None, "channel_id": None}
        
    stream_node = db.query(IPTVChannelCache).filter(
        (IPTVChannelCache.channel_id == last_watch.content_id) | 
        (IPTVChannelCache.channel_name == last_watch.content_id)
    ).first()
    
    if not stream_node:
        return {"channel_name": last_watch.content_title, "stream_url": None, "channel_id": last_watch.content_id}
        
    return {
        "channel_name": stream_node.channel_name,
        "stream_url": stream_node.stream_url,
        "channel_id": stream_node.channel_id
    }
