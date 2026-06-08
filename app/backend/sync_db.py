import asyncio
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import SessionLocal
from app.services.iptv_service import sync_iptv_channels

async def main():
    db = SessionLocal()
    await sync_iptv_channels(db)
    db.close()

asyncio.run(main())
