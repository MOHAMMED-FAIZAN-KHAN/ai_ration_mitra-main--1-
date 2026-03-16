# Firebase Setup (Auth + Firestore + Google Sign-In)

Follow these steps to make this project fully functional with Firebase.

## 1. Create Firebase Project

1. Open Firebase Console: https://console.firebase.google.com
2. Create a new project (or use existing).
3. Enable:
   - `Authentication` -> `Sign-in method` -> `Google`
   - `Firestore Database` (start in production or test mode as needed)

## 2. Register Android App

1. In Firebase, add Android app with package:
   - `com.example.ai_ration_mitra`
2. Download `google-services.json`.
3. Place file at:
   - `android/app/google-services.json`

## 3. Add SHA Fingerprints (required for Google Sign-In on Android)

Run these commands from project root:

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
$env:PATH="$env:JAVA_HOME\bin;$env:PATH"
cd android
.\gradlew signingReport
```

Copy `SHA1` and `SHA-256` from debug/release variants and add them in:

- Firebase Console -> Project Settings -> Your Android App -> Add fingerprint

Current values from your machine:

- `SHA1`: `6A:68:ED:C5:5C:BD:0A:1F:90:02:87:F7:4A:35:13:E1:F4:B6:C1:EA`
- `SHA-256`: `3E:B4:B2:30:6C:32:FF:26:59:CB:82:F2:DC:0F:AD:55:F9:DC:A9:36:3A:50:B7:CF:01:24:95:FB:7C:BB:BE:0E`

## 4. Register iOS App (if you run iOS)

1. Add iOS app in Firebase Console with your iOS bundle id.
2. Download `GoogleService-Info.plist`.
3. Place file at:
   - `ios/Runner/GoogleService-Info.plist`
4. In Xcode, ensure plist is added to `Runner` target.

## 5. Install Dependencies

```powershell
flutter pub get
```

## 6. Firestore Rules (starter)

Use these rules to lock profile docs to signed-in users:

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /notifications/{notificationId} {
      allow read: if request.auth != null;
      allow create, update, delete: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.type == 'admin';
    }
  }
}
```

## 7. Run the App

```powershell
flutter run
```

## Notes

- Citizen users can self-onboard with Google Sign-In.
- FPS Dealer/Admin Google login requires a Firestore user profile with matching role.
- For FPS/Admin first-time Google login, keep the same email in Firestore profile and Google account.
- Existing OTP flow is still available as a fallback path.
