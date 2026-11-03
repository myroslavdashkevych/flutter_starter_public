import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_events.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_service.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_validators.dart';
import 'package:flutter_starter/presentation/auth/bloc/reset_password_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  ResetPasswordCubit(this._repository, this._analytics)
    : super(const ResetPasswordState());

  final AuthRepository _repository;
  final AnalyticsService _analytics;

  Future<void> submit({required String email}) async {
    final emailError = validateEmail(email);
    if (emailError != null) {
      emit(ResetPasswordState(emailError: emailError));
      return;
    }

    emit(const ResetPasswordState(isSubmitting: true));
    final result = await _repository.sendPasswordReset(email: email);
    if (result is Ok) {
      unawaited(_analytics.logEvent(AnalyticsEvents.passwordResetRequested));
    }
    if (isClosed) return;
    emit(switch (result) {
      Ok() => const ResetPasswordState(isSent: true),
      Err(:final failure) => ResetPasswordState(failure: failure),
    });
  }
}
