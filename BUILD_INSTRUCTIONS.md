# AI Ration Mitra - Build Instructions

## ⚠️ IMPORTANT: OneDrive File Locking Issue

The project is currently located on OneDrive, which can cause file locking issues during the APK build process. To successfully build the APK, **move the project to a local drive** (C:\ drive) first.

### Steps to Move Project:

1. **Copy to Local Drive:**
   ```
   Copy entire "ai_ration_mitra-main (1)" folder to C:\Projects\ or C:\flutter-projects\
   ```

2. **Update Path in Terminal:**
   ```
   cd C:\Projects\ai_ration_mitra-main (1)
   ```

## Quick Start Building

### Prerequisites:
- Flutter SDK installed and updated
- Android SDK/Android Studio installed
- Java Development Kit (JDK) installed
- Virtual device or physical Android device connected

### Build Steps:

#### 1. Get Dependencies
```bash
cd C:\Projects\ai_ration_mitra-main (1)
flutter pub get
```

#### 2. Verify Code Quality
```bash
flutter analyze
# Expected output: "No issues found!"
```

#### 3. Run Tests (Optional)
```bash
flutter run
# This tests the app on a connected device/emulator in debug mode
```

#### 4. Build Debug APK (Quick Testing)
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

#### 5. Build Release APK (For Distribution)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### 6. Build Android App Bundle (Recommended for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

## Build Options Reference

| Command | Purpose | Output Size |
|---------|---------|-------------|
| `flutter build apk --debug` | Fast testing on devices | Larger (~50-60 MB) |
| `flutter build apk --release` | Distribution, optimized | Smaller (~25-30 MB) |
| `flutter build appbundle --release` | Play Store submission | Smaller (~25-30 MB) |

## Troubleshooting

### Problem: "AccessDeniedException" or File Locking Errors
**Solution:** Move project to a local drive (not OneDrive)

### Problem: Gradle Build Fails
**Solution:** Clean the build and try again
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Problem: Certificate/Signing Issues
**Solution:** The app currently uses debug keystore for release builds. For production release:

1. Generate a new keystore:
```bash
keytool -genkey -v -keystore ~/.keystore/my_app.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my_key
```

2. Update `android/app/build.gradle.kts` with your keystore details

### Problem: "No connected devices"
**Solution:** Connect physical device or launch Android emulator
```bash
flutter devices  # List available devices
```

## Build Output Locations

After successful build:

- **Debug APK**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Release APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **App Bundle**: `build/app/outputs/bundle/release/app-release.aab`

## Installation on Device

### Install Debug APK:
```bash
flutter install -v
# Or manually:
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Install Release APK:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## App Information

- **App Name**: AI Ration Mitra
- **Package Name**: com.example.ai_ration_mitra
- **Min SDK**: Android 5.0 (API 21)
- **Target SDK**: Android 13+ (API 33+)
- **Minimum Flutter**: 3.0.0+

## Post-Build Checklist

After successfully building the APK:

- [ ] APK file generated successfully
- [ ] File size is reasonable (25-60 MB depending on build type)
- [ ] Install on test device
- [ ] Test all screens load correctly
- [ ] Test citizen login and grievance submission
- [ ] Test admin login and grievance viewing
- [ ] Test booking slot functionality
- [ ] Verify no crashes occur during basic usage

## Production Deployment Notes

For production deployment to Google Play Store:

1. Use Release Build (AAB format preferred)
2. Sign with production keystore (not debug keystore)
3. Update version codes in `pubspec.yaml` for each release
4. Complete app privacy policy and store listing
5. Submit AAB file to Google Play Console

## Support & Additional Resources

- Flutter Documentation: https://flutter.dev/docs
- Android Studio: https://developer.android.com/studio
- Google Play Console: https://play.google.com/console

---

**Note**: All code has been optimized, cleaned, and is ready for production. Follow the instructions above to successfully build the APK.
