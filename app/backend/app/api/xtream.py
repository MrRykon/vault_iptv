"""Isolated Xtream gateway. Provider credentials are never stored by Vault."""
import asyncio
import ipaddress
import socket
from urllib.parse import urlsplit, quote
import httpx
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from app.core.dependencies import get_current_user
from app.db.models import User

router = APIRouter()


class XtreamRequest(BaseModel):
    server: str = Field(max_length=500)
    username: str = Field(min_length=1, max_length=200)
    password: str = Field(min_length=1, max_length=200)
    section: str = 'live'
    series_id: int | None = None


async def provider_origin(server):
    parsed = urlsplit(server.strip())
    if parsed.scheme not in ('http', 'https') or not parsed.hostname or parsed.username or parsed.password or parsed.query or parsed.fragment or parsed.path not in ('', '/'):
        raise HTTPException(400, 'Usa la dirección del proveedor: https://host:puerto')
    try:
        addresses = await asyncio.to_thread(socket.getaddrinfo, parsed.hostname, parsed.port or (443 if parsed.scheme == 'https' else 80), type=socket.SOCK_STREAM)
        if not addresses or any(not ipaddress.ip_address(addr[4][0]).is_global for addr in addresses):
            raise HTTPException(400, 'El proveedor Xtream debe usar una dirección pública')
    except (socket.gaierror, ValueError):
        raise HTTPException(400, 'No se pudo resolver el proveedor')
    return f'{parsed.scheme}://{parsed.netloc}'


async def provider_call(origin, credentials, action=None, series_id=None):
    params = {'username': credentials.username, 'password': credentials.password}
    if action:
        params['action'] = action
    if series_id is not None:
        params['series_id'] = series_id
    try:
        async with httpx.AsyncClient(timeout=15, follow_redirects=False) as client:
            response = await client.get(f'{origin}/player_api.php', params=params)
            response.raise_for_status()
            return response.json()
    except (httpx.HTTPError, ValueError):
        # Never echo the request URL: it contains provider credentials.
        raise HTTPException(502, 'El proveedor Xtream no respondió correctamente')


@router.post('/catalog')
async def catalog(credentials: XtreamRequest, user: User = Depends(get_current_user)):
    if user.profile_type == 'kids':
        raise HTTPException(403, 'Xtream no está habilitado para perfiles infantiles')
    actions = {'live': 'get_live_streams', 'vod': 'get_vod_streams', 'series': 'get_series'}
    if credentials.section not in actions:
        raise HTTPException(400, 'Sección desconocida')
    origin = await provider_origin(credentials.server)
    account = await provider_call(origin, credentials)
    if not isinstance(account, dict) or str(account.get('user_info', {}).get('auth')) != '1' or account.get('user_info', {}).get('status') != 'Active':
        raise HTTPException(401, 'Credenciales Xtream incorrectas o cuenta inactiva')
    raw = await provider_call(origin, credentials, actions[credentials.section])
    if not isinstance(raw, list):
        raise HTTPException(502, 'Catálogo Xtream inválido')
    items = []
    for item in raw:
        ident = str(item.get('series_id' if credentials.section == 'series' else 'stream_id', ''))
        if not ident.isdigit():
            continue
        ext = str(item.get('container_extension', 'mp4')) if credentials.section == 'vod' else 'm3u8'
        if not ext.isalnum():
            ext = 'mp4'
        kind = 'movie' if credentials.section == 'vod' else 'live'
        stream = f'{origin}/{kind}/{quote(credentials.username, safe="")}/{quote(credentials.password, safe="")}/{ident}.{ext}'
        items.append({'id': ident, 'title': item.get('name', 'Xtream'), 'poster': item.get('stream_icon') or item.get('cover'),
                      'category': item.get('category_id'), 'type': credentials.section,
                      'stream_url': None if credentials.section == 'series' else stream})
    return {'items': items}


@router.post('/episodes')
async def episodes(credentials: XtreamRequest, user: User = Depends(get_current_user)):
    if user.profile_type == 'kids':
        raise HTTPException(403, 'Xtream no está habilitado para perfiles infantiles')
    if credentials.series_id is None:
        raise HTTPException(400, 'Falta la serie')
    origin = await provider_origin(credentials.server)
    raw = await provider_call(origin, credentials, 'get_series_info', credentials.series_id)
    if not isinstance(raw, dict) or not isinstance(raw.get('episodes'), dict):
        raise HTTPException(502, 'Episodios Xtream inválidos')
    items = []
    for season in raw['episodes'].values():
        for episode in season:
            ident = str(episode.get('id', ''))
            ext = str(episode.get('container_extension', 'mp4'))
            if not ident.isdigit() or not ext.isalnum():
                continue
            items.append({'id': ident, 'title': episode.get('title', ident), 'type': 'episode',
                          'stream_url': f'{origin}/series/{quote(credentials.username, safe="")}/{quote(credentials.password, safe="")}/{ident}.{ext}'})
    return {'items': items}
