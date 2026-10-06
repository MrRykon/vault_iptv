"""Reconcile the complete playlist directory with the channel cache."""
import asyncio
import hashlib
import logging
import re
from pathlib import Path
from datetime import datetime, timezone
from urllib.parse import urlparse
import httpx
from app.core.config import settings
from app.db.database import SessionLocal
from app.db.models import IPTVChannelCache

log = logging.getLogger(__name__)
sync_lock = asyncio.Lock()
sync_status = {"revision": "", "channels": 0, "error": None}


def is_kids_channel(group_title):
    return any(word in (group_title or '').lower() for word in ('kids', 'children', 'cartoon', 'animation', 'family', 'infantil'))


def parse_m3u(content):
    if not content.lstrip('\ufeff \r\n').startswith('#EXTM3U'):
        raise ValueError('Expected an extended M3U playlist')
    metadata = None
    for line in content.splitlines():
        line = line.strip()
        if line.startswith('#EXTINF:'):
            attrs = dict(re.findall(r'([\w-]+)="([^"]*)"', line))
            title = re.split(r',(?=(?:[^"]*"[^"]*")*[^"]*$)', line, maxsplit=1)
            name = attrs.get('tvg-name') or (title[1].strip() if len(title) > 1 else 'Canal')
            metadata = (attrs, name)
        elif line and not line.startswith('#') and metadata:
            attrs, name = metadata
            metadata = None
            if urlparse(line).scheme not in ('http', 'https'):
                continue
            group = attrs.get('group-title', 'General')
            yield dict(channel_id=hashlib.sha256(line.encode()).hexdigest()[:24], channel_name=name,
                       stream_url=line, logo_url=attrs.get('tvg-logo'), category=group,
                       raw_group_title=group, country=attrs.get('tvg-country'),
                       language=attrs.get('tvg-language'), is_kids_safe=is_kids_channel(group))


async def collect_playlists():
    root = Path(settings.PLAYLISTS_DIR)
    root.mkdir(parents=True, exist_ok=True)
    contents = []
    async with httpx.AsyncClient(timeout=20, follow_redirects=True) as client:
        for path in sorted(root.iterdir()):
            if path.suffix.lower() in ('.m3u', '.m3u8'):
                contents.append(path.read_text(encoding='utf-8-sig'))
            elif path.suffix.lower() == '.txt':
                for url in path.read_text(encoding='utf-8-sig').splitlines():
                    url = url.strip()
                    if not url or url.startswith('#'):
                        continue
                    if urlparse(url).scheme not in ('http', 'https'):
                        raise ValueError('Playlist links must use HTTP or HTTPS')
                    response = await client.get(url)
                    response.raise_for_status()
                    contents.append(response.text)
        if settings.IPTV_SOURCE_URL:
            response = await client.get(settings.IPTV_SOURCE_URL)
            response.raise_for_status()
            contents.append(response.text)
    return contents


async def sync_iptv_channels(db):
    async with sync_lock:
        try:
            contents = await collect_playlists()
            channels = {c['channel_id']: c for text in contents for c in parse_m3u(text)}
            revision = hashlib.sha256('\n'.join(contents).encode()).hexdigest()
            if revision != sync_status['revision']:
                # Fetch and parse first: a broken file must not erase the last good catalog.
                db.query(IPTVChannelCache).delete()
                db.add_all([IPTVChannelCache(**c, is_active=True, last_refreshed_at=datetime.now(timezone.utc)) for c in channels.values()])
                db.commit()
            sync_status.update(revision=revision, channels=len(channels), error=None)
            return True
        except Exception:
            db.rollback()
            sync_status['error'] = 'No se pudo leer una lista. Se conserva el último catálogo válido.'
            log.warning('Playlist refresh failed; preserving the previous catalog')
            return False


async def watch_playlists():
    while True:
        with SessionLocal() as db:
            await sync_iptv_channels(db)
        await asyncio.sleep(max(5, settings.PLAYLIST_REFRESH_SECONDS))
