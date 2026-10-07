@echo off
cd /d "%~dp0"
where py >nul 2>nul
if errorlevel 1 (
  python tools\diagnostics.py --check-server %*
) else (
  py -3 tools\diagnostics.py --check-server %*
)
pause
