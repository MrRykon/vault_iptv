@echo off
color 0B
echo ===========================================
echo        VAULT BACKEND SERVER ACTIVE
echo ===========================================
echo Routing over internal network Port 8000...
cd d:\Vault\backend
.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
