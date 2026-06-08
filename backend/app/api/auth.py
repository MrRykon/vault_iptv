from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta, datetime, timezone

from app.db.database import get_db
from app.core.config import settings
from app.core.dependencies import get_current_user
from app.services import auth_service
from app.schemas.auth import Token
from app.schemas.users import UserResponse, UserCreate
from app.db.models import User
from app.core.security import get_password_hash

router = APIRouter()

@router.post("/login", response_model=Token)
def login_for_access_token(db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()):
    user = auth_service.authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if user.account_status == "suspended":
         raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been suspended. Please contact the administrator."
        )
    if user.access_expires_at is not None and user.access_expires_at < datetime.now(timezone.utc):
         raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your Vault Access Pass has inherently expired organically."
        )

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth_service.create_access_token(
        db=db, user_id=user.id, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserResponse)
def read_users_me(current_user: User = Depends(get_current_user)):
    if current_user.access_expires_at is not None and current_user.access_expires_at < datetime.now(timezone.utc):
         raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your Vault Access Pass has fundamentally expired natively."
        )
    return current_user

@router.post("/logout")
def logout(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    auth_service.revoke_all_user_sessions(db, current_user.id)
    return {"message": "Logged out successfully"}

@router.post("/register", response_model=UserResponse)
def register_user(user_in: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.custom_username == user_in.custom_username).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username already taken")
    
    hashed = get_password_hash(user_in.password)
    new_user = User(
        custom_username=user_in.custom_username,
        display_name=user_in.custom_username,
        hashed_password=hashed,
        account_status="active",
        profile_type="standard",
        admin_status=False
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user
