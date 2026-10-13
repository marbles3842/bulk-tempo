# Bulk Tempo

Bulk Tempo is a mobile application targeting Android and iOS, designed to help lifters during weight gain (bulking) phases by evaluating weekly weight gain rates alongside workout progress.

This project was built as part of the [10xDevs course](https://www.10xdevs.pl/).

---

## Tech Stack

- **Flutter**: Cross-platform mobile framework for Android and iOS.
- **Firebase**: Firebase Authentication and Realtime Database for account management and cloud sync.
- **Hevy API Integration**: External workout tracking API integration.

---

## Functionality & Project Structure

### Key Features
- **Weight Tracking**: Log, edit, and view daily body weight measurements and weekly averages.
- **Workout Integration**: Sync workout metrics (exercises, sets, weights, reps) from Hevy.
- **Gain Rate Dashboard**: Evaluate weekly weight gain speed against target ranges alongside training progress.
- **User Authentication**: Secure email/password login and multi-device data sync.

### Architecture & Project Structure
The project follows a **Feature-First MVVM** architecture augmented with **Clean Architecture boundaries** and unidirectional data flow using **Riverpod**:

- `lib/app/`: App-level routing (`go_router`), theme setup, and global providers.
- `lib/core/`: Shared cross-cutting concerns (functional `Result<T, AppFailure>` handling, router constants, design system).
- `lib/features/`: Modular feature packages (`auth`, `weight`, `workout`, `gain_target`), structured into clear architectural layers:
  - **Presentation Layer** (`presentation/`): Views (`ConsumerWidget`) bound to pure Dart ViewModels (`Notifier` / `AsyncNotifier`) with immutable state models.
  - **Domain Layer** (`domain/`): Core business logic, domain entities, and abstract repository contracts with zero framework dependencies.
  - **Data Layer** (`data/`): Data Transfer Objects (DTOs), remote/local datasources, and repository implementations converting network/storage exceptions to typed `Result` objects.

---

## Running and Building

### Dependencies
```bash
flutter pub get
```

### Code Generation
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Running
```bash
# Run on connected mobile device or emulator
flutter run
```

### Testing
```bash
flutter test
```

### Building
```bash
# Build Android APK
flutter build apk

# Build iOS App Bundle
flutter build ios
```

---

## Firebase Setup

Firebase configuration files (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, and `lib/firebase_options.dart`) are excluded from git.

Place `google-services.json` in `android/app/` and `GoogleService-Info.plist` in `ios/Runner/` when setting up your Firebase project.
