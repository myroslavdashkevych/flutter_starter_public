import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_field_error.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_up_state.freezed.dart';

@freezed
abstract class SignUpState with _$SignUpState {
  const factory SignUpState({
    AuthFieldError? emailError,
    AuthFieldError? passwordError,
    AuthFieldError? confirmationError,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    Failure? failure,
  }) = _SignUpState;
}
