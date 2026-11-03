import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_events.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_service.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_validators.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit(this._repository, this._analytics) : super(const SignUpState());

  final AuthRepository _repository;
  final AnalyticsService _analytics;

  Future<void> submit({
    required String email,
    required String password,
    required String confirmation,
  }) async {
    final emailError = validateEmail(email);
    final passwordError = validatePassword(password);
    final confirmationError = validateConfirmation(password, confirmation);
    if (emailError != null ||
        passwordError != null ||
        confirmationError != null) {
      emit(
        SignUpState(
          emailError: emailError,
          passwordError: passwordError,
          confirmationError: confirmationError,
        ),
      );
      return;
    }

    emit(const SignUpState(isSubmitting: true));
    final result = await _repository.signUp(email: email, password: password);
    if (result is Ok) {
      unawaited(
        _analytics.logEvent(
          AnalyticsEvents.signUp,
          parameters: const {
            AnalyticsParams.method: AnalyticsValues.passwordMethod,
          },
        ),
      );
    }
    if (isClosed) return;
    emit(switch (result) {
      Ok() => const SignUpState(isSuccess: true),
      Err(:final failure) => SignUpState(failure: failure),
    });
  }
}
