import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/use_case/auth/sign_in_use_case.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_validator.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_event.dart';
import 'package:flutter_starter/presentation/auth/bloc/sign_in_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc(this._signIn) : super(const SignInState()) {
    // A repeated submit while one runs is ignored (AUTH-4).
    on<SignInSubmitted>(_onSubmitted, transformer: droppable());
  }

  final SignInUseCase _signIn;

  Future<void> _onSubmitted(
    SignInSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    final emailError = validateEmail(event.email);
    final passwordError = validatePassword(event.password);
    if (emailError != null || passwordError != null) {
      emit(SignInState(emailError: emailError, passwordError: passwordError));
      return;
    }

    emit(const SignInState(isSubmitting: true));
    final result = await _signIn((
      email: event.email,
      password: event.password,
    ));
    emit(switch (result) {
      Ok() => const SignInState(isSuccess: true),
      Err(:final failure) => SignInState(failure: failure),
    });
  }
}
