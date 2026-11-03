import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_starter/data/_shared/network/token_provider.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: TokenProvider)
class FirebaseTokenProvider implements TokenProvider {
  FirebaseTokenProvider(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<String?> getToken({bool forceRefresh = false}) async =>
      _auth.currentUser?.getIdToken(forceRefresh);

  @override
  Future<void> onUnauthorized() => _auth.signOut();
}
