import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/use_case/auth/watch_auth_state_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/auth_fixture.dart';
import '../../../helper/mock.dart';

void main() {
  test('emits what the repository emits', () async {
    final repository = MockAuthRepository();
    when(repository.authStateChanges)
        .thenAnswer((_) => Stream<AppUser?>.fromIterable([testUser, null]));

    final users = await WatchAuthStateUseCase(repository)(()).toList();

    expect(users, [testUser, null]);
  });
}
