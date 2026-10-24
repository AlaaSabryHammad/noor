# Firebase (accounts)

Accounts are **optional**: the app works fully signed out, and falls back to that if Firebase cannot start.

## Current setup

| Item | Value |
|---|---|
| Project | `noor-app-alaa-4829` (display name “NOOR”) — [console](https://console.firebase.google.com/project/noor-app-alaa-4829/overview) |
| Android app | `app.noor.noor` — `1:849515368017:android:f641355b92e8c2cd00f270` |
| iOS app | `app.noor.noor` — `1:849515368017:ios:a7262499a1d2769900f270` |
| Sign-in methods | Email/Password, Anonymous (guest), Google — enabled from `firebase.json` with `firebase deploy --only auth`. Apple is implemented in the app but must be enabled by hand in the console (needs your Apple Developer account) |
| Other services | Crashlytics (opt-in crash reports), Hosting (`site/`: privacy policy page) |
| Android debug keys | SHA-1 and SHA-256 of the local debug keystore are registered |

`lib/firebase_options.dart` and `android/app/google-services.json` hold the *client* configuration. These identifiers are not secrets, but you should still restrict the API keys (Google Cloud console → APIs & Services → Credentials → restrict to the Android package/SHA-1 and the iOS bundle id) before a public release.

## Re-create it for another project (fork)

```bash
firebase login
firebase projects:create <unique-id> --display-name "NOOR"
dart pub global activate flutterfire_cli
flutterfire configure --project=<unique-id> --platforms=android,ios --android-package-name=app.noor.noor --ios-bundle-id=app.noor.noor --yes

# enable the sign-in methods declared in firebase.json (edit supportEmail first)
firebase deploy --only auth --project <unique-id>

# Android: register your debug and release signing keys, then refresh google-services.json
firebase apps:android:sha:create <androidAppId> <SHA1-without-colons> --project <unique-id>
firebase apps:sdkconfig android <androidAppId> --project <unique-id> > android/app/google-services.json
```

Then point Google Sign-In at the new project:

- Android: pass the project's **web** client id (type 3 in `google-services.json`) with `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` (the default in `firebase_auth_service.dart` is this project's id).
- iOS: put the iOS `CLIENT_ID` in `GIDClientID`, the web client id in `GIDServerClientID`, and the `REVERSED_CLIENT_ID` as a URL scheme in `ios/Runner/Info.plist` (already done for this project).

## Before shipping

- Add the **release** keystore SHA-1/SHA-256 to the Android app (the debug keys only work for debug builds).
- Account deletion is implemented in *Settings → My account*; Sign in with Apple (iOS) is implemented in code and needs the console setup described in [RELEASE.md](RELEASE.md).
- Crashlytics is wired in and **opt-in**; Hosting serves the privacy page (`firebase deploy --only hosting`). Details in [RELEASE.md](RELEASE.md).
- Consider authorised domains / App Check and a password policy in the console.
