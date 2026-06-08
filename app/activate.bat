@echo off
setlocal EnableDelayedExpansion

echo ===================================================
echo   Vault IPTV - Activate (Smart Auto-Build)
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
)

:: 3. Check for App Updates (Code changes)
set APP_CHANGED=0

:: Check uncommitted changes in frontend (ignoring api_service.dart auto-updates)
git status --porcelain frontend | findstr /V "api_service.dart" > temp_status.txt
for %%A in (temp_status.txt) do if %%~zA GTR 0 set APP_CHANGED=1

:: Check committed changes
git log -1 --format=%%H -- frontend > temp_hash.txt
set /p CURRENT_HASH=<temp_hash.txt
set LAST_HASH=none
if exist ".last_build_hash" set /p LAST_HASH=<.last_build_hash
if not "!CURRENT_HASH!"=="!LAST_HASH!" set APP_CHANGED=1

if "!IP_CHANGED!"=="1" set APP_CHANGED=1

if "!APP_CHANGED!"=="1" (
    echo [DETECTED] App changes found. Starting compiler...
    
    :: Update IP in api_service.dart
    if "!IP_CHANGED!"=="1" (
        echo Updating api_service.dart with new IP...
        powershell -Command "(Get-Content frontend\lib\core\api\api_service.dart) -replace 'return ''http://.*:8000''; // Fallback for Android testing', 'return ''http://!CURRENT_IP!:8000''; // Fallback for Android testing' | Set-Content frontend\lib\core\api\api_service.dart"
    )

    :: Build Web
    echo.
    echo Building Flutter Web App...
    cd frontend
    call flutter build web --release
    cd ..
    echo.
    echo Copying Web Build to Backend...
    if not exist "backend\app\web_client" mkdir "backend\app\web_client"
    xcopy /E /Y /I "frontend\build\web\*" "backend\app\web_client\" >nul

    :: Build APK
    echo.
    echo Building Android APK...
    cd frontend
    call flutter build apk --release
    cd ..
    
    echo.
    echo Build complete. APK is available at: D:\Vault\app\frontend\build\app\outputs\apk\release\
    
    :: Save current hash to prevent rebuilding next time
    echo !CURRENT_HASH!> .last_build_hash
    
    echo.
) else (
    echo [CLEAN] No IP or Code changes detected. Skipping compiler.
    echo.
)

:: Cleanup temp files
if exist temp_status.txt del temp_status.txt
if exist temp_hash.txt del temp_hash.txt

:: 4. Start the FastAPI Server
echo ===================================================
echo   Starting Vault Backend Server...
echo   Web Interface: http://!CURRENT_IP!:8000/
echo ===================================================
cd backend
call uvicorn app.main:app --host 0.0.0.0 --port 8000

pause
