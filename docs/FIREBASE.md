# Firebase setup (accounts)

The app works without Firebase. To turn accounts on:

## 1. Create / link the project

```bash
npm install -g firebase-tools
firebase login
firebase projects:create <unique-project-id> --display-name "NOOR"
dart pub global activate flutterfire_cli
flutterfire configure --project=<unique-project-id> --platforms=android,ios
```

`flutterfire configure` registers the Android/iOS apps, regenerates `lib/firebase_options.dart`, downloads `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`, and adds the Google Services Gradle plugin.

## 2. Enable sign-in methods (Firebase console → Authentication → Sign-in method)

| Method | Notes |
|---|---|
| Email/Password | enable |
| Anonymous | enable (the “continue as guest” button) |
| Google | enable; set the project support e-mail |

## 3. Google Sign-In

- Android: add the **SHA-1 and SHA-256** of your debug and release keys (Firebase console → Project settings → Your apps), then download `google-services.json` again.
- Pass the project's **web client ID** (Authentication → Google → Web SDK configuration) at build time so the app can obtain an ID token:

  ```bash
  flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<id>.apps.googleusercontent.com
  ```

  Without it the Google button is simply hidden.
- iOS: add the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` as a URL scheme in `ios/Runner/Info.plist`.

## 4. Store requirements

- Apps that offer account creation must let users **delete the account** (implemented in *Settings → My account*).
- If you ship Google sign-in on iOS, App Store guideline 4.8 also requires offering **Sign in with Apple**; that needs an Apple Developer account and is not included yet.
