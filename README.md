# Bulk Tempo

A Flutter application targeting Android, iOS, and Web.

---

## Environment Configuration (`env.json`)

To securely handle API credentials and external service configuration without leaking secrets to version control, this project uses compile-time environment variables loaded via `--dart-define-from-file`.

### 1. Create `env.json`

Create an `env.json` file in the project root directory (this file is ignored by git):

```json
{
  "HEAVY_BASE_URL": "https://api.example.com",
  "HEAVY_API_KEY": "your_heavy_api_key_here"
}
```

These values are mapped at compile time to [`HeavyEnv`](lib/core/constants/heavy_env.dart):
* `HEAVY_BASE_URL` -> `HeavyEnv.baseUrl`
* `HEAVY_API_KEY` -> `HeavyEnv.apiKey`

---

## Running and Building

When launching or building the app, pass `--dart-define-from-file=env.json`:

### Command Line

```bash
# Run the application
flutter run --dart-define-from-file=env.json

# Build APK
flutter build apk --dart-define-from-file=env.json
```

---

## Firebase Setup (if applicable)

Firebase configuration files (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, and `lib/firebase_options.dart`) are excluded from git.

Generate or place them directly in their respective platform directories when configuring your Firebase project.
