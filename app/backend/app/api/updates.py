"""Only advertise published APKs that exist and match their checksum."""
import hashlib
import json
import re
from pathlib import Path
from functools import lru_cache
from fastapi import APIRouter, Request, HTTPException
from fastapi.responses import FileResponse
from app.core.config import settings

router = APIRouter()


@lru_cache(maxsize=4)
def artifact_digest(path, modified_ns, size):
    # Invalidate after any normal file replacement/edit; avoid rehashing a large APK for every client poll.
    with Path(path).open('rb') as file:
        return hashlib.file_digest(file, 'sha256').hexdigest()


def published_release():
    root = Path(settings.RELEASES_DIR)
    manifest = root / 'release.json'
    if not manifest.exists():
        return None
    try:
        data = json.loads(manifest.read_text(encoding='utf-8'))
        name = data['filename']
        if not re.fullmatch(r'Vault_[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+\.apk', name):
            raise ValueError('Invalid filename')
        path = root / name
        stat = path.stat()
        digest = artifact_digest(str(path.resolve()), stat.st_mtime_ns, stat.st_size)
        if digest != data['apk_sha256']:
            raise ValueError('Checksum mismatch')
        return data
    except (OSError, ValueError, KeyError):
        raise HTTPException(503, 'La versión publicada no es válida; vuelve a publicarla')


@router.get('/check')
def check_updates(request: Request):
    data = published_release()
    if not data:
        return {'available': False}
    return {**data, 'available': True, 'apk_download_url': str(request.url_for('download_apk', filename=data['filename']))}


@router.get('/apk/{filename}', name='download_apk')
def download_apk(filename: str):
    data = published_release()
    if not data or filename != data['filename']:
        raise HTTPException(404, 'APK no publicado')
    return FileResponse(Path(settings.RELEASES_DIR) / filename, media_type='application/vnd.android.package-archive', filename=filename)
