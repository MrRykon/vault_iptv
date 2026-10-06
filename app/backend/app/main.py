import sys
import argparse
import uvicorn
import asyncio
from contextlib import asynccontextmanager, suppress
from pathlib import Path
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.core.dependencies import require_admin
from app.db.database import engine, Base
from app.db import models

from app.api import auth, users, admin, plex, iptv, updates, history, bugs, vod, notifications, xtream
from app.services.iptv_service import watch_playlists, sync_status

# Create DB tables
Base.metadata.create_all(bind=engine)

# Seed admin user if configured
from app.db.seed import seed_admin_user
seed_admin_user()

@asynccontextmanager
async def lifespan(app):
    task = asyncio.create_task(watch_playlists())
    yield
    task.cancel()
    with suppress(asyncio.CancelledError):
        await task

app = FastAPI(title="Vault Backend API", version=settings.LATEST_VERSION, lifespan=lifespan)

Path("app/media").mkdir(parents=True, exist_ok=True)
app.mount("/media", StaticFiles(directory="app/media"), name="media")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(admin.router, prefix="/admin", tags=["admin"])
app.include_router(plex.router, prefix="/plex", tags=["plex"])
app.include_router(iptv.router, prefix="/iptv", tags=["iptv"])
app.include_router(updates.router, prefix="/updates", tags=["updates"])
app.include_router(history.router, prefix="/history", tags=["history"])
app.include_router(bugs.router, prefix="/bugs", tags=["bugs"])
app.include_router(vod.router, prefix="/vod", tags=["vod"], dependencies=[Depends(require_admin)])
app.include_router(notifications.router, prefix="/notifications", tags=["notifications"])
app.include_router(xtream.router, prefix="/xtream", tags=["xtream"])

@app.get("/health")
def health():
    return {"service": "vault", "status": "online", "playlist_revision": sync_status["revision"]}

# Standalone HTML design preview, alongside the Flutter client.
preview_dir = Path(__file__).resolve().parents[3] / "web"
if preview_dir.is_dir():
    app.mount("/preview", StaticFiles(directory=preview_dir, html=True), name="html_preview")

# Mount the Flutter Web App
app.mount("/", StaticFiles(directory=settings.WEB_CLIENT_DIR, html=True), name="web_client")

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
