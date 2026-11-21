@echo off
chcp 65001 >nul
setlocal

title Vault IPTV - Mantenimiento

echo ===================================================
echo             VAULT IPTV - MANTENIMIENTO
echo ===================================================
echo.

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fI"
set "APP_DIR=%ROOT_DIR%\app"
set "BACKEND_DIR=%APP_DIR%\backend"
set "VENV_PYTHON=%BACKEND_DIR%\.venv\Scripts\python.exe"

set "PYTHON_EXE="
if exist "%VENV_PYTHON%" (
    set "PYTHON_EXE=%VENV_PYTHON%"
) else if exist "C:\Users\ceper\AppData\Local\Programs\Python\Python312\python.exe" (
    set "PYTHON_EXE=C:\Users\ceper\AppData\Local\Programs\Python\Python312\python.exe"
) else (
    set "PYTHON_EXE=python"
)

cd /d "%APP_DIR%"

echo Ejecutando limpieza y optimizacion del sistema...
"%PYTHON_EXE%" tools\maintenance.py %*

echo.
pause
