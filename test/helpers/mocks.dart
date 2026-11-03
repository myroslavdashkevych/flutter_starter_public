import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';
import 'package:flutter_starter/domain/favorites/repositories/favorites_repository.dart';
import 'package:flutter_starter/domain/items/repositories/items_repository.dart';
import 'package:flutter_starter/domain/settings/entities/app_settings.dart';
import 'package:flutter_starter/domain/settings/repositories/settings_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockItemsRepository extends Mock implements ItemsRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

void registerFallbackValues() {
  registerFallbackValue(const AppSettings());
  registerFallbackValue(
    EmailAuthProvider.credential(email: 'fallback@example.com', password: 'x'),
  );
}
