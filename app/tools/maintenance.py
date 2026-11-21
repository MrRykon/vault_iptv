"""Conservative cleanup. Never infer that source or user data is unused."""
import argparse
import shutil
import os
from pathlib import Path
APP = Path(__file__).resolve().parents[1]


def candidates(root=APP):
    root = Path(root)
    for parent in (root / 'backend/app', root / 'tools'):
        for path in parent.rglob('__pycache__'):
            if not path.is_symlink():
                yield path
    for name in ('frontend/build', 'frontend/.dart_tool', 'frontend/android/.gradle'):
        path = root / name
        if path.exists() and not path.is_symlink():
            yield path
    for parent in (root / 'releases', root / 'backend/app/media'):
        for path in parent.glob('*.tmp'):
            if not path.is_symlink():
                yield path


def size_bytes(path):
    if path.is_file():
        return path.stat().st_size
    total = 0
    for parent, _, files in os.walk(path, followlinks=False):
        for name in files:
            child = Path(parent) / name
            if not child.is_symlink():
                total += child.stat().st_size
    return total


def clean(root=APP, dry_run=False):
    root = Path(root).resolve()
    total = 0
    count = 0
    for path in candidates(root):
        # Parent symlinks must not turn cleanup into a deletion outside the app.
        if not path.resolve().is_relative_to(root) or any(parent.is_symlink() for parent in path.parents):
            continue
        size = size_bytes(path)
        print(('Se borraría: ' if dry_run else 'Limpiando: ') + str(path))
        if not dry_run:
            if path.is_dir():
                shutil.rmtree(path)
            else:
                path.unlink()
        total += size
        count += 1
    summary = {'items': count, 'bytes': total, 'dry_run': dry_run}
    print(f'{count} elementos; {total / (1024 * 1024):.2f} MB ' + ('recuperables.' if dry_run else 'liberados.'))
    return summary


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    clean(dry_run=args.dry_run)
