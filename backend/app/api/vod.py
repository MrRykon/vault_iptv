from fastapi import APIRouter, Depends, Request, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.core.dependencies import get_current_user
import os
import subprocess

router = APIRouter()

# Global mount pointer
MOVIES_DIR = r"D:\Movies"

@router.get("/scan")
def scan_local_directory(db: Session = Depends(get_db)):
    # Scan D:\Movies and register them natively
    found_movies = []
    if os.path.exists(MOVIES_DIR):
        for file in os.listdir(MOVIES_DIR):
            if file.endswith(('.mkv', '.mp4', '.avi')):
                found_movies.append(file)
    return {"status": "scanned", "found": found_movies}

def get_transcode_command(file_path: str, quality: str):
    # Dynamic FFMPEG transcode binding limits
    target_scale = ""
    if quality == "1080p": target_scale = "-vf scale=-1:1080"
    elif quality == "720p": target_scale = "-vf scale=-1:720"
    elif quality == "1440p": target_scale = "-vf scale=-1:1440"
    
    return [
        "ffmpeg", "-i", file_path,
        "-c:v", "libx264", "-preset", "ultrafast",
        "-crf", "23", "-maxrate", "5M", "-bufsize", "10M",
        *target_scale.split(),
        "-c:a", "aac", "-b:a", "128k", "-ac", "2",
        "-f", "matroska", "pipe:1"
    ]

@router.get("/stream")
def stream_local_movie(filename: str, quality: str = "original", req: Request = None):
    # Security traversal check
    if ".." in filename or "/" in filename or "\\" in filename:
        raise HTTPException(status_code=400, detail="Invalid filename parameters natively.")

    file_path = os.path.join(MOVIES_DIR, filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File absolutely disconnected natively.")

    if quality != "original":
        def generate():
            try:
                cmd = get_transcode_command(file_path, quality)
                process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
                while True:
                    chunk = process.stdout.read(1024 * 1024)
                    if not chunk: break
                    yield chunk
            except Exception:
                raise HTTPException(status_code=500, detail="FFmpeg not installed securely on Host OS.")
        return StreamingResponse(generate(), media_type="video/x-matroska")
        
    # Original exact HTTP 206 chunker logic statically
    file_size = os.path.getsize(file_path)
    range_header = req.headers.get("Range", None)
    
    start = 0
    end = file_size - 1
    
    if range_header:
        byte_range = range_header.replace("bytes=", "").split("-")
        start = int(byte_range[0])
        if byte_range[1]: end = int(byte_range[1])
        
    chunk_size = end - start + 1
    
    def file_yield():
        with open(file_path, "rb") as f:
            f.seek(start)
            bytes_left = chunk_size
            while bytes_left > 0:
                read_len = min(1024 * 1024, bytes_left)
                data = f.read(read_len)
                if not data: break
                bytes_left -= len(data)
                yield data
                
    headers = {
        "Content-Range": f"bytes {start}-{end}/{file_size}",
        "Accept-Ranges": "bytes",
        "Content-Length": str(chunk_size),
        "Content-Type": "video/mp4" # MKV/MP4 stream
    }
    
    return StreamingResponse(file_yield(), headers=headers, status_code=206)
