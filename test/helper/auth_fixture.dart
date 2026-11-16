import 'dart:async';

import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:mocktail/mocktail.dart';

import 'mock.dart';

const testUser = AppUser(id: 'user-1', email: 'user@example.com');

/// An auth state that, like Firebase, gives every new listener the current
/// user first, then every change.
class TestAuthState {
  TestAuthState([this.user]);

  AppUser? user;
  final _changes = StreamController<AppUser?>.broadcast();

  bool get hasListener => _changes.hasListener;

  void set(AppUser? value) {
    user = value;
    _changes.add(value);
  }

  MockAuthRepository repository() {
    final repository = MockAuthRepository();
    when(repository.authStateChanges).thenAnswer(
      (_) => Stream.multi((listener) {
        listener.add(user);
        final subscription = _changes.stream.listen(listener.add);
        listener.onCancel = subscription.cancel;
      }),
    );
    return repository;
  }

  Future<void> close() => _changes.close();
}

MockAuthRepository signedInAuthRepository() {
  final repository = MockAuthRepository();
  when(repository.authStateChanges)
      .thenAnswer((_) => Stream<AppUser?>.value(testUser));
  return repository;
}
