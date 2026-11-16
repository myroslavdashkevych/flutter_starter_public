// Placeholder: `flutterfire configure` overwrites this file with the prod
// Firebase project (doc/guide/new-project.md, Connect your own Firebase projects).
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Firebase is not configured for the prod flavor. Run flutterfire configure '
    '(doc/guide/new-project.md, Connect your own Firebase projects).',
  );
}
