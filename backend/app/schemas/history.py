from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class HistoryRecord(BaseModel):
    content_source: str
    content_id: str
    content_title: str
    position_seconds: float
    is_kids_safe: bool = False

class HistoryResponse(HistoryRecord):
    id: int
    watched_at: datetime

    class Config:
        orm_mode = True
