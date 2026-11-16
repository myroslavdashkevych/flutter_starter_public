import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_starter/data/_shared/data_source/network/token_provider.dart';
import 'package:flutter_starter/data/auth/data_source/auth_firebase_data_source.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AuthFirebaseModule {
  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  /// The same instance as [AuthFirebaseDataSource]: it owns `FirebaseAuth`.
  @lazySingleton
  TokenProvider tokenProvider(AuthFirebaseDataSource dataSource) => dataSource;
}
