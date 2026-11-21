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

# Each Android client (phone/tablet vs TV) has its own package id, so each needs its own APK.
MANIFESTS = {'mobile': 'release.json', 'tv': 'release_tv.json'}
FILENAME_PATTERN = r'Vault(TV)?_[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+\.apk'


@lru_cache(maxsize=4)
def artifact_digest(path, modified_ns, size):
    # Invalidate after any normal file replacement/edit; avoid rehashing a large APK for every client poll.
    with Path(path).open('rb') as file:
        return hashlib.file_digest(file, 'sha256').hexdigest()


def published_release(platform='mobile'):
    root = Path(settings.RELEASES_DIR)
    manifest = root / MANIFESTS.get(platform, MANIFESTS['mobile'])
    if not manifest.exists():
        return None
    try:
        data = json.loads(manifest.read_text(encoding='utf-8'))
        name = data['filename']
        if not re.fullmatch(FILENAME_PATTERN, name):
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
def check_updates(request: Request, platform: str = 'mobile'):
    data = published_release(platform)
    if not data:
        return {'available': False}
    ver = data.get('version') or data.get('latest_version')
    bld = data.get('build_number') or data.get('latest_build')
    return {
        **data,
        'platform': platform if platform in MANIFESTS else 'mobile',
        'version': ver,
        'latest_version': ver,
        'build_number': bld,
        'latest_build': bld,
        'available': True,
        'apk_download_url': str(request.url_for('download_apk', filename=data['filename']))
    }


@router.get('/apk/{filename}', name='download_apk')
def download_apk(filename: str):
    for platform in MANIFESTS:
        data = published_release(platform)
        if data and filename == data['filename']:
            return FileResponse(Path(settings.RELEASES_DIR) / filename, media_type='application/vnd.android.package-archive', filename=filename)
    raise HTTPException(404, 'APK no publicado')
