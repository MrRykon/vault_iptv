"""Rotate admin credentials locally without committing them to source control."""
import getpass
import os
import sys
from pathlib import Path
BACKEND = Path(__file__).resolve().parents[1] / 'backend'
os.chdir(BACKEND)
sys.path.insert(0, str(BACKEND))
from app.db.database import SessionLocal, Base, engine
from app.db.models import User
from app.core.security import get_password_hash
from app.services.auth_service import revoke_all_user_sessions
from dotenv import set_key

if __name__ == '__main__':
    password = getpass.getpass('Nueva contraseña para admin: ')
    if not password or password != getpass.getpass('Confirmar contraseña: '):
        raise SystemExit('Las contraseñas no coinciden')
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        admin = db.query(User).filter(User.custom_username == 'admin').first()
        if admin is None:
            admin = User(custom_username='admin', display_name='Administrador', admin_status=True, account_status='active', profile_type='standard')
            db.add(admin)
        admin.hashed_password = get_password_hash(password)
        db.flush()
        revoke_all_user_sessions(db, admin.id)
        db.commit()
    set_key(str(BACKEND / '.env'), 'SEED_ADMIN_PASSWORD', password)
    print('Credenciales admin actualizadas. Las sesiones anteriores han sido revocadas.')
