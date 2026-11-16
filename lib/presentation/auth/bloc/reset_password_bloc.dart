import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/auth/send_password_reset_use_case.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_validator.dart';
import 'package:flutter_starter/presentation/auth/bloc/reset_password_event.dart';
import 'package:flutter_starter/presentation/auth/bloc/reset_password_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  ResetPasswordBloc(this._sendPasswordReset)
    : super(const ResetPasswordState()) {
    // A repeated submit while one runs is ignored (AUTH-4).
    on<ResetPasswordSubmitted>(_onSubmitted, transformer: droppable());
  }

  final SendPasswordResetUseCase _sendPasswordReset;

  Future<void> _onSubmitted(
    ResetPasswordSubmitted event,
    Emitter<ResetPasswordState> emit,
  ) async {
    final emailError = validateEmail(event.email);
    if (emailError != null) {
      emit(ResetPasswordState(emailError: emailError));
      return;
    }

    emit(const ResetPasswordState(isSubmitting: true));
    final result = await _sendPasswordReset((email: event.email));
    emit(switch (result) {
      Ok() => const ResetPasswordState(isSent: true),
      Err(:final failure) => ResetPasswordState(failure: failure),
    });
  }
}
