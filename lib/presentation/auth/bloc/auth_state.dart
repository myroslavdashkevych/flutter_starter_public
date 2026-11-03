import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.unknown() = AuthUnknown;

  const factory AuthState.authenticated(AppUser user) = AuthAuthenticated;

  const factory AuthState.unauthenticated() = AuthUnauthenticated;
}
