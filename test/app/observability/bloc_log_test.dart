import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_starter/app/observability/bloc_logging.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/use_case/auth/delete_account_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_in_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_out_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_up_use_case.dart';
import 'package:flutter_starter/domain/use_case/auth/watch_auth_state_use_case.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_bloc.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_event.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_bloc.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_event.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_bloc.dart';
import 'package:flutter_starter/presentation/profile/bloc/profile_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

import '../../helper/fake_analytics_service.dart';
import '../../helper/fake_favorite_repository.dart';
import '../../helper/mock.dart';

void main() {
  const email = 'user@example.com';
  const password = 'secret-password-1';
  const failure = Failure.auth(AuthFailureReason.invalidCredentials);

  late Talker talker;
  late MockAuthRepository repository;
  late BlocObserver previousObserver;

  setUp(() {
    talker = Talker();
    previousObserver = Bloc.observer;
    Bloc.observer = createBlocObserver(talker: talker, flavor: Flavor.dev);
    repository = MockAuthRepository();
    when(repository.authStateChanges)
        .thenAnswer((_) => const Stream<AppUser?>.empty());
    when(() => repository.signIn(email: email, password: password))
        .thenAnswer((_) async => const Err(failure));
    when(() => repository.signUp(email: email, password: password))
        .thenAnswer((_) async => const Err(failure));
    when(() => repository.reauthenticate(password: password))
        .thenAnswer((_) async => const Err(failure));
  });

  tearDown(() => Bloc.observer = previousObserver);

  test(
    'OBS-7: logs of sign-in, sign-up and delete events carry no password',
    () async {
      final signIn = SignInBloc(
        SignInUseCase(repository, FakeAnalyticsService()),
      );
      final signUp = SignUpBloc(
        SignUpUseCase(repository, FakeAnalyticsService()),
      );
      final profile = ProfileBloc(
        WatchAuthStateUseCase(repository),
        SignOutUseCase(repository),
        DeleteAccountUseCase(
          repository,
          FakeFavoriteRepository(),
          FakeAnalyticsService(),
        ),
      );

      signIn.add(const SignInSubmitted(email: email, password: password));
      signUp.add(
        const SignUpSubmitted(
          email: email,
          password: password,
          confirmation: password,
        ),
      );
      profile.add(const ProfileDeleteRequested(password: password));
      await pumpEventQueue();
      await Future.wait([signIn.close(), signUp.close(), profile.close()]);

      final logs = [
        for (final log in talker.history) log.generateTextMessage(),
      ];
      expect(
        logs.where((log) => log.contains('receive event')),
        hasLength(greaterThanOrEqualTo(3)),
        reason: 'the events must be logged for this test to mean anything',
      );
      for (final log in logs) {
        expect(log, isNot(contains(password)));
      }
    },
  );
}
