# Sprint 3 Release Blockers

These items are intentionally not represented as completed functionality:

- Add server-side recursive deletion for parent and child accounts before
  enabling deletion controls.
- Export, review, version, and emulator-test the deployed Firestore rules.
- Replace the temporary default parent PIN (`0000`) with mandatory setup or
  stronger parent authentication.
- Present foreground push notifications in the app.
- Verify non-English Chapter 2 level IDs against deployed Firestore before
  changing the current fallback list.

Do not re-enable account or child deletion from the Flutter client until the
server-side deletion flow removes all nested data atomically and is covered by
integration tests.
