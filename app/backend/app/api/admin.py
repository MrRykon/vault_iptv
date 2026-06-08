from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.core.dependencies import get_current_user, require_admin
from app.schemas.users import UserResponse, AdminUserUpdate, UserCreate, ExpirationUpdate
from app.db.models import User, UserSession, WatchHistory
from app.services import auth_service
from app.core.security import get_password_hash
from datetime import datetime, timedelta, timezone

router = APIRouter()

@router.get("/users", response_model=List[UserResponse])
def read_all_users(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    users = db.query(User).all()
    return users

@router.post("/users", response_model=UserResponse)
def create_user(user_in: UserCreate, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    existing = db.query(User).filter(User.custom_username == user_in.custom_username).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username already registered")
    
    hashed = get_password_hash(user_in.password)
    new_user = User(
        custom_username=user_in.custom_username,
        display_name=user_in.display_name or user_in.custom_username,
        hashed_password=hashed,
        account_status=user_in.account_status,
        profile_type=user_in.profile_type,
        admin_status=False
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.put("/users/{user_id}/suspend")
def suspend_user(user_id: int, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.account_status = "suspended"
    auth_service.revoke_all_user_sessions(db, user.id) # Kick them out
    db.commit()
    return {"message": "User suspended successfully"}

@router.put("/users/{user_id}/activate")
def activate_user(user_id: int, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.account_status = "active"
    db.commit()
    return {"message": "User activated successfully"}

@router.put("/users/{user_id}/profile-type")
def change_profile_type(user_id: int, update_data: AdminUserUpdate, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if update_data.profile_type:
        if update_data.profile_type not in ["standard", "kids"]:
            raise HTTPException(status_code=400, detail="Invalid profile type. Must be standard or kids.")
        user.profile_type = update_data.profile_type
    db.commit()
    return {"message": "User profile type adjusted"}

@router.put("/users/{user_id}/reset-password")
def reset_password(user_id: int, update_data: AdminUserUpdate, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    if not update_data.password:
        raise HTTPException(status_code=400, detail="Password is required")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.hashed_password = get_password_hash(update_data.password)
    auth_service.revoke_all_user_sessions(db, user.id)
    db.refresh(user)
    db.commit()
    return {"message": "Password reset successfully"}

@router.delete("/users/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.admin_status:
        raise HTTPException(status_code=400, detail="Cannot rigidly eradicate network Administrators natively")
    
    db.query(UserSession).filter(UserSession.user_id == user_id).delete(synchronize_session=False)
    db.query(WatchHistory).filter(WatchHistory.user_id == user_id).delete(synchronize_session=False)
    db.delete(user)
    db.commit()
    return {"message": "User permanently expunged"}

@router.put("/users/{user_id}/username")
def force_username_rotation(user_id: int, custom_username: str = Body(..., embed=True), db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    existing = db.query(User).filter(User.custom_username == custom_username).first()
    if existing and existing.id != user_id:
        raise HTTPException(status_code=400, detail="Username inherently captured by another profile")
        
    user.custom_username = custom_username
    db.commit()
    return {"message": "System login constraints updated directly"}

@router.put("/users/{user_id}/expiration")
def set_user_expiration(user_id: int, expr: ExpirationUpdate, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found natively")
    if user.admin_status:
        raise HTTPException(status_code=400, detail="Cannot expire Admin accounts!")
        
    if expr.days is not None and expr.days > 0:
        user.access_expires_at = datetime.now(timezone.utc) + timedelta(days=expr.days)
    else:
        user.access_expires_at = None
        
    db.commit()
    return {"message": "Account time bounds configured natively"}
