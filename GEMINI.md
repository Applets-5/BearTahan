# BearTahan 🐻

BearTahan is a gamified KSSR-aligned learning application specifically designed for Malaysian Standard 1 students. It aims to make learning engaging through a reward-based system where students earn stars by completing lessons in various subjects.

## Project Overview

- **Purpose:** Educational app for Standard 1 students (BM, English, Math, Science, Mandarin).
- **Core Technologies:**
  - **Framework:** Flutter 3.41.9 (Stable)
  - **State Management:** Riverpod 3.x
  - **Navigation:** GoRouter
  - **Backend:** Firebase (Firestore for database, Firebase Auth for authentication, FCM for notifications).
  - **Architecture:** Feature-based screen organization with centralized services and providers.

## Key Architecture & Patterns

- **State Management:** Uses Riverpod for dependency injection and state management. Providers are located in `lib/providers/data_providers.dart`.
- **Routing:** Centralized routing in `lib/router/app_router.dart` using GoRouter. Includes an auth-gate logic to redirect users based on login status.
- **Data Layer:** `FirestoreService` in `lib/services/firestore_service.dart` handles all interactions with Cloud Firestore.
- **Models:** Data models are defined in `lib/models/` (e.g., `UserProfile`, `ChildProfile`, `Subject`, `Question`).
- **Screens:** Divided into `auth`, `child`, `parent`, and `shared` modules within `lib/screens/`.
- **Theme:** Centralized styling in `lib/theme/app_theme.dart`.

## Building and Running

### Prerequisites
- Flutter SDK: `3.41.9` (Run `flutter --version` to verify).

### Key Commands
- **Install Dependencies:** `flutter pub get`
- **Run App:** `flutter run`
- **Run Tests:** `flutter test`
- **Linting:** `flutter analyze`
- **Formatting:** `dart format .` (Mandatory before every commit).

## Development Conventions

- **Branching Strategy:**
  - `main`: Stable production branch.
  - `sprint-X`: Integration branch for current sprint.
  - `sprint-X/feature-name`: Individual feature branches.
- **Code Style:** Standard Dart/Flutter style. Always run `dart format .` before committing to avoid CI failures.
- **CI/CD:** GitHub Actions (defined in `.github/workflows/flutter_ci.yml`) runs on every push. It enforces:
  1. `dart format` (check)
  2. `flutter analyze`
  3. `flutter test`
- **Mock Data:** A `seedMockData` method is available in `FirestoreService` for initializing development environments.

## Directory Structure Highlights

- `lib/`: Main source code.
- `lib-converted-lovable/`: Excluded from analysis; likely legacy or reference code from conversion tools.
- `assets/images/`: Contains character mascots (`bear1.png` to `bear6.png`) and UI assets.
- `test/`: Unit and widget tests.

## Future Interactions

When assisting with this project, prioritize maintaining consistency with:
- Riverpod for all state management.
- GoRouter for navigation updates.
- Firestore as the source of truth for user data and progress.
- Strict adherence to Flutter 3.41.9 compatibility.
