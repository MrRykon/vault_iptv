from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from jose import jwt, JWTError

from app.db.database import get_db
from app.db.models import User, UserSession
from app.core.config import settings

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        jti: str = payload.get("jti")
        if user_id is None or jti is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    # Validate session is active
    session_record = db.query(UserSession).filter(UserSession.token_jti == jti).first()
    if session_record is None or session_record.revoked_at is not None:
        raise HTTPException(status_code=401, detail="Session revoked or invalid.")
        
    user = db.query(User).filter(User.id == int(user_id)).first()
    if user is None:
        raise credentials_exception
        
    if user.account_status == "suspended":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been suspended. Please contact the administrator."
        )
        
    return user

def require_admin(current_user: User = Depends(get_current_user)):
    if not current_user.admin_status:
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user
