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
remote_cache = {}


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
    urls = []
    async with httpx.AsyncClient(timeout=20, follow_redirects=True) as client:
        for path in sorted(root.iterdir()):
            if path.suffix.lower() in ('.m3u', '.m3u8'):
                contents.append(await asyncio.to_thread(path.read_text, encoding='utf-8-sig'))
            elif path.suffix.lower() == '.txt':
                text = await asyncio.to_thread(path.read_text, encoding='utf-8-sig')
                for url in text.splitlines():
                    url = url.strip()
                    if not url or url.startswith('#'):
                        continue
                    if urlparse(url).scheme not in ('http', 'https'):
                        raise ValueError('Playlist links must use HTTP or HTTPS')
                    urls.append(url)
        if settings.IPTV_SOURCE_URL:
            urls.append(settings.IPTV_SOURCE_URL)
        # Limit parallel requests and discard caches for sources no longer configured.
        urls = list(dict.fromkeys(urls))
        for url in set(remote_cache) - set(urls):
            del remote_cache[url]
        semaphore = asyncio.Semaphore(4)

        async def fetch(url):
            cached = remote_cache.get(url, {})
            headers = {}
            if cached.get('etag'):
                headers['If-None-Match'] = cached['etag']
            if cached.get('modified'):
                headers['If-Modified-Since'] = cached['modified']
            async with semaphore:
                response = await client.get(url, headers=headers)
            if response.status_code == 304 and 'text' in cached:
                return cached['text']
            response.raise_for_status()
            text = response.text
            # Validate before retaining a remote body; invalid data must be retried.
            if not text.lstrip('\ufeff \r\n').startswith('#EXTM3U'):
                raise ValueError('Expected an extended M3U playlist')
            remote_cache[url] = {'text': text, 'etag': response.headers.get('etag'),
                                 'modified': response.headers.get('last-modified')}
            return text

        results = await asyncio.gather(*(fetch(url) for url in urls), return_exceptions=True)
        for result in results:
            if isinstance(result, Exception):
                raise result
            contents.append(result)
    return contents


async def sync_iptv_channels(db):
    async with sync_lock:
        try:
            contents = await collect_playlists()
            revision = hashlib.sha256(''.join(f'{len(text)}:{text}' for text in contents).encode()).hexdigest()
            if revision != sync_status['revision']:
                channels = {c['channel_id']: c for text in contents for c in parse_m3u(text)}
                # Fetch and parse first: a broken file must not erase the last good catalog.
                db.query(IPTVChannelCache).delete()
                db.add_all([IPTVChannelCache(**c, is_active=True, last_refreshed_at=datetime.now(timezone.utc)) for c in channels.values()])
                db.commit()
                sync_status.update(revision=revision, channels=len(channels))
            sync_status['error'] = None
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
