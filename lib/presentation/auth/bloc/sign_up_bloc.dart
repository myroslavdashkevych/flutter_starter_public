import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_up_use_case.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_validator.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_event.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_up_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc(this._signUp) : super(const SignUpState()) {
    // A repeated submit while one runs is ignored (AUTH-4).
    on<SignUpSubmitted>(_onSubmitted, transformer: droppable());
  }

  final SignUpUseCase _signUp;

  Future<void> _onSubmitted(
    SignUpSubmitted event,
    Emitter<SignUpState> emit,
  ) async {
    final emailError = validateEmail(event.email);
    final passwordError = validatePassword(event.password);
    final confirmationError = validateConfirmation(
      event.password,
      event.confirmation,
    );
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
    final result = await _signUp((
      email: event.email,
      password: event.password,
    ));
    emit(switch (result) {
      Ok() => const SignUpState(isSuccess: true),
      Err(:final failure) => SignUpState(failure: failure),
    });
  }
}
