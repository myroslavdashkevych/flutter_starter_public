import 'package:flutter_starter/app/router/auth_redirect.dart';
import 'package:flutter_starter/presentation/auth/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_fixtures.dart';

void main() {
  const unknown = AuthState.unknown();
  const signedOut = AuthState.unauthenticated();
  const signedIn = AuthState.authenticated(testUser);

  const authPages = ['/sign-in', '/sign-up', '/reset-password'];
  const appPages = ['/items', '/items/5', '/profile', '/settings'];

  String? redirect(AuthState auth, String location) =>
      authRedirect(auth, Uri.parse(location));

  for (final (name, auth) in [
    ('unknown', unknown),
    ('signed out', signedOut),
  ]) {
    test('$name: every page stays', () {
      for (final location in [...authPages, ...appPages]) {
        expect(redirect(auth, location), isNull, reason: location);
      }
    });
  }

  group('signed in', () {
    test('auth pages go to the profile', () {
      for (final location in authPages) {
        expect(redirect(signedIn, location), '/profile', reason: location);
      }
    });

    test('app pages stay', () {
      for (final location in appPages) {
        expect(redirect(signedIn, location), isNull, reason: location);
      }
    });
  });
}
