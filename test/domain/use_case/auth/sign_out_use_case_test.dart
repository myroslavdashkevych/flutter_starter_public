import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_out_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/mock.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  test('signs out and passes the success through', () async {
    when(repository.signOut).thenAnswer((_) async => const Ok(null));

    final result = await SignOutUseCase(repository)(());

    expect(result, isA<Ok<void>>());
    verify(repository.signOut).called(1);
  });

  test('passes a failure through', () async {
    when(repository.signOut)
        .thenAnswer((_) async => const Err(Failure.unexpected()));

    final result = await SignOutUseCase(repository)(());

    expect(result, isA<Err<void>>());
  });
}
