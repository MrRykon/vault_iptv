from pydantic import BaseModel
from typing import Optional

class IPTVChannelResponse(BaseModel):
    channel_id: str
    channel_name: str
    country: Optional[str] = None
    category: Optional[str] = None
    stream_url: str
    logo_url: Optional[str] = None
    language: Optional[str] = None
    is_kids_safe: bool
    current_program: Optional[str] = None
    program_time: Optional[str] = None
    is_online: Optional[bool] = True

    class Config:
        from_attributes = True
