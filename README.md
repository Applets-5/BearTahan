# BearTahan 🐻

Gamified KSSR-aligned learning app for Malaysian Standard 1 students.  
Built with Flutter + Firebase by team APPLE-5.

---

## First-time setup

1. Install **Flutter 3.41.9, stable channel** — [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Clone the repo and open the project folder
3. Run:

```bash
flutter pub get
```

4. Verify everything is working:

```bash
flutter doctor
flutter run
```

> **Version check:** Run `flutter --version` and confirm you are on `3.41.9`.  
> If not, run `flutter upgrade` or reinstall. Using a different version will cause CI failures.

---

## Before every commit — format your code

We enforce consistent code formatting across the project. Before you commit, always run:

```bash
dart format .
```

This automatically reformats all your Dart files to the standard style. It takes under a second and fixes everything for you — you do not need to do it manually line by line.

**Why this matters:** GitHub Actions runs a format check on every push. If your code is not formatted, the CI pipeline will fail with a red ❌ and your PR cannot be merged. Running `dart format .` before committing means you will never hit this.

```bash
# Typical workflow before committing
dart format .
git add .
git commit -m "your message"
git push
```

---

## Running tests locally

Run all tests before pushing:

```bash
flutter test
```

Run a specific test file:

```bash
flutter test test/services/star_service_test.dart
```

See detailed output with each test name:

```bash
flutter test --reporter expanded
```

All tests must pass locally before you push. If a test fails, fix it first — do not push broken tests.

For a full guide on how to write tests and use AI to generate them, read [`TESTING_GUIDE.md`](https://docs.google.com/document/d/1zSLGKhDw6b9D-MITOAOiu5wWx9foBHhS08Ejwoxq3xE/edit?usp=sharing).

---

## GitHub Actions (CI)

Every push to any branch automatically triggers our CI pipeline on GitHub. It runs three checks in order:

| Check | What it does |
|---|---|
| `dart format` | Fails if code is not formatted |
| `flutter analyze` | Fails if there are lint or type errors |
| `flutter test` | Fails if any unit test fails |

After pushing, check the icon next to your commit on GitHub:

| Icon | Meaning |
|---|---|
| 🟡 Yellow dot | CI is still running, wait |
| ✅ Green tick | All checks passed |
| ❌ Red cross | Something failed — click Details to see what |

**PRs to `sprint-1` or `main` cannot be merged unless CI is green.**  
If your CI is red, fix the issue locally and push again.

---

## Branching

| Branch | Purpose |
|---|---|
| `main` | Stable — merged into after sprint review only |
| `sprint-1`, `sprint-2`, ... | Sprint integration branch — all PRs go here |
| `sprint-1/your-feature` | Your personal feature branch — branch off the sprint branch |

Always branch off the current sprint branch, not `main`.

---

## Tech stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter 3.41.9 (Dart) |
| Database | Cloud Firestore |
| Authentication | Firebase Auth (Google Sign-In) |
| Push notifications | Firebase Cloud Messaging |
| State management | Riverpod |
