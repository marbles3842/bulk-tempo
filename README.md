# Bulk Tempo

Bulk Tempo is a mobile application designed to help lifters during weight gain (bulking) phases by evaluating weekly weight gain rates alongside workout progress.

This project was built as part of the [10xDevs course](https://www.10xdevs.pl/).

---

## Tech Stack

- **Flutter**: Cross-platform application framework for Android, iOS, and Web.
- **Firebase**: Authentication and cloud data storage.
- **Hevy API Integration**: Workout tracking integration.

---

## Functionality & Structure

### Key Features
- **Weight Tracking**: Log, edit, and track daily body weight measurements and weekly averages.
- **Workout Syncing**: Import workout activity (weights, reps, sets) via Hevy integration.
- **Gain Rate Evaluation**: Dashboard assessing weight gain speed against target ranges alongside training progress.
- **User Authentication**: Secure user login and multi-device data sync.

### Project Structure
The codebase follows a feature-first MVVM architecture in `lib/`:
- `lib/app/`: Global app initialization, theme, and router configuration.
- `lib/core/`: Shared components, utilities, and router constants.
- `lib/features/`: Modular features (`auth`, `weight`, `workout`, `gain_target`), each containing presentation, domain, and data layers.

---

## Running and Building

### Dependencies
```bash
flutter pub get
```

### Running
```bash
# Run on default connected device
flutter run

# Run on Web
flutter run -d chrome
```

### Testing
```bash
flutter test
```

### Building
```bash
# Build Android APK
flutter build apk

# Build Web release
flutter build web
```

---

## Firebase Setup

Firebase configuration files (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, and `lib/firebase_options.dart`) are excluded from git.

Generate or place them directly in their respective platform directories when configuring your Firebase project.
