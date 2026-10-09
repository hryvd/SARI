@echo off
echo =========================================
echo Building Sar-E Android APK
echo =========================================
echo.

echo 1. Fetching new dependencies (http package)...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Failed to run 'flutter pub get'. Make sure Flutter is installed and in your PATH!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo 2. Building the APK file...
call flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Failed to build the APK. Check the errors above.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo =========================================
echo Build Successful! 
echo Your APK is located at:
echo build\app\outputs\flutter-apk\app-release.apk
echo =========================================
pause
