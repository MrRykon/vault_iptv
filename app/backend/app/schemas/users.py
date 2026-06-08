from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    custom_username: str
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    account_status: Optional[str] = "active"
    profile_type: Optional[str] = "standard"
    access_expires_at: Optional[datetime] = None

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: int
    admin_status: bool
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        orm_mode = True

class UserUpdate(BaseModel):
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None

class AdminUserUpdate(BaseModel):
    account_status: Optional[str] = None
    profile_type: Optional[str] = None
    password: Optional[str] = None

class ExpirationUpdate(BaseModel):
    days: Optional[int] = None
