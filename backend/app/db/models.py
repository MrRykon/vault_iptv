from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Float
from sqlalchemy.sql import func
from app.db.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    custom_username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    display_name = Column(String, nullable=True)
    avatar_url = Column(String, nullable=True)
    admin_status = Column(Boolean, default=False)
    account_status = Column(String, default="active") # active, suspended
    profile_type = Column(String, default="standard") # standard, kids
    access_expires_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class UserSession(Base):
    __tablename__ = "user_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    token_jti = Column(String, unique=True, index=True, nullable=False)
    issued_at = Column(DateTime(timezone=True), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    revoked_at = Column(DateTime(timezone=True), nullable=True)
    device_name = Column(String, nullable=True)

class WatchHistory(Base):
    __tablename__ = "watch_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content_source = Column(String, nullable=False) # 'plex', 'iptv'
    content_id = Column(String, nullable=False)
    content_title = Column(String, nullable=False)
    watched_at = Column(DateTime(timezone=True), default=func.now())
    position_seconds = Column(Float, nullable=False)
    is_kids_safe = Column(Boolean, default=False)

class IPTVChannelCache(Base):
    __tablename__ = "iptv_cache"

    id = Column(Integer, primary_key=True, index=True)
    channel_id = Column(String, index=True, nullable=False)
    channel_name = Column(String, nullable=False)
    country = Column(String, nullable=True)
    category = Column(String, nullable=True)
    stream_url = Column(String, nullable=False)
    logo_url = Column(String, nullable=True)
    language = Column(String, nullable=True)
    is_kids_safe = Column(Boolean, default=False)
    raw_group_title = Column(String, nullable=True)
    last_refreshed_at = Column(DateTime(timezone=True), server_default=func.now())
    is_active = Column(Boolean, default=True)

class BugReport(Base):
    __tablename__ = "bug_reports"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    message = Column(String, nullable=False)
    status = Column(String, default="open") # open, resolved
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class GlobalNotification(Base):
    __tablename__ = "notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    subject = Column(String, nullable=False)
    content = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    is_active = Column(Boolean, default=True)
