from fastapi import APIRouter, Depends, HTTPException, Response, Request
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
    import re
    match = re.fullmatch(r'/library/metadata/(\d+)/thumb(?:/\d+)?', url)
    if not match:
        raise HTTPException(400, 'Ruta de imagen Plex inválida')
    await plex_service.allowed_metadata(int(match[1]), current_user.profile_type)
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            response = await client.get(settings.PLEX_BASE_URL.rstrip('/') + url, headers={'X-Plex-Token': settings.PLEX_TOKEN})
            response.raise_for_status()
            return Response(content=response.content, media_type=response.headers.get('content-type', 'image/jpeg'))
    except httpx.HTTPError:
        raise HTTPException(502, 'No se pudo cargar la imagen de Plex')


@router.get('/children/{ident}')
async def plex_children(ident: int, current_user: User = Depends(get_current_user)):
    await plex_service.allowed_metadata(ident, current_user.profile_type)
    nodes = (await plex_service.plex_json(f'/library/metadata/{ident}/children')).get('Metadata', [])
    return [plex_service.normalize(n) for n in nodes]


@router.get('/stream/{ident}')
async def plex_stream(ident: int, request: Request, current_user: User = Depends(get_current_user)):
    node = await plex_service.allowed_metadata(ident, current_user.profile_type)
    try:
        key = node['Media'][0]['Part'][0]['key']
    except (KeyError, IndexError):
        raise HTTPException(409, 'No hay un archivo reproducible')
    if not key.startswith('/') or key.startswith('//'):
        raise HTTPException(502, 'Ruta de Plex inválida')
    client = httpx.AsyncClient(timeout=30)
    headers = {'X-Plex-Token': settings.PLEX_TOKEN}
    if request.headers.get('range'):
        headers['Range'] = request.headers['range']
    try:
        response = await client.send(client.build_request('GET', settings.PLEX_BASE_URL.rstrip('/') + key, headers=headers), stream=True)
        response.raise_for_status()
    except httpx.HTTPError:
        await client.aclose()
        raise HTTPException(502, 'Plex no pudo reproducir el archivo')
    async def chunks():
        try:
            async for chunk in response.aiter_raw():
                yield chunk
        finally:
            await response.aclose()
            await client.aclose()
    passthrough = {k: response.headers[k] for k in ('content-length', 'content-range', 'accept-ranges') if k in response.headers}
    return StreamingResponse(chunks(), status_code=response.status_code, media_type=response.headers.get('content-type', 'video/mp4'), headers=passthrough)
