@echo off
setlocal EnableDelayedExpansion

echo ===================================================
echo   Vault IPTV - Activate Server (Smart Auto-Build)
echo ===================================================

:: 1. Detect Current IP Address
set "CURRENT_IP="
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set "CURRENT_IP=%%i"
    set "CURRENT_IP=!CURRENT_IP: =!"
    goto :found_ip
)
:found_ip
echo Detected Local IP: !CURRENT_IP!

:: 2. Check if IP changed in api_service.dart
set IP_CHANGED=0
findstr /C:"return 'http://!CURRENT_IP!:8000';" "frontend\lib\core\api\api_service.dart" >nul
if errorlevel 1 (
    echo [DETECTED] Network IP has changed.
    set IP_CHANGED=1
    echo Updating api_service.dart with new IP...
    powershell -Command "(Get-Content frontend\lib\core\api\api_service.dart) -replace 'return ''http://.*:8000''; // Fallback for Android testing', 'return ''http://!CURRENT_IP!:8000''; // Fallback for Android testing' | Set-Content frontend\lib\core\api\api_service.dart"
)

:: 3. Smart OTA Syncer (No Compiling)
echo.
set "FULL_VERSION="
for /f "tokens=2 delims=: " %%a in ('findstr "^version:" frontend\pubspec.yaml') do set FULL_VERSION=%%a
for /f "tokens=1 delims=+" %%a in ("!FULL_VERSION!") do set APP_VERSION=%%a

set LAST_BUILT=none
if exist ".last_build_version" set /p LAST_BUILT=<.last_build_version

if not "!APP_VERSION!"=="!LAST_BUILT!" (
    echo [DETECTED] New version !APP_VERSION! found in pubspec.yaml.
    echo Syncing pre-compiled OTA updates to backend...
    echo.
    
    if not exist "backend\app\media" mkdir "backend\app\media"
    
    :: The user manually compiles the APK and places it in D:\Vault\app as VaultApp_v!APP_VERSION!.apk
    if exist "VaultApp_v!APP_VERSION!.apk" (
        echo Copying APK to Backend Media folder for OTA...
        copy /Y "VaultApp_v!APP_VERSION!.apk" "backend\app\media\Vault_v!APP_VERSION!.apk" >nul
        echo !APP_VERSION!> .last_build_version
        echo [SUCCESS] App v!APP_VERSION! staged for OTA updates!
    ) else (
        echo [WARNING] VaultApp_v!APP_VERSION!.apk not found in D:\Vault\app. Please compile and place it here first!
    )
    
    if exist "VaultWeb_v!APP_VERSION!.zip" (
        echo Extracting Web Client to Backend...
        if not exist "backend\app\web_client" mkdir "backend\app\web_client"
        powershell -Command "Expand-Archive -Path 'VaultWeb_v!APP_VERSION!.zip' -DestinationPath 'backend\app\web_client' -Force" >nul
    )
    echo.
) else (
    echo [CLEAN] App version !APP_VERSION! OTA files are already synced.
    echo.
)

:: 4. Start the FastAPI Server
echo ===================================================
echo   Starting Vault Backend Server...
echo   Web Interface: http://!CURRENT_IP!:8000/
echo ===================================================
cd backend

if not exist "venv\" (
    echo Creating Python Virtual Environment...
    python -m venv venv
)
call venv\Scripts\activate.bat
echo Installing dependencies...
pip install -r requirements.txt -q

call uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

pause
