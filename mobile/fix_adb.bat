@echo off
echo Fixing ADB Installation Error...

cd /d "C:\Users\paull\Desktop\Projects\Shield-ai\mobile"

echo Step 1: Killing ADB server...
adb kill-server
timeout /t 2 /nobreak >nul

echo Step 2: Starting ADB server...
adb start-server
timeout /t 2 /nobreak >nul

echo Step 3: Uninstalling previous versions...
adb uninstall com.shieldai.mobile
adb uninstall com.example.mobile
adb uninstall shield_ai

echo Step 4: Cleaning Flutter build...
flutter clean

echo Step 5: Getting dependencies...
flutter pub get

echo Step 6: Building APK...
flutter build apk --debug

echo Step 7: Installing APK...
adb install build\app\outputs\flutter-apk\app-debug.apk

if %errorlevel% equ 0 (
    echo ✅ Installation successful!
    echo Launching app...
    adb shell am start -n com.shieldai.mobile/.MainActivity
) else (
    echo ❌ Installation failed. Trying alternative method...
    adb install -r -t build\app\outputs\flutter-apk\app-debug.apk
    if %errorlevel% equ 0 (
        echo ✅ Alternative installation successful!
        adb shell am start -n com.shieldai.mobile/.MainActivity
    ) else (
        echo ❌ All installation methods failed.
        echo Please check device connection and try manually.
    )
)
