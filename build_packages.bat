@echo off
setlocal enabledelayedexpansion

set "ROOT=d:\Projectos\vault_iptv-main"
set "JAVA_HOME=%ROOT%\jdk-21.0.12.1+1"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo ========================================================
echo   COMPILANDO PAQUETES VAULT IPTV (MOBILE, TV, WEB)
echo ========================================================
echo [1/3] Compilando APK Mobile...
cd /d "%ROOT%\mobile_build\android"
call gradlew.bat assembleDebug --no-daemon
if errorlevel 1 (
    echo [ERROR] Fallo al compilar APK Mobile
    exit /b 1
)
copy /y "%ROOT%\mobile_build\android\app\build\outputs\apk\debug\app-debug.apk" "%ROOT%\VaultIPTV_Mobile.apk"
echo [OK] VaultIPTV_Mobile.apk generado.

echo.
echo [2/3] Compilando APK TV...
cd /d "%ROOT%\tv_build\android"
call gradlew.bat assembleDebug --no-daemon
if errorlevel 1 (
    echo [ERROR] Fallo al compilar APK TV
    exit /b 1
)
copy /y "%ROOT%\tv_build\android\app\build\outputs\apk\debug\app-debug.apk" "%ROOT%\VaultIPTV_TV.apk"
echo [OK] VaultIPTV_TV.apk generado.

echo.
echo [3/3] Empaquetando Web ZIP...
powershell -Command "Compress-Archive -Path '%ROOT%\web\*' -DestinationPath '%ROOT%\VaultIPTV_Web.zip' -Force"
echo [OK] VaultIPTV_Web.zip generado.

echo.
echo ========================================================
echo   TODOS LOS PAQUETES FUERON COMPILADOS EXITOSAMENTE:
echo   - %ROOT%\VaultIPTV_Mobile.apk
echo   - %ROOT%\VaultIPTV_TV.apk
echo   - %ROOT%\VaultIPTV_Web.zip
echo ========================================================
