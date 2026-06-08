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

    class Config:
        orm_mode = True
