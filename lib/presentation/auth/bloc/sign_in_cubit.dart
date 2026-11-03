import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_events.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_service.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_validators.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._repository, this._analytics) : super(const SignInState());

  final AuthRepository _repository;
  final AnalyticsService _analytics;

  Future<void> submit({required String email, required String password}) async {
    final emailError = validateEmail(email);
    final passwordError = validatePassword(password);
    if (emailError != null || passwordError != null) {
      emit(SignInState(emailError: emailError, passwordError: passwordError));
      return;
    }

    emit(const SignInState(isSubmitting: true));
    final result = await _repository.signIn(email: email, password: password);
    if (result is Ok) {
      unawaited(
        _analytics.logEvent(
          AnalyticsEvents.login,
          parameters: const {
            AnalyticsParams.method: AnalyticsValues.passwordMethod,
          },
        ),
      );
    }
    if (isClosed) return;
    emit(switch (result) {
      Ok() => const SignInState(isSuccess: true),
      Err(:final failure) => SignInState(failure: failure),
    });
  }
}
