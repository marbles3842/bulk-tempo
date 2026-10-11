# Bulk Tempo

A Flutter application targeting Android, iOS, and Web.

---

## Hevy API Integration

Each user configures their personal Hevy Pro API key (`https://hevy.com/settings?developer`) directly inside the app via the **Workouts** or **Profile** tab. The API key is validated and stored locally in encrypted device storage (`flutter_secure_storage`) scoped to the signed-in account, and is never compiled into application binaries or shared across users.

---

## Running and Building

### Command Line

```bash
# Run the application
flutter run

# Build APK
flutter build apk
```

---

## Firebase Setup (if applicable)

Firebase configuration files (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, and `lib/firebase_options.dart`) are excluded from git.

Generate or place them directly in their respective platform directories when configuring your Firebase project.
