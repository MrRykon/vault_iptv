@echo off
cd /d "%~dp0"
where py >nul 2>nul
if errorlevel 1 (
  python tools\server.py %*
) else (
  py -3 tools\server.py %*
)
if errorlevel 1 pause
