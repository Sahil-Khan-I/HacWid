@echo off
echo Building and installing Hacwidd APK...
echo.

REM Clean the build cache
echo Step 1: Cleaning Flutter build cache...
flutter clean

REM Get dependencies
echo Step 2: Getting dependencies...
flutter pub get

REM Build the APK in release mode
echo Step 3: Building APK in release mode...
flutter build apk --release

REM Check if the build was successful
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Failed to build the APK!
    pause
    exit /b 1
)

REM Install the APK on a connected device
echo Step 4: Installing APK on connected device...
flutter install --release

echo.
echo Done! The app has been installed on your device.
echo.
echo IMPORTANT: After installation:
echo 1. Go to your home screen
echo 2. Add the "Simple Widget" from the Hacwidd app
echo 3. Open the app and tap the red debug button to force update
echo.

pause