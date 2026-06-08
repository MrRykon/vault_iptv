@echo off
setlocal EnableDelayedExpansion

echo ===================================================
echo   Vault IPTV - Auto-Build and Run Script (Windows)
echo ===================================================

:: 1. Detect Current IP Address
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set "IP=%%i"
    set "IP=!IP: =!"
    goto :found_ip
)
:found_ip
echo Detected Local IP: %IP%

:: 2. Update api_service.dart with the new IP
echo Updating api_service.dart with new IP...
set "FILE=frontend\lib\core\api\api_service.dart"
set "TEMPFILE=%FILE%.tmp"
if exist "%TEMPFILE%" del "%TEMPFILE%"

for /f "delims=" %%a in ('type "%FILE%"') do (
    set "line=%%a"
    echo !line! | findstr /C:"return 'http://" >nul
    if not errorlevel 1 (
        echo     return 'http://%IP%:8000'; // Fallback for Android testing >> "%TEMPFILE%"
    ) else (
        echo !line! >> "%TEMPFILE%"
    )
)
move /Y "%TEMPFILE%" "%FILE%" >nul

:: 3. Build Web App
echo.
echo Building Flutter Web App...
cd frontend
call flutter build web --release

:: 4. Copy Web App to Backend
echo.
echo Copying Web Build to Backend...
cd ..
if not exist "backend\app\web_client" mkdir "backend\app\web_client"
xcopy /E /Y /I "frontend\build\web\*" "backend\app\web_client\"

:: 5. Build Android APK
echo.
echo Building Android APK...
cd frontend
call flutter build apk --release

:: 6. Copy APK to Backend Media Folder
echo.
echo Copying APK to Backend Media...
cd ..
copy /Y "frontend\build\app\outputs\apk\release\Vault_*.apk" "backend\app\media\"

:: 7. Start the FastAPI Server
echo.
echo ===================================================
echo   Starting Vault Backend Server...
echo   Web Interface: http://%IP%:8000/
echo ===================================================
cd backend
call uvicorn app.main:app --host 0.0.0.0 --port 8000

pause
