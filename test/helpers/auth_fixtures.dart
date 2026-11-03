import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

const testUser = AppUser(id: 'user-1', email: 'user@example.com');

MockAuthRepository signedInAuthRepository() {
  final repository = MockAuthRepository();
  when(repository.authStateChanges)
      .thenAnswer((_) => Stream<AppUser?>.value(testUser));
  return repository;
}
