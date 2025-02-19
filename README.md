# BuildBot

A mobile application that provides AI-assisted PC building and maintenance guidance.

## Option 1: Direct Installation (Recommended)

### Android Users
1. Download the APK file provided with this submission (Can be found in /build/app/outputs/flutter-apk/buildbot.apk)
2. On your Android device, open the APK file
3. If prompted, allow installation from unknown sources
4. Install and launch the app

### System Requirements
- Android 6.0 or higher
- Active internet connection

## Option 2: Running the Code (Development)

If you wish to run the code directly:

### Prerequisites
1. Install Flutter SDK from: https://docs.flutter.dev/get-started/install
2. Install Android Studio or VS Code
3. Set up an Android emulator or connect a physical device

### Setup Steps
1. Clone this repository
2. Open terminal in project directory
3. Run `flutter pub get`
4. Run `flutter run`

### Troubleshooting
- If you get dependency errors, try:
  ```
  flutter clean
  flutter pub get
  ```
- Make sure you have an emulator running or device connected
- Check Flutter installation with `flutter doctor`

## Features
- AI-powered PC building assistance
- Chat history
- User authentication
- Theme customization
- Account management

## Summary
- All necessary API keys and configurations are included in the app
- No additional setup is required for API keys or Firebase
- For quickest evaluation, use Option 1 (APK installation)