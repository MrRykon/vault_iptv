import httpx
import re
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from app.core.config import settings
from app.db.models import IPTVChannelCache

def is_kids_channel(group_title: str) -> bool:
    if not group_title:
        return False
    kids_keywords = ["kids", "children", "cartoon", "animation", "family"]
    return any(keyword in group_title.lower() for keyword in kids_keywords)

async def sync_iptv_channels(db: Session):
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(settings.IPTV_SOURCE_URL, timeout=30.0)
            response.raise_for_status()
            content = response.text
            
            lines = content.splitlines()
            if not lines or not lines[0].startswith("#EXTM3U"):
                print("Invalid M3U file format.")
                return

            print("Starting IPTV Sync from ", settings.IPTV_SOURCE_URL)
            
            # Simple M3U parser extracting tvg-id, tvg-name, tvg-logo, group-title
            extinf_pattern = re.compile(r'#EXTINF:.*?(tvg-id="([^"]*)")?.*?(tvg-name="([^"]*)")?.*?(tvg-logo="([^"]*)")?.*?(group-title="([^"]*)")?,(.*)')
            
            # Clean up old active channels by marking them inactive before processing new batch
            db.query(IPTVChannelCache).update({"is_active": False})
            
            current_extinf = None
            channels_added = 0
            
            for line in lines:
                line = line.strip()
                if not line:
                    continue
                    
                if line.startswith("#EXTINF:"):
                    current_extinf = line
                elif not line.startswith("#") and current_extinf:
                    match = extinf_pattern.search(current_extinf)
                    if match:
                        channel_id = match.group(2) or match.group(9) # Use ID or name as fallback
                        channel_name = match.group(4) or match.group(9)
                        logo_url = match.group(6)
                        group_title = match.group(8)
                        
                        # Validate the entry, fallback if needed
                        if channel_name:
                            is_kids_safe = is_kids_channel(group_title)
                            
                            # Upsert logic
                            channel_record = db.query(IPTVChannelCache).filter(IPTVChannelCache.channel_name == channel_name).first()
                            
                            if channel_record:
                                channel_record.channel_id = channel_id or channel_name
                                channel_record.stream_url = line
                                channel_record.logo_url = logo_url
                                channel_record.raw_group_title = group_title
                                channel_record.category = group_title
                                channel_record.is_kids_safe = is_kids_safe
                                channel_record.is_active = True
                                channel_record.last_refreshed_at = datetime.now(timezone.utc)
                            else:
                                new_channel = IPTVChannelCache(
                                    channel_id=channel_id or channel_name,
                                    channel_name=channel_name,
                                    stream_url=line,
                                    logo_url=logo_url,
                                    raw_group_title=group_title,
                                    category=group_title,
                                    is_kids_safe=is_kids_safe,
                                    is_active=True
                                )
                                db.add(new_channel)
                            
                            channels_added += 1
                    current_extinf = None
            
            db.commit()
            print(f"IPTV Sync completed silently. Refreshed/Added {channels_added} channels.")
            
    except Exception as e:
        print(f"Failed to sync IPTV channels silently: {e}")
        db.rollback()
