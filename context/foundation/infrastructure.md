---
project: Bulk Tempo
researched_at: 2026-10-03
recommended_platform: Google Play + Firebase
runner_up: Google Play + Firebase + Cloudflare Workers
context_type: mvp
tech_stack:
  language: Dart
  framework: Flutter
  runtime: Android
  database: Cloud Firestore (proposed Firebase data store)
---

## Recommendation

**Publish the Android app through Google Play. Use Firebase Authentication and Cloud Firestore for accounts and private, cross-device data. Use a Firebase Cloud Function only if the required Hevy import needs a server-held API key.** The developer chose this path after reviewing the risks. The Flutter app is a mobile binary, so none of the six web/PaaS hosts can publish it to Play; adding one now would create another service beside the chosen Firebase stack. The MVP has a small, mainly single-region audience, no always-on process, equal concern for cost and iteration speed, and a preference for one provider. [Flutter's Android release guide](https://docs.flutter.dev/deployment/android), [Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup), [Google Play upload guide](https://developer.android.com/studio/publish/upload-bundle).

This decision selects **Cloud Firestore** for structured measurements and settings; `tech-stack.md` names Firebase cloud data without choosing a specific database. That choice should be confirmed when the data model is implemented. Google Play is the production distribution channel; [Firebase App Distribution](https://firebase.google.com/docs/app-distribution) is only a preview channel for testers.

## Platform Comparison

The five criteria are CLI maintenance, managed operation, agent-readable docs, scriptable deploy API, and MCP/first-class integration. Pass = 2, Partial = 1, Fail = 0. Scores describe backend operability, **not** Android distribution. The hard filter removes every web/PaaS host as the *primary* Flutter Android deployment target. All remain possible only for an additional Hevy proxy. The shortlist below ranks the complete deployment path after applying the project's stack and interview constraints.

| Backend platform | CLI | Managed | Docs | Deploy API | MCP/integration | Total /10 | Fit for this MVP |
|---|---|---|---|---|---:|---:|---|
| Firebase / Google Cloud | Partial | Pass | Pass | Pass | Pass | 9 | Best: chosen Auth/data, optional co-located Function |
| Cloudflare Workers | Pass | Pass | Pass | Pass | Pass | 10 | Optional Hevy proxy; adds vendor and JS runtime |
| Vercel | Pass | Pass | Pass | Pass | Partial | 9 | Optional HTTP API; adds vendor and runtime |
| Netlify | Partial | Pass | Pass | Pass | Pass | 9 | Optional HTTP API; adds vendor and runtime |
| Fly.io | Pass | Partial | Pass | Pass | Partial | 8 | Persistent VM capability is unused |
| Railway | Partial | Pass | Pass | Pass | Pass | 9 | Optional conventional API; adds vendor and runtime |
| Render | Partial | Pass | Pass | Pass | Pass | 9 | Optional conventional API; adds vendor and runtime |

Firebase has a documented [CLI](https://firebase.google.com/docs/cli), [Flutter integration](https://firebase.google.com/docs/flutter/setup), and [MCP server](https://firebase.google.com/docs/ai-assistance/mcp-server). Its CLI deploys functions and Firestore rules, but rules have no release rollback; Play's first publication and required legal/account gates also need human work, hence Partial for the complete maintenance loop. [Firestore free quota](https://firebase.google.com/docs/firestore/pricing) is 1 GiB stored, 50,000 reads/day, 20,000 writes/day, and 10 GiB outbound/month for one database. Firebase Functions deployment requires Blaze billing, despite a [no-cost monthly usage allowance](https://firebase.google.com/docs/functions/faq-and-troubleshooting). Cost at 10k–100k requests depends on Firestore documents read and written, function CPU, egress, and build storage rather than the request count alone.

Cloudflare has [Wrangler deploy, tail, and rollback commands](https://developers.cloudflare.com/workers/wrangler/commands/workers/), [published pricing](https://developers.cloudflare.com/workers/platform/pricing/), and an [official MCP server](https://github.com/cloudflare/mcp). Its Workers runtime supports JavaScript/Web APIs with partial Node compatibility, so a Firebase Admin integration would need a proof of compatibility. [Node compatibility behavior](https://developers.cloudflare.com/workers/configuration/compatibility-flags/) was checked 2026-10-03. Its D1/KV/R2 services would duplicate the chosen Firebase data layer.

Vercel offers [CLI previews, production deploys, logs, and rollback](https://vercel.com/docs/cli) and supports several [function runtimes](https://vercel.com/docs/functions/configuring-functions/runtime). Its [MCP is beta, checked 2026-10-03](https://vercel.com/docs/agent-resources/vercel-mcp). The [Hobby plan](https://vercel.com/docs/plans/hobby) is personal/non-commercial; [Pro begins at $20/month](https://vercel.com/docs/plans/pro-plan). Its storage marketplace would add another provider beside Firebase.

Netlify provides [draft-by-default CLI deploys](https://docs.netlify.com/deploy/create-deploys/), [runtime logs](https://docs.netlify.com/build/functions/logs/), [agent-readable docs and MCP](https://docs.netlify.com/build/build-with-ai/agent-setup-guides/agent-setup-overview/), and [credit-based plans](https://docs.netlify.com/manage/accounts-and-billing/billing/billing-for-credit-based-plans/credit-based-pricing-plans/). Rollback is primarily a previous-deploy publish action in the UI, so CLI maintenance is Partial. Netlify Blobs is [beta, checked 2026-10-03](https://docs.netlify.com/blobs/overview/) and is not needed here.

Fly.io supports [container/VM deployment](https://fly.io/docs/flyctl/deploy/), [CLI logs](https://fly.io/docs/flyctl/logs/), and [published usage pricing](https://fly.io/docs/about/pricing/). It can host persistent processes, but this app has no such requirement; the [trial](https://fly.io/docs/about/free-trial/) is not an ongoing free tier. Its managed Postgres would replace or duplicate Firebase data. Its [MCP launch tool](https://www.fly.io/docs/mcp/launch/) hosts an MCP server rather than providing a first-class Fly administration MCP.

Railway has [non-interactive `railway up --ci --json`](https://docs.railway.com/cli/up), [JSON logs](https://docs.railway.com/cli/logs), [managed databases](https://docs.railway.com/databases), [pricing](https://railway.com/pricing), and an [official MCP](https://docs.railway.com/ai/mcp-server). [Restoring an arbitrary prior deploy needs the dashboard](https://docs.railway.com/guides/roll-back-bad-deploy), hence Partial CLI. Render similarly offers [CLI/API deployments](https://render.com/docs/cli), [logs and API rollback](https://render.com/docs/rollbacks), [agent-readable docs](https://render.com/docs/llm-support), [pricing](https://render.com/pricing), and [MCP](https://render.com/docs/mcp-server); CLI maintenance is Partial because rollback is API/UI rather than a documented CLI command. Render's docs-only MCP is **experimental, checked 2026-10-03** per its [LLM support docs](https://render.com/docs/llm-support).

### Shortlisted Deployment Paths

1. **Google Play + Firebase (recommended).** Native Android distribution, chosen identity and data services, one provider for the optional secret-bearing Hevy function, and the shortest operational path. Firestore and Auth can begin on Spark; Functions needs Blaze. [Firebase pricing](https://firebase.google.com/pricing).
2. **Google Play + Firebase + Cloudflare Workers.** A low-cost, scriptable edge function could proxy Hevy. It introduces a second vendor and a JS runtime, and Firebase Admin SDK behavior on Workers must be tested before adoption. [Workers runtime](https://developers.cloudflare.com/workers/runtime-apis/).
3. **Google Play + Firebase + Railway.** A conventional Node service can proxy Hevy without edge runtime constraints. It adds an always-on service/billing surface for a single integration and has a dashboard rollback step. [Railway deploy and pricing](https://docs.railway.com/build-deploy), [pricing](https://railway.com/pricing).

## Anti-Bias Cross-Check: Google Play + Firebase

### Devil's Advocate — Weaknesses

1. Hevy says its [public API is currently only for Pro users and may change or be abandoned](https://api.hevyapp.com/docs/). An MVP for multiple private accounts may need each user's own API key; that cannot be embedded in an Android binary or treated as one shared project secret.
2. Deploying a Hevy proxy with [Cloud Functions requires Blaze billing](https://firebase.google.com/docs/functions/get-started). Function invocations may remain within the no-cost allowance, but builds, image storage, egress, and secrets can still create charges. [Functions cost details](https://firebase.google.com/docs/functions/faq-and-troubleshooting).
3. Firestore client access depends on correct per-user Security Rules. [Server libraries bypass those rules](https://firebase.google.com/docs/firestore/security/test-rules-emulator), while a bad rules deploy has [no one-click rollback](https://firebase.google.com/docs/cli).
4. New personal Play developer accounts can face [12 opted-in testers for 14 continuous days before production access](https://support.google.com/googleplay/android-developer/answer/14151465). The [one-time account fee is $25](https://support.google.com/googleplay/android-developer/answer/6112435); review and account gates could consume a meaningful part of the five-week schedule.
5. The repo still has `com.example.bulk_tempo` as its Android application ID and no Firebase packages. Registering Firebase or Play under a provisional ID would create avoidable migration work. [Flutter release guide](https://docs.flutter.dev/deployment/android).

### Pre-Mortem — How This Could Fail

Sześć miesięcy po starcie Bulk Tempo nadal ma małą grupę użytkowników, ale jego główna obietnica jest zawodna. Zespół uznał integrację Hevy za prosty odczyt danych i zbyt późno odkrył, że każdy użytkownik potrzebuje dostępu Pro oraz własnego klucza. Pierwszą wersję aplikacji zbudowano z kluczem testowym w kliencie, więc po wykryciu ryzyka trzeba było pilnie przenieść import do funkcji serwerowej. Funkcja wymagała planu Blaze; koszt wzrósł przez częste odpytywanie i niepotrzebne odczyty Firestore, których nikt nie monitorował. W pośpiechu poprawiono reguły bazy bez testów izolacji kont. Nowa reguła zablokowała część użytkowników, a brak automatycznego cofnięcia wymusił ręczne odtworzenie starego pliku i kolejne wdrożenie. Równocześnie publikacja w Play spóźniła się, bo konto wymagało zamkniętego testu przez 14 dni. Wersja aplikacji z błędem czekała już na recenzję, więc poprawka musiała dostać nowy kod wersji i przejść następny proces wydania. Ostatecznie użytkownicy nie ufali dashboardowi: import treningów był niepełny, a stan synchronizacji offline wyglądał jak aktualny wynik.

### Unknown Unknowns

- Hevy's API contract explicitly disclaims stability; verify its current Pro requirement, per-user authentication model, limits, and permitted use before designing the import. [Hevy API](https://api.hevyapp.com/docs/).
- Cloud Firestore's location is [fixed after database creation](https://firebase.google.com/docs/firestore/locations); select a nearby region before provisioning. The first database is the only one eligible for its [free quota](https://firebase.google.com/docs/firestore/pricing).
- Android Firestore persistence is [enabled by default](https://firebase.google.com/docs/firestore/manage-data/enable-offline). A dashboard must distinguish cached or incomplete data from current server data, especially after switching accounts.
- Experimental server-side Dart Functions support exists, but is **experimental, checked 2026-10-03** and requires Firebase CLI 15.15.0+. The app's Dart constraint does not make that backend production-ready; use the documented Node.js Functions path if a proxy is needed. [Dart Functions status](https://firebase.google.com/docs/functions/start-dart).
- Google Play's Publishing API can update an existing app, but [initial publication and legal consents require Play Console](https://developers.google.com/android-publisher/edits). Automation does not remove that human gate.

## Operational Story

- **Preview deploys:** Use [Firebase App Distribution CLI](https://firebase.google.com/docs/app-distribution/android/distribute-cli) to share a signed pre-release APK with invited testers; the command returns tester and console links. For Play-specific validation, use an internal or closed testing track. These builds are separate from production publication.
- **Secrets:** Keep any Hevy API key out of the Flutter bundle, Git, and committed MCP config. For a project-owned integration credential, set it with `firebase functions:secrets:set HEVY_API_KEY` and bind it only to the Hevy function; each user's own Hevy credential needs a separate, explicitly designed server-side storage and access model. Rotating a Function secret requires redeploying the bound function. [Firebase secret guidance](https://firebase.google.com/docs/functions/config-env).
- **Rollback:** Halt a bad staged Play rollout in Play Console or through the [Publishing API](https://developers.google.com/android-publisher/tracks); a corrected app build needs a new, higher version code. Restore the previous Firestore rules file from version control and run `firebase deploy --only firestore:rules` after validation; rules have [no built-in release rollback](https://firebase.google.com/docs/cli). Re-deploy a known-good Function source revision and separately check data compatibility. No fixed time-to-revert is promised because Play propagation/review and any data repair vary.
- **Approval:** A human creates/verifies the Play account, accepts legal terms, supplies billing and secrets, and approves production publication, primary-secret rotation, and database deletion. An agent may build, test, prepare preview releases, and inspect read-only status/logs with scoped credentials.
- **Logs:** Use `firebase functions:log --only <function-name> --project <project-id>` for an optional Hevy function and `gcloud logging read '<filter>' --project <project-id> --limit 50` for scoped read-only Cloud Logging access. Flutter crashes need the Crashlytics SDK; inspect its [Firebase console reports](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports) or Firebase MCP where configured. [Firebase CLI](https://firebase.google.com/docs/cli), [Cloud Logging CLI](https://docs.cloud.google.com/sdk/gcloud/reference/logging/read).

## Risk Register

| Risk | Source | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| Hevy API restricted to Pro or changed | Devil's advocate | High | High | Validate access with a real target account and import a sample workout before relying on it; define a manual-data fallback. |
| Per-user Hevy keys mishandled | Unknown unknowns | Medium | High | Design per-user server-side credential handling; never embed keys in the Android app or store them in a shared project secret. |
| Unexpected Blaze charges | Devil's advocate | Medium | Medium | Set billing budget alerts, cap Function instances, avoid polling, and review Firestore reads plus build storage after each preview. |
| Cross-account data exposure or lockout | Devil's advocate | Medium | High | Write owner-scoped rules and test authenticated user A, user B, and unauthenticated access in the emulator before each rules deploy. |
| Slow or blocked Play production access | Pre-mortem | Medium | High | Check account status now; if applicable, recruit 12 testers and start the 14-day closed test early. |
| Wrong Firestore region | Unknown unknowns | Medium | Medium | Choose the nearby region before first database creation and record it in the deploy plan. |
| Cached data shown as current | Unknown unknowns | Medium | Medium | Show sync/error state and explicitly mark incomplete or cached dashboard results. |
| Bad rules or app release hard to reverse | Pre-mortem | Medium | High | Version rules, test in emulator, stage Play rollouts, retain a known-good source revision, and rehearse recovery. |
| Provisional Android application ID becomes permanent | Research finding | Medium | Medium | Choose the final reverse-domain application ID before Firebase registration, signing, or Play setup. |

## Getting Started

1. Set the final Android `applicationId` in `bulk_tempo/android/app/build.gradle.kts` before registering the Android app with Firebase or Play. The current value is `com.example.bulk_tempo`. Confirm Play developer account eligibility and start any required closed-testing period early. [Flutter Android release](https://docs.flutter.dev/deployment/android), [Play testing requirement](https://support.google.com/googleplay/android-developer/answer/14151465).
2. Create one Firebase project, enable email/password Authentication, and provision one Cloud Firestore database in the chosen region. Start with the Spark plan for Auth/Firestore; upgrade to Blaze only when the Hevy Function is actually required. [Firebase pricing plans](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans), [Firestore locations](https://firebase.google.com/docs/firestore/locations).
3. From `bulk_tempo/`, add `firebase_core`, `firebase_auth`, and `cloud_firestore` with `flutter pub add`; install the Firebase CLI and run `dart pub global activate flutterfire_cli`, then `flutterfire configure` for Android. The project currently pins Dart `^3.13.5` but no Firebase plugin or adapter version, so resolve and review the generated lockfile before implementation. [Current FlutterFire workflow](https://firebase.google.com/docs/flutter/setup).
4. Define owner-scoped Firestore rules in source control, test cross-account denial in the emulator, and deploy only the validated rules with `firebase deploy --only firestore:rules`. If Hevy import needs a server key, add a **Node.js** callable Function, bind its Secret Manager credential, and call it from Flutter using the `cloud_functions` plugin; deploying that Function requires Blaze. [Firebase CLI](https://firebase.google.com/docs/cli), [callable functions](https://firebase.google.com/docs/functions/callable), [secret configuration](https://firebase.google.com/docs/functions/config-env).
5. Configure Android release signing, build the Play artifact with `flutter build appbundle`, test a signed build, and upload it to a Play testing track before human-approved production publication. [Flutter build instructions](https://docs.flutter.dev/deployment/android), [Google Play upload](https://developer.android.com/studio/publish/upload-bundle).

## Out of Scope

- Docker image configuration
- CI/CD pipeline setup
- Production-scale multi-region, high-availability, and disaster-recovery architecture
