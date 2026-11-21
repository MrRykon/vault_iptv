"""Publish an already built, consistently signed APK; replace manifest atomically."""
import argparse
import hashlib
import json
import re
import shutil
import zipfile
from pathlib import Path

APP = Path(__file__).resolve().parents[1]


def publish(apk, version, build, notes='', force=False, root=None, platform='mobile'):
    if not re.fullmatch(r'\d+\.\d+\.\d+', version) or build < 1:
        raise ValueError('Use semantic version x.y.z and a positive build number')
    if platform not in ('mobile', 'tv'):
        raise ValueError('Platform must be mobile or tv')
    with zipfile.ZipFile(apk) as archive:
        if 'AndroidManifest.xml' not in archive.namelist():
            raise ValueError('Not an Android APK')
    root = Path(root or APP / 'releases')
    root.mkdir(parents=True, exist_ok=True)
    manifest = root / ('release_tv.json' if platform == 'tv' else 'release.json')
    if manifest.exists():
        previous = json.loads(manifest.read_text())
        if build <= previous['latest_build']:
            raise ValueError('Increase the Android build number before publishing another update')
    filename = f"{'VaultTV' if platform == 'tv' else 'Vault'}_{version}+{build}.apk"
    target = root / filename
    if target.resolve() != Path(apk).resolve():
        temp = root / (filename + '.tmp')
        shutil.copy2(apk, temp)
        temp.replace(target)
    with target.open('rb') as file:
        digest = hashlib.file_digest(file, 'sha256').hexdigest()
    data = dict(latest_version=version, latest_build=build, filename=filename,
                apk_sha256=digest, release_notes=notes, force_update=force)
    temp = manifest.with_suffix('.tmp')
    temp.write_text(json.dumps(data, indent=2), encoding='utf-8')
    temp.replace(manifest)
    print(f'Published Vault ({platform}) {version}+{build}')
    return data


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('apk', type=Path)
    parser.add_argument('--version', required=True)
    parser.add_argument('--build', type=int, required=True)
    parser.add_argument('--notes', default='Actualización de Vault')
    parser.add_argument('--force', action='store_true')
    parser.add_argument('--platform', choices=['mobile', 'tv'], default='mobile')
    args = parser.parse_args()
    publish(args.apk, args.version, args.build, args.notes, args.force, platform=args.platform)
