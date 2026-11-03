import 'package:flutter_starter/domain/auth/entities/app_user.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class AuthUserChanged extends AuthEvent {
  const AuthUserChanged(this.user);

  final AppUser? user;
}
