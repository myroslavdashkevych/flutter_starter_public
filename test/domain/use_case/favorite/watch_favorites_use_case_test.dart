import 'dart:async';

import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/domain/entity/user_favorites.dart';
import 'package:flutter_starter/domain/use_case/favorite/watch_favorites_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/auth_fixture.dart';
import '../../../helper/character_fixture.dart';
import '../../../helper/mock.dart';

void main() {
  const alice = AppUser(id: 'alice');
  const bob = AppUser(id: 'bob');

  late TestAuthState auth;
  late MockFavoriteRepository repository;
  late Map<String, StreamController<List<Character>>> favoritesOf;
  late WatchFavoritesUseCase useCase;

  setUp(() {
    auth = TestAuthState(alice);
    repository = MockFavoriteRepository();
    favoritesOf = {};
    when(() => repository.watchAll(any())).thenAnswer(
      (invocation) =>
          (favoritesOf[invocation.positionalArguments.first as String] ??=
                  StreamController<List<Character>>.broadcast())
              .stream,
    );
    useCase = WatchFavoritesUseCase(auth.repository(), repository);
  });

  tearDown(() async {
    await auth.close();
    for (final controller in favoritesOf.values) {
      await controller.close();
    }
  });

  Future<List<UserFavorites>> collect(Future<void> Function() act) async {
    final emitted = <UserFavorites>[];
    final subscription = useCase(()).listen(emitted.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();
    await act();
    await pumpEventQueue();
    return emitted;
  }

  test('FAV-6: a guest gets the guest state', () async {
    auth.user = null;

    final emitted = await collect(() async {});

    expect(emitted, [const UserFavorites.guest()]);
    verifyNever(() => repository.watchAll(any()));
  });

  test('FAV-12: favorites not read yet are unknown', () async {
    final emitted = await collect(() async {});

    expect(emitted, [const UserFavorites.signedIn()]);
  });

  test(
    "FAV-5: a user gets their favorites in the repository's order",
    () async {
      final emitted = await collect(
        () async =>
            favoritesOf['alice']!.add([testCharacter(2), testCharacter(1)]),
      );

      expect(
        emitted.last,
        UserFavorites.signedIn(
          characters: [testCharacter(2), testCharacter(1)],
        ),
      );
    },
  );

  test('FAV-16: a user change hides the previous favorites at once', () async {
    final emitted = await collect(() async {
      favoritesOf['alice']!.add([testCharacter(1)]);
      await pumpEventQueue();
      auth.set(bob);
      await pumpEventQueue();
      favoritesOf['alice']!.add([testCharacter(1), testCharacter(3)]);
      favoritesOf['bob']!.add([testCharacter(2)]);
    });

    expect(emitted, [
      const UserFavorites.signedIn(),
      UserFavorites.signedIn(characters: [testCharacter(1)]),
      const UserFavorites.signedIn(),
      UserFavorites.signedIn(characters: [testCharacter(2)]),
    ]);
  });

  test('FAV-16: after sign-out no favorites are shown', () async {
    final emitted = await collect(() async {
      favoritesOf['alice']!.add([testCharacter(1)]);
      await pumpEventQueue();
      auth.set(null);
      await pumpEventQueue();
      favoritesOf['alice']!.add([testCharacter(1), testCharacter(3)]);
    });

    expect(emitted.last, const UserFavorites.guest());
    expect(favoritesOf['alice']!.hasListener, isFalse);
  });

  test("FAV-16: signing in again shows that user's favorites", () async {
    final emitted = await collect(() async {
      auth.set(null);
      await pumpEventQueue();
      auth.set(alice);
      await pumpEventQueue();
      favoritesOf['alice']!.add([testCharacter(1)]);
    });

    expect(
      emitted.last,
      UserFavorites.signedIn(characters: [testCharacter(1)]),
    );
    verify(() => repository.watchAll('alice')).called(2);
  });

  test('the same user again does not restart the favorites', () async {
    await collect(() async {
      auth.set(alice);
    });

    verify(() => repository.watchAll('alice')).called(1);
  });
}
