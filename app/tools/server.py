"""Cross-platform launcher shared by Windows and Raspberry Pi."""
import argparse
import getpass
import hashlib
import json
import os
import shutil
import socket
import subprocess
import venv
from pathlib import Path

APP = Path(__file__).resolve().parents[1]
BACKEND = APP / 'backend'
FRONTEND = APP / 'frontend'


def network_addresses():
    addresses = set()
    try:
        for entry in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            addresses.add(entry[4][0])
        # Routing only: UDP connect sends no packet.
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.connect(('192.0.2.1', 80))
            addresses.add(sock.getsockname()[0])
    except OSError:
        pass
    return sorted(a for a in addresses if not a.startswith('127.'))


def prepare_backend():
    target = BACKEND / '.venv'
    python = target / ('Scripts/python.exe' if os.name == 'nt' else 'bin/python')
    if not python.exists():
        venv.EnvBuilder(with_pip=True).create(target)
    subprocess.run([str(python), '-m', 'pip', 'install', '-r', 'requirements.txt', '-c', 'requirements.lock'], cwd=BACKEND, check=True)
    env = BACKEND / '.env'
    if not env.exists():
        import secrets
        password = os.environ.get('SEED_ADMIN_PASSWORD') or getpass.getpass('Contraseña inicial de admin: ')
        if not password or '\n' in password or '\r' in password or "'" in password:
            raise ValueError('Use a nonempty password without quotes or line breaks')
        env.write_text("SECRET_KEY=" + secrets.token_urlsafe(48) + "\nSEED_ADMIN_USERNAME=admin\nSEED_ADMIN_PASSWORD='" + password + "'\nMOCK_PLEX=true\n", encoding='utf-8')
        env.chmod(0o600)
    (BACKEND / 'app/media').mkdir(parents=True, exist_ok=True)
    return python


def refresh_build():
    flutter = shutil.which('flutter')
    if not flutter:
        print('Flutter no está en PATH: API y listas listas; compilar APK requiere Flutter + Android SDK.')
        return
    assets = FRONTEND / 'assets/playlists'
    assets.mkdir(parents=True, exist_ok=True)
    # Generated bundle: only known playlist files are reconciled.
    for path in assets.glob('*.m3u*'):
        if not (APP / 'playlists' / path.name).exists():
            path.unlink()
    for path in (APP / 'playlists').iterdir():
        if path.suffix in ('.m3u', '.m3u8'):
            shutil.copy2(path, assets / path.name)
    sources = []
    for directory in ('lib', 'assets', 'android'):
        sources.extend(p for p in (FRONTEND / directory).rglob('*') if p.is_file() and not any(part in ('build', '.gradle', '.cxx') for part in p.parts) and p.name not in ('local.properties', 'key.properties'))
    sources.extend([FRONTEND / 'pubspec.yaml', FRONTEND / 'pubspec.lock'])
    digest = hashlib.sha256(b''.join(str(p.relative_to(FRONTEND)).encode() + p.read_bytes() for p in sorted(sources))).hexdigest()
    state = APP / '.vault-build.json'
    saved = json.loads(state.read_text()) if state.exists() else {}
    if saved.get('web_digest') != digest or not (FRONTEND / 'build/web/index.html').exists():
        subprocess.run([flutter, 'pub', 'get', '--enforce-lockfile'], cwd=FRONTEND, check=True, shell=os.name == 'nt')
        subprocess.run([flutter, 'build', 'web', '--no-pub'], cwd=FRONTEND, check=True, shell=os.name == 'nt')
        saved['web_digest'] = digest
        state.write_text(json.dumps(saved), encoding='utf-8')
    if saved.get('apk_digest') == digest and (APP / 'releases/release.json').exists():
        return
    if not (FRONTEND / 'android/key.properties').exists():
        print('Cambios detectados. Configura android/key.properties para compilar y publicar un APK firmado. Se inicia la API sin publicar un APK.')
        return
    import re
    from publish_update import publish
    version, declared_build = re.search(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)', (FRONTEND / 'pubspec.yaml').read_text(), re.M).groups()
    manifest = APP / 'releases/release.json'
    previous = json.loads(manifest.read_text()) if manifest.exists() else {}
    if previous and tuple(map(int, version.split('.'))) < tuple(map(int, previous['latest_version'].split('.'))):
        raise ValueError('The display version cannot be lower than the published version')
    build = max(int(declared_build), int(previous.get('latest_build', 0)) + 1)
    subprocess.run([flutter, 'pub', 'get', '--enforce-lockfile'], cwd=FRONTEND, check=True, shell=os.name == 'nt')
    subprocess.run([flutter, 'build', 'apk', '--release', '--no-pub', f'--build-number={build}'], cwd=FRONTEND, check=True, shell=os.name == 'nt')
    outputs = FRONTEND / 'build/app/outputs/flutter-apk'
    artifact = outputs / 'app-release.apk'
    if not artifact.exists():
        artifact = outputs / f'Vault_v{version}.apk'
    if not artifact.exists():
        raise RuntimeError('Release APK not found in Flutter outputs')
    publish(artifact, version, int(build), 'Nueva versión de Vault', root=APP / 'releases')
    saved['apk_digest'] = digest
    state.write_text(json.dumps(saved), encoding='utf-8')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8000)
    parser.add_argument('--skip-build', action='store_true')
    args = parser.parse_args()
    python = prepare_backend()
    for address in network_addresses():
        print(f'Dirección del servidor para la app: http://{address}:{args.port}')
    if not args.skip_build:
        try:
            refresh_build()
        except (subprocess.CalledProcessError, ValueError, RuntimeError, OSError) as error:
            print(f'No se publicó el APK: {error}. Revisa la compilación y aumenta version/build en pubspec.yaml.')
    runtime = os.environ.copy()
    if (FRONTEND / 'build/web/index.html').exists():
        runtime['WEB_CLIENT_DIR'] = str(FRONTEND / 'build/web')
    subprocess.run([str(python), '-m', 'uvicorn', 'app.main:app', '--host', '0.0.0.0', '--port', str(args.port), '--no-access-log'], cwd=BACKEND, check=True, env=runtime)
