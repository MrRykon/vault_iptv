@echo off
cd /d "%~dp0"
where py >nul 2>nul
if errorlevel 1 (
  python tools\maintenance.py %*
) else (
  py -3 tools\maintenance.py %*
)
pause
