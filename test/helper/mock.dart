import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_starter/domain/entity/app_settings.dart';
import 'package:flutter_starter/domain/repository/auth_repository.dart';
import 'package:flutter_starter/domain/repository/character_repository.dart';
import 'package:flutter_starter/domain/repository/favorite_repository.dart';
import 'package:flutter_starter/domain/repository/settings_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockCharacterRepository extends Mock implements CharacterRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFavoriteRepository extends Mock implements FavoriteRepository {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

void registerFallbackValues() {
  registerFallbackValue(const AppSettings());
  registerFallbackValue(
    EmailAuthProvider.credential(email: 'fallback@example.com', password: 'x'),
  );
}
