import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_field_error.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_state.freezed.dart';

@freezed
abstract class SignInState with _$SignInState {
  const factory SignInState({
    AuthFieldError? emailError,
    AuthFieldError? passwordError,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    Failure? failure,
  }) = _SignInState;
}
