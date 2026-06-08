from sqlite3 import IntegrityError
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, timezone
from jose import jwt
import uuid

from app.core.config import settings
from app.db.models import User, UserSession
from app.core.security import verify_password, get_password_hash

def authenticate_user(db: Session, username: str, password: str):
    user = db.query(User).filter(User.custom_username == username).first()
    if not user:
        return False
    if not verify_password(password, user.hashed_password):
        return False
    return user

def create_access_token(db: Session, user_id: int, expires_delta: timedelta = None):
    to_encode = {"sub": str(user_id)}
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    # Generate unique session identifier
    jti = str(uuid.uuid4())
    to_encode.update({"exp": expire, "jti": jti})
    
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    
    # Track session in DB
    new_session = UserSession(
        user_id=user_id,
        token_jti=jti,
        issued_at=datetime.now(timezone.utc),
        expires_at=expire
    )
    db.add(new_session)
    db.commit()
    
    return encoded_jwt

def revoke_session(db: Session, jti: str):
    session_record = db.query(UserSession).filter(UserSession.token_jti == jti).first()
    if session_record:
        session_record.revoked_at = datetime.now(timezone.utc)
        db.commit()
        return True
    return False

def revoke_all_user_sessions(db: Session, user_id: int):
    sessions = db.query(UserSession).filter(UserSession.user_id == user_id, UserSession.revoked_at == None).all()
    now_ts = datetime.now(timezone.utc)
    for s in sessions:
        s.revoked_at = now_ts
    db.commit()
