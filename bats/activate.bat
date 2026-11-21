@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

title Vault IPTV - Servidor Activo

echo ========================================================
echo             VAULT IPTV - ACTIVAR SERVIDOR
echo ========================================================
echo.

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fI"
set "APP_DIR=%ROOT_DIR%\app"
set "BACKEND_DIR=%APP_DIR%\backend"
set "VENV_DIR=%BACKEND_DIR%\.venv"
set "VENV_PYTHON=%VENV_DIR%\Scripts\python.exe"

if not exist "%VENV_PYTHON%" (
    echo [INFO] Inicializando entorno virtual Python en backend\.venv...
    if exist "C:\Users\ceper\AppData\Local\Programs\Python\Python312\python.exe" (
        "C:\Users\ceper\AppData\Local\Programs\Python\Python312\python.exe" -m venv "%VENV_DIR%"
    ) else (
        python -m venv "%VENV_DIR%"
    )
)

cd /d "%BACKEND_DIR%"

if not exist ".env" (
    echo [INFO] Creando archivo .env inicial...
    (
        echo DATABASE_URL=sqlite:///./vault.db
        echo SECRET_KEY=vault_secret_key_84920482_production_grade
        echo ALGORITHM=HS256
        echo ACCESS_TOKEN_EXPIRE_MINUTES=43200
        echo REFRESH_TOKEN_EXPIRE_MINUTES=43200
        echo SEED_ADMIN_ON_FIRST_RUN=true
        echo SEED_ADMIN_USERNAME=admin
        echo SEED_ADMIN_PASSWORD=admin123
        echo MOCK_PLEX=true
        echo PLAYLISTS_DIR=../playlists
        echo PLAYLIST_REFRESH_SECONDS=30
        echo RELEASES_DIR=../releases
        echo ALLOW_PUBLIC_REGISTRATION=false
        echo LATEST_VERSION=0.0.5
        echo MINIMUM_SUPPORTED_VERSION=0.0.5
        echo FORCE_UPDATE=false
    ) > ".env"
)

"%VENV_PYTHON%" -c "import fastapi, uvicorn, sqlalchemy" >nul 2>nul
if errorlevel 1 (
    echo [INFO] Instalando dependencias de Python...
    "%VENV_PYTHON%" -m pip install -r requirements.txt -q
)

if not exist "app\media" mkdir "app\media"
if not exist "%APP_DIR%\playlists" mkdir "%APP_DIR%\playlists"

"%VENV_PYTHON%" -m app.db.seed >nul 2>nul

powershell -Command "Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }" >nul 2>nul

set "CURRENT_IP=127.0.0.1"
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i /c:"IPv4"') do (
    set "TMP_IP=%%i"
    set "TMP_IP=!TMP_IP: =!"
    if not "!TMP_IP!"=="" (
        set "CURRENT_IP=!TMP_IP!"
        goto :ip_found
    )
)
:ip_found

echo.
echo ========================================================
echo   SERVIDOR VAULT IPTV INICIADO Y EN EJECUCION
echo ========================================================
echo.
echo   [*] Abriendo navegador en: http://localhost:8000/
echo.
echo   * Acceso Web en esta PC:    http://localhost:8000/
echo   * Acceso desde tu Movil/TV: http://!CURRENT_IP!:8000/
echo   * Documentacion API:        http://!CURRENT_IP!:8000/docs
echo.
echo.
echo   IMPORTANTE:
echo   NO CIERRES ESTA VENTANA mientras uses Vault IPTV.
echo   Para apagar el servidor, simplemente cierra esta ventana
echo   o presiona Ctrl + C.
echo ========================================================
echo.

"%VENV_PYTHON%" -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --no-access-log

echo.
echo [INFO] Servidor detenido.
pause
