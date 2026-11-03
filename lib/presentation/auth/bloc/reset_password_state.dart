import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_validators.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reset_password_state.freezed.dart';

@freezed
abstract class ResetPasswordState with _$ResetPasswordState {
  const factory ResetPasswordState({
    AuthFieldError? emailError,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSent,
    Failure? failure,
  }) = _ResetPasswordState;
}
