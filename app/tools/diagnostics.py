"""Read-only diagnostics. Does not expose credentials or delete user data."""
import argparse
import json
import shutil
import sys
from pathlib import Path
from urllib.request import urlopen
from maintenance import candidates, size_bytes

APP = Path(__file__).resolve().parents[1]


def report(root=APP, check_server=False):
    root = Path(root).resolve()
    playlists = root / 'playlists'
    files = [p for p in playlists.iterdir() if p.is_file() and p.suffix.lower() in ('.txt', '.m3u', '.m3u8')] if playlists.exists() else []
    caches = [p for p in candidates(root) if p.resolve().is_relative_to(root) and not any(parent.is_symlink() for parent in p.parents)]
    data = {
        'python': sys.version.split()[0],
        'python_supported': sys.version_info >= (3, 12),
        'backend_environment': (root / 'backend/.venv').is_dir(),
        'configuration_present': (root / 'backend/.env').is_file(),
        'tools': {name: bool(shutil.which(name)) for name in ('flutter', 'java', 'git')},
        'playlist_files': len(files),
        'published_apks': len(list((root / 'releases').glob('*.apk'))),
        'web_build_present': (root / 'frontend/build/web/index.html').is_file(),
        'html_preview_present': (root.parent / 'web/index.html').is_file(),
        'cache_bytes': sum(size_bytes(p) for p in caches),
        'disk_free_bytes': shutil.disk_usage(root).free,
    }
    if check_server:
        try:
            with urlopen('http://127.0.0.1:8000/health', timeout=3) as response:
                status = json.load(response)
                data['local_server'] = 'online' if status.get('service') == 'vault' and status.get('status') == 'online' else 'unrecognized'
        except Exception:
            data['local_server'] = 'offline'
    return data


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Diagnóstico de Vault sin modificar archivos.')
    parser.add_argument('--json', action='store_true', help='Informe para herramientas externas')
    parser.add_argument('--check-server', action='store_true', help='Comprobar el servidor local en el puerto 8000')
    args = parser.parse_args()
    data = report(check_server=args.check_server)
    if args.json:
        print(json.dumps(data, indent=2))
    else:
        print('VAULT · DIAGNÓSTICO')
        print(f'Python: {data["python"]} · compatible: {data["python_supported"]}')
        print(f'Entorno backend: {data["backend_environment"]} · configuración: {data["configuration_present"]}')
        print('Herramientas en PATH: ' + ', '.join(f'{key}: {value}' for key, value in data['tools'].items()))
        print(f'Listas: {data["playlist_files"]} · APK publicados: {data["published_apks"]}')
        print(f'Web Flutter: {data["web_build_present"]} · Vista HTML: {data["html_preview_present"]}')
        print(f'Cachés recuperables: {data["cache_bytes"] / (1024 ** 2):.2f} MB')
        print(f'Espacio libre: {data["disk_free_bytes"] / (1024 ** 3):.2f} GB')
        if args.check_server:
            print('Servidor local: ' + data['local_server'])
