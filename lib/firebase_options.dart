// Placeholder until the Firebase project is linked.
//
// Running `flutterfire configure --project=<your-project-id>` regenerates this
// file with the real keys for each platform and adds google-services.json /
// GoogleService-Info.plist. Until then Firebase initialisation fails, which
// `main()` treats as "accounts not configured": the app works fully signed out.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError('Firebase is not configured. Run `flutterfire configure`.');
}
