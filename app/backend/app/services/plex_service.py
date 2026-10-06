import httpx
from fastapi import HTTPException
from app.core.config import settings

kids_safe_keywords = {'kids', 'children', 'family', 'animation', 'infantil'}


def mock_library(profile_type):
    items = [
        {'id': 'mock_movie_1', 'title': 'Cosmic Adventure', 'type': 'movie', 'tags': ['Action', 'Sci-Fi'], 'is_kids_safe': False},
        {'id': 'mock_movie_2', 'title': 'Dark Thriller', 'type': 'movie', 'tags': ['Thriller'], 'is_kids_safe': False},
        {'id': 'mock_show_1', 'title': 'Cartoon Funtime', 'type': 'show', 'tags': ['Animation', 'Kids'], 'is_kids_safe': True},
    ]
    return [dict(item, mock=True) for item in items if profile_type != 'kids' or item['is_kids_safe']]


async def plex_json(path):
    if not settings.PLEX_BASE_URL or not settings.PLEX_TOKEN:
        raise HTTPException(503, 'Plex todavía no está configurado')
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            response = await client.get(settings.PLEX_BASE_URL.rstrip('/') + path,
                                        headers={'X-Plex-Token': settings.PLEX_TOKEN, 'Accept': 'application/json'})
            response.raise_for_status()
            return response.json().get('MediaContainer', {})
    except (httpx.HTTPError, ValueError):
        raise HTTPException(502, 'No se pudo contactar con Plex')


def normalize(node):
    tags = [g.get('tag', '') for g in node.get('Genre', [])]
    kind = node.get('type')
    return {'id': str(node.get('ratingKey')), 'title': node.get('title', 'Plex'), 'type': kind,
            'poster': f"/plex/image?url={node.get('thumb', '')}", 'tags': tags, 'mock': False,
            'is_kids_safe': any(t.lower() in kids_safe_keywords for t in tags),
            'stream_url': f"/plex/stream/{node.get('ratingKey')}" if kind in ('movie', 'episode') else None}


async def get_plex_library(profile_type):
    if settings.MOCK_PLEX:
        return mock_library(profile_type)
    sections = (await plex_json('/library/sections')).get('Directory', [])
    items = []
    for section in sections:
        if section.get('type') not in ('movie', 'show'):
            continue
        for node in (await plex_json(f"/library/sections/{section['key']}/all")).get('Metadata', []):
            item = normalize(node)
            if profile_type != 'kids' or item['is_kids_safe']:
                items.append(item)
    return items


async def allowed_metadata(ident, profile_type):
    if settings.MOCK_PLEX:
        raise HTTPException(409, 'Este contenido es una demostración; configura Plex para reproducirlo')
    nodes = (await plex_json(f'/library/metadata/{ident}')).get('Metadata', [])
    if not nodes:
        raise HTTPException(404, 'Contenido no encontrado')
    node = nodes[0]
    # Episodes inherit the series genre restrictions.
    if profile_type == 'kids':
        parent = node.get('grandparentRatingKey') or node.get('parentRatingKey')
        permission_node = node
        if parent:
            permission_node = (await plex_json(f'/library/metadata/{parent}')).get('Metadata', [{}])[0]
        if not normalize(permission_node)['is_kids_safe']:
            raise HTTPException(403, 'Contenido no apto para este perfil')
    return node
