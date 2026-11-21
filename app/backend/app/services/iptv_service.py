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

COUNTRY_NAMES = {
    'AR': 'Argentina', 'BR': 'Brasil', 'CO': 'Colombia', 'EC': 'Ecuador',
    'IT': 'Italia', 'JP': 'Japón', 'MX': 'México', 'PY': 'Paraguay',
    'PE': 'Perú', 'PR': 'Puerto Rico', 'ES': 'España', 'US': 'Estados Unidos',
    'UY': 'Uruguay', 'VE': 'Venezuela', 'CL': 'Chile', 'BO': 'Bolivia',
    'CR': 'Costa Rica', 'CU': 'Cuba', 'DO': 'República Dominicana',
    'GT': 'Guatemala', 'HN': 'Honduras', 'NI': 'Nicaragua', 'PA': 'Panamá',
    'SV': 'El Salvador', 'FR': 'Francia', 'DE': 'Alemania', 'GB': 'Reino Unido',
    'UK': 'Reino Unido', 'CA': 'Canadá',
}

COUNTRY_TRANSLATIONS = {
    'argentina': 'Argentina', 'brasil': 'Brasil', 'brazil': 'Brasil',
    'colombia': 'Colombia', 'ecuador': 'Ecuador', 'italia': 'Italia',
    'italy': 'Italia', 'japon': 'Japón', 'japan': 'Japón', 'mexico': 'México',
    'méxico': 'México', 'paraguay': 'Paraguay', 'peru': 'Perú', 'perú': 'Perú',
    'puerto rico': 'Puerto Rico', 'espana': 'España', 'españa': 'España',
    'spain': 'España', 'united states': 'Estados Unidos', 'estados unidos': 'Estados Unidos',
    'usa': 'Estados Unidos', 'uruguay': 'Uruguay', 'venezuela': 'Venezuela',
    'chile': 'Chile', 'bolivia': 'Bolivia', 'costa rica': 'Costa Rica',
    'cuba': 'Cuba', 'republica dominicana': 'República Dominicana',
    'dominican republic': 'República Dominicana', 'guatemala': 'Guatemala',
    'honduras': 'Honduras', 'nicaragua': 'Nicaragua', 'panama': 'Panamá',
    'panamá': 'Panamá', 'el salvador': 'El Salvador', 'francia': 'Francia',
    'france': 'Francia', 'alemania': 'Alemania', 'germany': 'Alemania',
    'reino unido': 'Reino Unido', 'united kingdom': 'Reino Unido',
    'uk': 'Reino Unido', 'canada': 'Canadá', 'canadá': 'Canadá',
    'internacional': 'Internacional', 'international': 'Internacional'
}

CATEGORY_MAP = {
    'news': 'Noticias', 'noticias': 'Noticias',
    'sports': 'Deportes', 'sport': 'Deportes', 'deportes': 'Deportes',
    'kids': 'Infantil', 'children': 'Infantil', 'animation': 'Infantil', 'family': 'Infantil', 'infantil': 'Infantil',
    'movies': 'Películas', 'movie': 'Películas', 'cinema': 'Películas', 'film': 'Películas', 'peliculas': 'Películas',
    'series': 'Series',
    'music': 'Música', 'musica': 'Música',
    'documentary': 'Documentales', 'documentales': 'Documentales',
    'comedy': 'Comedia', 'comedia': 'Comedia',
    'entertainment': 'Entretenimiento', 'entretenimiento': 'Entretenimiento',
    'cooking': 'Cocina', 'cocina': 'Cocina',
    'culture': 'Cultura', 'cultura': 'Cultura',
    'education': 'Educación', 'educacion': 'Educación',
    'business': 'Negocios', 'negocios': 'Negocios',
    'religious': 'Religión', 'religion': 'Religión',
    'weather': 'Clima', 'clima': 'Clima',
    'travel': 'Viajes', 'outdoor': 'Viajes',
    'general': 'General', 'undefined': 'General', 'public': 'General'
}


def normalize_category(raw_group):
    if not raw_group:
        return 'General'
    groups = [g.strip().lower() for g in raw_group.split(';') if g.strip()]
    for g in groups:
        if g in CATEGORY_MAP:
            return CATEGORY_MAP[g]
    for g in groups:
        for key, val in CATEGORY_MAP.items():
            if key in g:
                return val
    return 'General'


def normalize_country(raw_name=None, raw_code=None, url=''):
    if raw_name:
        k = raw_name.strip().lower()
        if k in COUNTRY_TRANSLATIONS:
            return COUNTRY_TRANSLATIONS[k]
        if k.upper() in COUNTRY_NAMES:
            return COUNTRY_NAMES[k.upper()]
    if raw_code:
        ck = raw_code.strip().upper()
        if ck in COUNTRY_NAMES:
            return COUNTRY_NAMES[ck]
        if ck.lower() in COUNTRY_TRANSLATIONS:
            return COUNTRY_TRANSLATIONS[ck.lower()]
    if url:
        m = re.search(r'countries/([a-zA-Z]{2})\.m3u', url)
        if m:
            code = m.group(1).upper()
            return COUNTRY_NAMES.get(code, code)
    return raw_name or 'Internacional'


def is_kids_channel(category, raw_group=''):
    if category == 'Infantil':
        return True
    combined = f"{category} {raw_group}".lower()
    return any(word in combined for word in ('kids', 'children', 'cartoon', 'animation', 'family', 'infantil', 'niños'))


def parse_m3u(content, default_country=None, default_source_url=''):
    clean = content.lstrip('\ufeff \r\n')
    if '#EXTINF:' not in clean and not clean.startswith('#EXTM3U'):
        return
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
            raw_group = attrs.get('group-title', '')
            cat = normalize_category(raw_group)
            raw_country = attrs.get('tvg-country') or default_country
            country = normalize_country(raw_name=default_country, raw_code=raw_country, url=default_source_url)
            channel_id = hashlib.sha256(line.encode()).hexdigest()[:24]
            yield dict(
                channel_id=channel_id,
                channel_name=name,
                stream_url=line,
                logo_url=attrs.get('tvg-logo'),
                category=cat,
                raw_group_title=raw_group or cat,
                country=country,
                language=attrs.get('tvg-language'),
                is_kids_safe=is_kids_channel(cat, raw_group)
            )


async def collect_playlists():
    root_dirs = [
        Path(__file__).resolve().parents[4] / "playlists",  # D:\Projectos\vault_iptv-main\playlists
        Path(__file__).resolve().parents[3] / "playlists",  # D:\Projectos\vault_iptv-main\app\playlists
        Path(settings.PLAYLISTS_DIR),
    ]
    seen_dirs = set()
    seen_files = set()
    playlist_items = []  # list of (content, default_country, source_url)
    remote_sources = []  # list of (country_name, url)

    for r in root_dirs:
        try:
            r = r.resolve()
            if r in seen_dirs:
                continue
            seen_dirs.add(r)
            r.mkdir(parents=True, exist_ok=True)
            for path in sorted(r.iterdir()):
                if not path.is_file():
                    continue
                file_key = str(path.resolve()).lower()
                if file_key in seen_files:
                    continue
                seen_files.add(file_key)

                suffix = path.suffix.lower()
                if suffix in ('.m3u', '.m3u8', '.txt'):
                    text = await asyncio.to_thread(path.read_text, encoding='utf-8-sig', errors='replace')
                    clean_text = text.lstrip('\ufeff \r\n')
                    # If this file contains actual M3U stream channels directly:
                    if '#EXTINF:' in clean_text or clean_text.startswith('#EXTM3U'):
                        default_country = normalize_country(raw_name=path.stem)
                        playlist_items.append((text, default_country, ''))
                    else:
                        # File contains remote playlist links (e.g. "Country https://...")
                        for line in text.splitlines():
                            line = line.strip()
                            if not line or line.startswith('#'):
                                continue
                            m = re.match(r'^(.*?)\s*(https?://\S+)$', line)
                            if m:
                                country_lbl = m.group(1).strip()
                                link_url = m.group(2).strip()
                                remote_sources.append((country_lbl, link_url))
                            elif line.startswith('http'):
                                remote_sources.append(('', line))
        except Exception as e:
            log.warning(f"Error scanning playlist directory {r}: {e}")

    if settings.IPTV_SOURCE_URL:
        remote_sources.append(('', settings.IPTV_SOURCE_URL))

    # Deduplicate remote sources
    unique_sources = []
    seen_urls = set()
    for country, url in remote_sources:
        if url not in seen_urls:
            seen_urls.add(url)
            unique_sources.append((country, url))

    # Clean old cache entries
    current_urls = {u for _, u in unique_sources}
    for url in list(remote_cache.keys()):
        if url not in current_urls:
            del remote_cache[url]

    semaphore = asyncio.Semaphore(6)
    async with httpx.AsyncClient(timeout=25, follow_redirects=True) as client:
        async def fetch(country_label, url):
            cached = remote_cache.get(url, {})
            headers = {}
            if cached.get('etag'):
                headers['If-None-Match'] = cached['etag']
            if cached.get('modified'):
                headers['If-Modified-Since'] = cached['modified']
            async with semaphore:
                try:
                    response = await client.get(url, headers=headers)
                    if response.status_code == 304 and 'text' in cached:
                        return country_label, url, cached['text']
                    response.raise_for_status()
                    text = response.text
                    remote_cache[url] = {
                        'text': text,
                        'etag': response.headers.get('etag'),
                        'modified': response.headers.get('last-modified')
                    }
                    return country_label, url, text
                except Exception as req_err:
                    log.warning(f"Failed to fetch IPTV source {url}: {req_err}")
                    if 'text' in cached:
                        return country_label, url, cached['text']
                    return country_label, url, None

        if unique_sources:
            results = await asyncio.gather(*(fetch(c, u) for c, u in unique_sources), return_exceptions=True)
            for res in results:
                if isinstance(res, tuple) and res[2]:
                    country_lbl, src_url, content = res
                    playlist_items.append((content, country_lbl, src_url))

    return playlist_items


async def sync_iptv_channels(db):
    async with sync_lock:
        try:
            items = await collect_playlists()
            if not items:
                sync_status.update(error="No se encontraron listas de canales válidas.")
                return False

            raw_hash = hashlib.sha256(''.join(f'{len(c)}:{url}' for c, _, url in items).encode()).hexdigest()
            if raw_hash != sync_status['revision']:
                channels = {}
                for content, country_label, source_url in items:
                    try:
                        for ch in parse_m3u(content, default_country=country_label, default_source_url=source_url):
                            channels[ch['channel_id']] = ch
                    except Exception as parse_err:
                        log.warning(f"Error parsing M3U: {parse_err}")

                db.query(IPTVChannelCache).delete()
                db.add_all([
                    IPTVChannelCache(**c, is_active=True, last_refreshed_at=datetime.now(timezone.utc))
                    for c in channels.values()
                ])
                db.commit()
                sync_status.update(revision=raw_hash, channels=len(channels), error=None)
                log.info(f"IPTV Sync completed: {len(channels)} active channels across countries & categories.")
            sync_status['error'] = None
            return True
        except Exception as e:
            db.rollback()
            sync_status['error'] = f'Error al sincronizar listas: {e}'
            log.warning(f'Playlist refresh failed: {e}; preserving previous catalog')
            return False


async def watch_playlists():
    while True:
        with SessionLocal() as db:
            await sync_iptv_channels(db)
        await asyncio.sleep(max(5, settings.PLAYLIST_REFRESH_SECONDS))
