import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/presentation/_shared/component/favorite_toggle/bloc/favorite_toggle_bloc.dart';
import 'package:flutter_starter/presentation/_shared/component/favorite_toggle/bloc/favorite_toggle_event.dart';
import 'package:flutter_starter/presentation/_shared/component/favorite_toggle/bloc/favorite_toggle_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helper/auth_fixture.dart';
import '../../../../../helper/character_fixture.dart';
import '../../../../../helper/fake_favorite_repository.dart';
import '../../../../../helper/mock.dart';

/// Holds every toggle until [release] is called.
class _SlowFavoriteRepository extends FakeFavoriteRepository {
  final _gate = Completer<void>();
  var toggleCalls = 0;

  void release() => _gate.complete();

  @override
  Future<Result<bool>> toggle(String uid, Character character) async {
    toggleCalls++;
    await _gate.future;
    return super.toggle(uid, character);
  }
}

/// The favorites belong to [testUser]; every other user has none.
class _OneUserFavorites extends FakeFavoriteRepository {
  _OneUserFavorites(super.characters);

  @override
  Stream<List<Character>> watchAll(String uid) =>
      uid == testUser.id ? super.watchAll(uid) : Stream.value(const []);
}

void main() {
  late MockAuthRepository authRepository;
  late FakeFavoriteRepository favorites;

  FavoriteToggleBloc build() => favoriteToggleBloc(authRepository, favorites);

  setUp(() {
    authRepository = signedInAuthRepository();
    favorites = FakeFavoriteRepository();
  });

  blocTest<FavoriteToggleBloc, FavoriteToggleState>(
    'FAV-2: a guest is not signed in',
    setUp: () {
      when(authRepository.authStateChanges)
          .thenAnswer((_) => Stream<AppUser?>.value(null));
    },
    build: build,
    act: (bloc) => bloc.add(const FavoriteToggleStarted(1)),
    wait: Duration.zero,
    verify: (bloc) {
      expect(bloc.state.isSignedIn, isFalse);
      expect(bloc.state.isFavorite, isFalse);
    },
  );

  blocTest<FavoriteToggleBloc, FavoriteToggleState>(
    'FAV-1: a user sees the current state of the character',
    setUp: () => favorites = FakeFavoriteRepository([testCharacter(1)]),
    build: build,
    act: (bloc) => bloc.add(const FavoriteToggleStarted(1)),
    wait: Duration.zero,
    verify: (bloc) {
      expect(bloc.state.isSignedIn, isTrue);
      expect(bloc.state.isFavorite, isTrue);
    },
  );

  blocTest<FavoriteToggleBloc, FavoriteToggleState>(
    'FAV-3: follows a change made on another screen',
    build: build,
    act: (bloc) async {
      bloc.add(const FavoriteToggleStarted(1));
      await pumpEventQueue();
      await favorites.toggle(testUser.id, testCharacter(1));
    },
    wait: Duration.zero,
    verify: (bloc) => expect(bloc.state.isFavorite, isTrue),
  );

  test('FAV-16: a user change hides the mark at once, sign-out hides the '
      'toggle', () async {
    final auth = TestAuthState(testUser);
    addTearDown(auth.close);
    final bloc = favoriteToggleBloc(
      auth.repository(),
      _OneUserFavorites([testCharacter(1)]),
    )..add(const FavoriteToggleStarted(1));
    addTearDown(bloc.close);
    await pumpEventQueue();
    expect(bloc.state.isFavorite, isTrue);

    auth.set(const AppUser(id: 'other'));
    await pumpEventQueue();
    expect(bloc.state.isSignedIn, isTrue);
    expect(bloc.state.isFavorite, isFalse);

    auth.set(null);
    await pumpEventQueue();
    expect(bloc.state.isSignedIn, isFalse);
  });

  blocTest<FavoriteToggleBloc, FavoriteToggleState>(
    'a new start follows the new character only',
    build: build,
    act: (bloc) async {
      bloc.add(const FavoriteToggleStarted(1));
      await pumpEventQueue();
      bloc.add(const FavoriteToggleStarted(2));
      await pumpEventQueue();
      // Marks character 1 only: a subscription to character 1 left running would
      // report it as the mark of this toggle.
      await favorites.toggle(testUser.id, testCharacter(1));
    },
    wait: Duration.zero,
    verify: (bloc) => expect(bloc.state.isFavorite, isFalse),
  );

  test('stops following the user when closed', () async {
    final users = StreamController<AppUser?>();
    addTearDown(users.close);
    when(authRepository.authStateChanges).thenAnswer((_) => users.stream);
    final bloc = build()..add(const FavoriteToggleStarted(1));
    await pumpEventQueue();
    expect(users.hasListener, isTrue);

    await bloc.close();

    expect(users.hasListener, isFalse);
  });

  blocTest<FavoriteToggleBloc, FavoriteToggleState>(
    'FAV-1: toggle flips the state',
    build: build,
    act: (bloc) async {
      bloc.add(const FavoriteToggleStarted(1));
      await pumpEventQueue();
      bloc.add(FavoriteToggleTapped(testCharacter(1)));
    },
    wait: Duration.zero,
    verify: (bloc) {
      expect(bloc.state.isFavorite, isTrue);
      expect(bloc.state.failure, isNull);
    },
  );

  blocTest<FavoriteToggleBloc, FavoriteToggleState>(
    'FAV-4: a failed toggle reports the failure and keeps the state',
    setUp: () {
      favorites.toggleFailure = const Failure.cache();
    },
    build: build,
    act: (bloc) async {
      bloc.add(const FavoriteToggleStarted(1));
      await pumpEventQueue();
      bloc.add(FavoriteToggleTapped(testCharacter(1)));
    },
    wait: Duration.zero,
    verify: (bloc) {
      expect(bloc.state.isFavorite, isFalse);
      expect(bloc.state.failure, const Failure.cache());
    },
  );

  late _SlowFavoriteRepository slow;
  blocTest<FavoriteToggleBloc, FavoriteToggleState>(
    'FAV-17: a tap while a toggle runs starts no second request',
    setUp: () => favorites = slow = _SlowFavoriteRepository(),
    build: build,
    act: (bloc) async {
      bloc.add(const FavoriteToggleStarted(1));
      await pumpEventQueue();
      bloc
        ..add(FavoriteToggleTapped(testCharacter(1)))
        ..add(FavoriteToggleTapped(testCharacter(1)));
      await pumpEventQueue();
      slow.release();
    },
    wait: Duration.zero,
    verify: (bloc) {
      expect(slow.toggleCalls, 1);
      expect(bloc.state.isFavorite, isTrue);
    },
  );
}
