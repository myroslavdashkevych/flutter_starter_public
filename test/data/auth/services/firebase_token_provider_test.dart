import 'package:flutter_starter/data/auth/services/firebase_token_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockFirebaseAuth auth;
  late FirebaseTokenProvider provider;

  setUp(() {
    auth = MockFirebaseAuth();
    provider = FirebaseTokenProvider(auth);
  });

  test('returns null without a signed-in user', () async {
    when(() => auth.currentUser).thenReturn(null);

    expect(await provider.getToken(), isNull);
  });

  test('returns the token of the current user', () async {
    final user = MockFirebaseUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.getIdToken(false)).thenAnswer((_) async => 'token');

    expect(await provider.getToken(), 'token');
  });

  test('passes forceRefresh to Firebase', () async {
    final user = MockFirebaseUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.getIdToken(true)).thenAnswer((_) async => 'fresh');

    expect(await provider.getToken(forceRefresh: true), 'fresh');
  });

  test('onUnauthorized signs out', () async {
    when(auth.signOut).thenAnswer((_) async {});

    await provider.onUnauthorized();

    verify(auth.signOut).called(1);
  });
}
