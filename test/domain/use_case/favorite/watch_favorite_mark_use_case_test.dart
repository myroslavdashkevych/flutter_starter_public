import 'dart:async';

import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/entity/favorite_mark.dart';
import 'package:flutter_starter/domain/use_case/favorite/watch_favorite_mark_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helper/auth_fixture.dart';
import '../../../helper/mock.dart';

void main() {
  const alice = AppUser(id: 'alice');
  const bob = AppUser(id: 'bob');

  late TestAuthState auth;
  late MockFavoriteRepository repository;
  late Map<String, StreamController<bool>> markOf;
  late WatchFavoriteMarkUseCase useCase;

  setUp(() {
    auth = TestAuthState(alice);
    repository = MockFavoriteRepository();
    markOf = {};
    when(() => repository.watchIsFavorite(any(), 5)).thenAnswer(
      (invocation) =>
          (markOf[invocation.positionalArguments.first as String] ??=
                  StreamController<bool>.broadcast())
              .stream,
    );
    useCase = WatchFavoriteMarkUseCase(auth.repository(), repository);
  });

  tearDown(() async {
    await auth.close();
    for (final controller in markOf.values) {
      await controller.close();
    }
  });

  Future<List<FavoriteMark>> collect(Future<void> Function() act) async {
    final emitted = <FavoriteMark>[];
    final subscription = useCase((characterId: 5)).listen(emitted.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();
    await act();
    await pumpEventQueue();
    return emitted;
  }

  test('FAV-2: a guest gets no mark', () async {
    auth.user = null;

    final emitted = await collect(() async {});

    expect(emitted, [const FavoriteMark.guest()]);
    verifyNever(() => repository.watchIsFavorite(any(), any()));
  });

  test('FAV-1: a user gets the mark of the character', () async {
    final emitted = await collect(() async => markOf['alice']!.add(true));

    expect(emitted, [
      const FavoriteMark.signedIn(isFavorite: false),
      const FavoriteMark.signedIn(isFavorite: true),
    ]);
  });

  test('FAV-16: a user change hides the previous mark at once', () async {
    final emitted = await collect(() async {
      markOf['alice']!.add(true);
      await pumpEventQueue();
      auth.set(bob);
      await pumpEventQueue();
      markOf['alice']!.add(true);
    });

    expect(emitted, [
      const FavoriteMark.signedIn(isFavorite: false),
      const FavoriteMark.signedIn(isFavorite: true),
      const FavoriteMark.signedIn(isFavorite: false),
    ]);
  });

  test('the same user again does not restart the mark', () async {
    await collect(() async => auth.set(alice));

    verify(() => repository.watchIsFavorite('alice', 5)).called(1);
  });

  test('FAV-2, FAV-16: after sign-out the mark is gone', () async {
    final emitted = await collect(() async {
      markOf['alice']!.add(true);
      await pumpEventQueue();
      auth.set(null);
    });

    expect(emitted.last, const FavoriteMark.guest());
    expect(markOf['alice']!.hasListener, isFalse);
  });
}
