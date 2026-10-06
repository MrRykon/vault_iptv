"""Conservative cleanup. Never infer that source or user data is unused."""
import argparse
import shutil
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


def clean(root=APP, dry_run=False):
    for path in candidates(root):
        print(('Se borraría: ' if dry_run else 'Limpiando: ') + str(path))
        if not dry_run:
            if path.is_dir():
                shutil.rmtree(path)
            else:
                path.unlink()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    clean(dry_run=args.dry_run)
