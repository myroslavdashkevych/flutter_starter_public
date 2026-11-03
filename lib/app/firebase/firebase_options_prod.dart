// Placeholder: `flutterfire configure` overwrites this file with the prod
// Firebase project (docs/new-project.md section 3).
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Firebase is not configured for the prod flavor. Run flutterfire configure '
    '(docs/new-project.md section 3).',
  );
}
