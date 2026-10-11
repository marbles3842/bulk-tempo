---
project: Bulk Tempo
status: draft-awaiting-decisions
prepared_at: 2026-10-05
target: Google Play production + Firebase Authentication + Cloud Firestore
source_contracts:
  - context/foundation/infrastructure.md
  - context/foundation/tech-stack.md
  - context/foundation/prd.md
---

# First deployment plan

This is a plan for the first Android release, not a record of a completed deployment. No Firebase project, Play app, production database, signing key, or release has been created by this plan. Run the stages in order; stop at each gate until its evidence is recorded. Commands below run from `bulk_tempo/` unless stated otherwise. Replace angle-bracket placeholders with approved identifiers; do not paste secrets into commands, Git, or this file.

## Decisions to record before provisioning

| Decision | Current state | Required answer |
| --- | --- | --- |
| Final Android package ID | `com.example.bulk_tempo` in Gradle | `<application-id>`; fix before Firebase registration and Play app creation. |
| Play developer account | Unknown | Account owner, verified/production eligibility, and whether the 12-tester/14-day closed-test gate applies. |
| Firebase project and Firestore location | Unknown | `<firebase-project-id>` and one chosen EU location, selected before database creation. |
| Hevy import credential model | Unresolved | Verify Hevy API entitlement and whether each user supplies a key or a permitted project credential exists. This is required for PRD FR-006. |
| Production release trigger | Stack says auto-deploy on merge; infrastructure requires human approval | Merge may run checks and preview distribution automatically. Production publication waits for explicit owner approval, including when a future GitHub Actions workflow initiates the release. |

## 1. Readiness and identity gate

**Agent work:** Inspect the Android manifest and Gradle settings, choose the final `applicationId` and matching namespace/Kotlin package after the owner supplies the ID, and update app name, icon, versioning, and release configuration. Remove `HEAVY_API_KEY` from `--dart-define` and `HeavyEnv`; a bundled Android binary cannot hold a secret. Replace the README's client-key instructions with the chosen import design. Record the commit SHA used for each release.

**Owner gate:** Verify the Google Play developer account and production eligibility. If the account is a personal account created after 13 November 2023, start a closed test with at least 12 opted-in testers for 14 continuous days early. Create/verify the Play app under the final package ID. The first app upload, legal consents, and first production publication happen in Play Console. Decide who holds the upload keystore and its recovery backup.

**Exit evidence:** Final package ID committed; package identity matches the intended Play listing; Play account/testing status recorded; no API key is passed through Flutter defines or present in tracked files. [Play testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465), [Play API first-publication limits](https://developers.google.com/android-publisher/edits).

## 2. Firebase project and app configuration

**Owner gate:** Create or identify `<firebase-project-id>` in Firebase Console. Enable email/password sign-in in Authentication. Choose the Cloud Firestore location and create the default database in production mode with locked-down rules; its location cannot be changed later. Start on Spark for Authentication and Firestore. Add Blaze billing only if a Cloud Function is approved for Hevy; set a billing budget alert first. Grant the agent only the project permissions needed for configuration and rules deployment.

**Agent work:** In `bulk_tempo/`, install Firebase CLI and FlutterFire CLI if absent, authenticate through the owner's approved method, then configure the Android Firebase app using the final package ID:

```sh
firebase login
dart pub global activate flutterfire_cli
flutter pub add firebase_core firebase_auth cloud_firestore
flutterfire configure
```

Select the existing project and **Android only** when prompted. Initialize Firebase in Flutter with `DefaultFirebaseOptions.currentPlatform`; implement email/password sign-up, sign-in, sign-out, and private account data. Review the generated `firebase_options.dart` and Android Firebase config. They contain project identifiers, not server secrets; the repository currently ignores them, so decide how reproducible local and GitHub Actions builds will receive them before enabling CI. Never add a Hevy API key to either file. [Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup).

**Exit evidence:** A signed-in test account can write and read its own Firestore documents on two Android devices or emulators; a signed-out client cannot read private data.

## 3. Data access and Hevy import gate

**Agent work:** Put Firestore rules and indexes in version control under `bulk_tempo/` with `firebase.json`. Use owner-scoped paths such as `users/{uid}/...` and allow reads/writes only when `request.auth.uid == uid`, with field validation appropriate to the final schema. Add a `firestore-rules-tests/` test package with emulator tests for unauthenticated access, user A's access, user B's denial, and update/delete permissions. Run:

```sh
firebase emulators:exec --only firestore "npm --prefix firestore-rules-tests test"
firebase deploy --project <firebase-project-id> --only firestore:rules
```

Deploy only after tests pass and the owner approves the production rules change. Keep the deployed rules commit SHA. CLI deployment overwrites rules edited in the console. [Rules testing](https://firebase.google.com/docs/firestore/security/test-rules-emulator), [selective rules deployment](https://firebase.google.com/docs/rules/manage-deploy).

**Hevy decision:** FR-006 requires importing workout weight and repetition data. First verify the current API terms and access with a real target account. If the approved design needs a server-held **project** key, implement a narrow Node.js callable Firebase Function, require Firebase Auth, limit requests and instances, and only then move the project to Blaze. Set the key interactively and deploy that function only:

```sh
firebase functions:secrets:set HEVY_API_KEY --project <firebase-project-id>
firebase deploy --project <firebase-project-id> --only functions:<hevy-function-name>
```

Bind the secret to that function in source. If **each user** supplies a key, design per-user protected storage, access, revocation, and deletion before implementing import; one project secret is unsuitable. Do not ship the first release until import works under the approved credential model, or the owner explicitly changes the MVP scope/PRD. [Functions secrets](https://firebase.google.com/docs/functions/config-env), [Hevy API](https://api.hevyapp.com/docs/).

**Exit evidence:** A valid test account imports a workout with weights and reps; invalid credentials fail safely; user B cannot access user A's imported data; no secret appears in the APK, logs, or repository.

## 4. Release build and tester validation

**Agent work:** Configure a dedicated upload key for the Gradle `release` build; keep the keystore and `key.properties` outside Git and back them up under owner control. Enable Play App Signing. Bump `version: <name>+<monotonic-code>` in `pubspec.yaml` for each Play upload. From `bulk_tempo/`, run:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

Run formatting/tests only for directories that exist when implementation is complete. Inspect signing and package identity of the built artifacts. For a quick preview, distribute the signed APK to invited testers:

```sh
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk --app <firebase-android-app-id> --testers-file <local-testers-file> --release-notes-file <local-notes-file>
```

Tester emails and release notes files stay outside Git unless explicitly intended as public. Validate on at least one physical Android device: sign-up, sign-in/out, password recovery if included, user isolation, historical weight entries, cross-device sync, missing/cached data display, Hevy import, and dashboard calculations. Install a Play internal/closed-track build as well to check the Play-delivered AAB. [Flutter Android release](https://docs.flutter.dev/deployment/android), [App Distribution CLI](https://firebase.google.com/docs/app-distribution/android/distribute-cli).

**Owner gate:** Review Play listing, screenshots, content rating, privacy policy, Data safety disclosures, and app-access instructions for reviewers. Because the app creates accounts, provide an in-app account-deletion path and an external deletion-request URL, with deletion of associated user data. Record the URLs and review completion before submitting. [Play account deletion requirement](https://support.google.com/googleplay/android-developer/answer/13327111).

**Exit evidence:** Testers install the signed build and pass the core flows; Play pre-launch checks have no release-blocking finding; the required store declarations and deletion paths are accepted.

## 5. Production publication gate

**Agent work:** Prepare the exact tested AAB, its SHA-256, version code, source commit, release notes, known issues, and validation evidence for owner review. Do not rebuild after approval; if the artifact changes, repeat validation. Record Firebase project ID, Firestore location, rules revision, optional Function revision, and the Play testing track.

**Owner gate:** Approve this specific AAB and release notes. Upload the first AAB and complete the first publication in Play Console. If production eligibility requires a closed test, complete that gate and apply for production access first. Prefer a staged production rollout where available; monitor the initial cohort before expanding. Record approval time and Play release/version identifiers.

**Exit evidence:** Play Console shows the approved version available on the intended production track; a fresh install from Play can authenticate, read/write private data, import a workout, and show the dashboard. Check that a second account cannot see the first account's data.

## 6. Post-release operation and recovery

- Monitor Play Console release status and Android vitals. If Crashlytics is implemented, inspect crash reports there; without its SDK, do not claim crash telemetry exists. For an optional Function, inspect `firebase functions:log --only <hevy-function-name> --project <firebase-project-id>` and billing/Firestore usage during the first days.
- If the app release is bad, halt the staged rollout in Play Console. A fixed app requires a new AAB with a higher version code; Play cannot simply republish an older code.
- If Firestore rules are bad, restore the known-good rules file from its recorded commit, rerun emulator tests, and deploy `firebase deploy --project <firebase-project-id> --only firestore:rules`. Check data compatibility and user access after recovery.
- If the Function is bad, redeploy its known-good source revision; rotate or delete a primary secret only through owner action. Do not delete a project or database as an automated recovery step.
- Keep the release record in `context/deployment/` with date, approver, source SHA, artifact hash, Firebase revisions, Play version code, monitoring result, and any recovery action.

## GitHub Actions handoff

The stack selects GitHub Actions and deployment on merge. After the first manual release is proven, make merges run formatting, analysis, tests, a signed build, and tester distribution automatically. Configure a protected GitHub Environment so production upload/publication from a merge waits for the owner's approval of the exact built artifact. Supply Firebase configuration and upload-key material through scoped environment secrets; do not store a broad Google credential or signing key in Git. Keep Play Console as the required manual path for first publication. A CI workflow is a separate implementation task; no workflow exists in the current starter.

## Open decisions and status

This plan remains **draft** until the owner answers the package ID/Play account, Firebase project/location, and Hevy credential questions above. Then replace placeholders, reconcile the release trigger, and mark the plan approved before any production mutation. The current app is still a `Hello World` starter with debug release signing and no Firebase integration, so execution also depends on implementing the MVP features and resolving the PRD's blocking calculation and missing-data questions.
