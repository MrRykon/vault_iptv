from pydantic import BaseModel, field_serializer
from typing import Optional
from datetime import datetime, timezone

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

    @field_serializer('access_expires_at')
    def serialize_expiry(self, value):
        # SQLite strips timezone metadata; stored timestamps are UTC.
        return value.replace(tzinfo=timezone.utc) if value is not None else None

    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None

class AdminUserUpdate(BaseModel):
    account_status: Optional[str] = None
    profile_type: Optional[str] = None
    password: Optional[str] = None

class ExpirationUpdate(BaseModel):
    days: Optional[int] = None
