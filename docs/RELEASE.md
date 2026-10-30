# Release checklist

> Google Play submission pack (signed bundle, graphics, listing text, form answers): **[PLAY_STORE.md](PLAY_STORE.md)**.

What the code already does for store review, and what is still manual. Items marked ⚠️ cannot be done from the repository: they need an Apple Developer / Google Play / Firebase console account.

## Done in the code

| Requirement | Where |
|---|---|
| Account deletion inside the app (Apple 5.1.1(v), Play) | *Settings → My account → Delete account*. E-mail accounts re-enter their password, Google accounts re-authenticate, Apple accounts re-authenticate and Apple's token is revoked (`FirebaseAuthService.deleteAccount`) |
| Sign in with Apple, offered next to Google (Apple 4.8) | iOS/macOS only (`appleSignInSupported`); native sheet with a nonce (`lib/features/auth/apple_sign_in.dart`); `ios/Runner/Runner.entitlements` |
| Privacy policy inside the app | *Settings → Privacy* (`/privacy`), text from `assets/data/privacy.json` |
| Privacy policy as a public web page | `site/privacy/index.html`, hosted with Firebase Hosting (see below) |
| Crash reports are opt-in | Collection is off in `AndroidManifest.xml` / `Info.plist`; a one-time card on Home and a switch in *Settings → Privacy* turn it on (`lib/core/privacy/crash_reporter.dart`). Debug builds never report |
| Continuous integration | `.github/workflows/ci.yml`: analyze and tests on Linux, Android debug build, golden screenshots on Windows |

## Privacy policy page

The policy text lives once, in `tool/build_privacy.py`, and produces both the in-app screen and the public page. The stores require a **contact address**, which is deliberately not stored in the repository:

```bash
python -X utf8 tool/build_privacy.py . --email you@example.com --name "Your name"
git add assets/data/privacy.json site && git commit -m "Privacy policy contact"
firebase deploy --only hosting --project noor-app-alaa-4829
```

The page is then at `https://noor-app-alaa-4829.web.app/privacy` — use that URL in both store listings (the app opens the same URL from *Privacy → Open the public policy page*; override with `--dart-define=PRIVACY_POLICY_URL=...` for another host).

Whenever the app starts collecting something new (analytics, cloud sync, ads), update `SECTIONS` and `UPDATED` in the script first. The wording was drafted from what the code actually does; **have a lawyer review it before the first public release.**

## ⚠️ Sign in with Apple setup

1. Apple Developer → Identifiers → `app.noor.noor` → enable the **Sign in with Apple** capability (the entitlement is already in the project).
2. Firebase console → Authentication → Sign-in method → **Apple** → enable.
3. For token revocation on deletion, create a *Sign in with Apple* key in Apple Developer (Keys) and enter the Team ID, Key ID and the `.p8` key in the Apple provider's **OAuth code flow configuration**. Without it, deleting an Apple account fails at the revoke step.
4. Test on a real iPhone (the simulator needs an iCloud sign-in). This part could not be run from Windows, so it is **untested**.

## ⚠️ Crashlytics

- Android: the Gradle plugin is wired in (`android/settings.gradle.kts`, `android/app/build.gradle.kts`); the debug build was verified.
- iOS: add the dSYM upload build phase so crashes are symbolicated. Run `flutterfire configure` on a Mac, or follow the Firebase docs for Swift Package Manager projects (this project has no Podfile). Untested.
- After the first release crash, check the Firebase console → Crashlytics for the app.

## ⚠️ Store forms (answers that match the policy)

| Question | Answer |
|---|---|
| Data collected | E-mail, name, profile photo and user ID **only if the person creates an account** (purpose: app functionality). Crash diagnostics **only if they agree**. Nothing else |
| Location | Used on the device for prayer times and Qibla; **not collected** by us |
| Ads / tracking / data sold | None |
| Data deletion | In-app (*My account → Delete account*) |
| Children | Account creation 13+; the Kids corner collects nothing |

Also review:
- Google Play: justify `SCHEDULE_EXACT_ALARM` (adhan alerts) in the permissions declaration form.
- Apple: confirm whether a `PrivacyInfo.xcprivacy` is needed for the app target (the plugins ship their own).

## ⚠️ Other items before shipping

- **Release signing.** `android/app/build.gradle.kts` still signs release builds with the *debug* key. Create an upload keystore, reference it from `key.properties`, and add its SHA-1/SHA-256 to the Firebase Android app (see [FIREBASE.md](FIREBASE.md)).
- Restrict the Firebase API keys (Android package + SHA, iOS bundle id) and consider App Check.
- Review licences for commercial distribution: Tanzil (CC BY 3.0, attribution in *About*), Saheeh International via Tanzil terms, everyayah.com audio, the Hisn al-Muslim dataset (MIT).
- Religious content written for this app needs scholarly review (see the README).
