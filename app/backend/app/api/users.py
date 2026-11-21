from fastapi import APIRouter, Depends, Body, UploadFile, File
import shutil
import os
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.schemas.users import UserUpdate, UserResponse
from app.db.models import User
from app.core.security import get_password_hash

router = APIRouter()

@router.get("/profile", response_model=UserResponse)
def read_own_profile(current_user: User = Depends(get_current_user)):
    return current_user

@router.put("/profile", response_model=UserResponse)
def update_own_profile(update_data: UserUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if update_data.display_name is not None:
        current_user.display_name = update_data.display_name
    if update_data.avatar_url is not None:
        current_user.avatar_url = update_data.avatar_url
    db.commit()
    db.refresh(current_user)
    return current_user

@router.put("/profile/password")
def handle_internal_password_switch(password: str = Body(..., embed=True), db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    hashed = get_password_hash(password)
    current_user.hashed_password = hashed
    db.commit()
    return {"message": "Self-Authorization mappings successfully modified"}

@router.post("/profile/avatar")
async def upload_avatar(file: UploadFile = File(...), db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    os.makedirs("app/media/avatars", exist_ok=True)
    extension = file.filename.split(".")[-1]
    file_path = f"app/media/avatars/user_{current_user.id}.{extension}"
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    current_user.avatar_url = f"http://10.29.148.140:8000/media/avatars/user_{current_user.id}.{extension}"
    db.commit()
    db.refresh(current_user)
    return current_user
