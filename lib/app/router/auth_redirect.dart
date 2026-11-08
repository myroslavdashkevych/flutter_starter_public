import 'package:flutter_starter/app/router/routes.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_state.dart';

/// The redirect rule NAV-5 from `docs/spec/features/navigation.md`.
String? authRedirect(AuthState auth, Uri uri) {
  final isAuthPage =
      uri.path == const SignInRoute().location ||
      uri.path == const SignUpRoute().location ||
      uri.path == const ResetPasswordRoute().location;

  return auth is AuthAuthenticated && isAuthPage
      ? const ProfileRoute().location
      : null;
}
