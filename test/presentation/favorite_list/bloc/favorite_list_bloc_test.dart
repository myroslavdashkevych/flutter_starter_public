import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_user.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/presentation/favorite_list/bloc/favorite_list_bloc.dart';
import 'package:flutter_starter/presentation/favorite_list/bloc/favorite_list_event.dart';
import 'package:flutter_starter/presentation/favorite_list/bloc/favorite_list_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helper/auth_fixture.dart';
import '../../../helper/character_fixture.dart';
import '../../../helper/fake_favorite_repository.dart';

/// Holds every toggle until [release] is called.
class _SlowFavoriteRepository extends FakeFavoriteRepository {
  _SlowFavoriteRepository(super.characters);

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

/// The favorites belong to [testUser]; every other user has none yet.
class _OneUserFavorites extends FakeFavoriteRepository {
  _OneUserFavorites(super.characters, this.otherUsers);

  final StreamController<List<Character>> otherUsers;

  @override
  Stream<List<Character>> watchAll(String uid) =>
      uid == testUser.id ? super.watchAll(uid) : otherUsers.stream;
}

void main() {
  late TestAuthState auth;
  late FakeFavoriteRepository favorites;

  FavoriteListBloc build() => favoriteListBloc(auth.repository(), favorites);

  setUp(() {
    auth = TestAuthState(testUser);
    favorites = FakeFavoriteRepository([testCharacter(2), testCharacter(1)]);
  });

  tearDown(() => auth.close());

  test('FAV-12: starts with an unknown auth state and no characters', () async {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.authStatus, FavoriteListAuthStatus.unknown);
    expect(bloc.state.characters, isNull);
  });

  blocTest<FavoriteListBloc, FavoriteListState>(
    'FAV-5: a user sees the characters in the repository order',
    build: build,
    wait: Duration.zero,
    verify: (bloc) {
      expect(bloc.state.authStatus, FavoriteListAuthStatus.signedIn);
      expect(bloc.state.characters, [testCharacter(2), testCharacter(1)]);
    },
  );

  blocTest<FavoriteListBloc, FavoriteListState>(
    'FAV-6: a guest gets the guest state',
    setUp: () => auth.user = null,
    build: build,
    wait: Duration.zero,
    verify: (bloc) {
      expect(bloc.state.authStatus, FavoriteListAuthStatus.guest);
      expect(bloc.state.characters, isEmpty);
    },
  );

  test('FAV-12, FAV-16: a user change shows the progress state, then the new '
      "user's favorites", () async {
    final otherUsers = StreamController<List<Character>>.broadcast();
    addTearDown(otherUsers.close);
    final oneUser = _OneUserFavorites([testCharacter(1)], otherUsers);
    favorites = oneUser;
    final bloc = build();
    addTearDown(bloc.close);
    await pumpEventQueue();
    expect(bloc.state.characters, [testCharacter(1)]);

    auth.set(const AppUser(id: 'other'));
    await pumpEventQueue();
    expect(bloc.state.authStatus, FavoriteListAuthStatus.signedIn);
    expect(bloc.state.characters, isNull);

    oneUser.otherUsers.add([testCharacter(3)]);
    await pumpEventQueue();
    expect(bloc.state.characters, [testCharacter(3)]);
  });

  blocTest<FavoriteListBloc, FavoriteListState>(
    'FAV-16: after sign-out no favorites are shown',
    build: build,
    act: (_) async {
      await pumpEventQueue();
      auth.set(null);
    },
    wait: Duration.zero,
    verify: (bloc) {
      expect(bloc.state.authStatus, FavoriteListAuthStatus.guest);
      expect(bloc.state.characters, isEmpty);
    },
  );

  test('stops following the user when closed', () async {
    final bloc = build();
    await pumpEventQueue();
    expect(auth.hasListener, isTrue);

    await bloc.close();

    expect(auth.hasListener, isFalse);
  });

  blocTest<FavoriteListBloc, FavoriteListState>(
    'FAV-3: removing an character elsewhere updates the list',
    build: build,
    act: (_) async {
      await pumpEventQueue();
      await favorites.toggle(testUser.id, testCharacter(2));
    },
    wait: Duration.zero,
    verify: (bloc) => expect(bloc.state.characters, [testCharacter(1)]),
  );

  blocTest<FavoriteListBloc, FavoriteListState>(
    'FAV-15: remove takes the character out by its id',
    build: build,
    act: (bloc) async {
      await pumpEventQueue();
      bloc.add(const FavoriteListRemoveRequested(1));
    },
    wait: Duration.zero,
    verify: (bloc) => expect(bloc.state.characters, [testCharacter(2)]),
  );

  blocTest<FavoriteListBloc, FavoriteListState>(
    'FAV-4: a failed remove keeps the character and reports the failure',
    build: () {
      favorites.toggleFailure = const Failure.cache();
      return build();
    },
    act: (bloc) async {
      await pumpEventQueue();
      bloc.add(const FavoriteListRemoveRequested(1));
    },
    wait: Duration.zero,
    verify: (bloc) {
      expect(bloc.state.characters, [testCharacter(2), testCharacter(1)]);
      expect(bloc.state.removeFailure, const Failure.cache());
    },
  );

  test('a remove while one runs starts no second request', () async {
    final slow = _SlowFavoriteRepository([testCharacter(2), testCharacter(1)]);
    favorites = slow;
    final bloc = build();
    addTearDown(bloc.close);
    await pumpEventQueue();

    bloc
      ..add(const FavoriteListRemoveRequested(1))
      ..add(const FavoriteListRemoveRequested(1));
    await pumpEventQueue();
    slow.release();
    await pumpEventQueue();

    expect(slow.toggleCalls, 1);
    expect(bloc.state.characters, [testCharacter(2)]);
  });

  blocTest<FavoriteListBloc, FavoriteListState>(
    'removing an id that is not a favorite does nothing',
    build: build,
    act: (bloc) async {
      await pumpEventQueue();
      bloc.add(const FavoriteListRemoveRequested(99));
    },
    wait: Duration.zero,
    verify: (bloc) {
      expect(bloc.state.characters, [testCharacter(2), testCharacter(1)]);
      expect(bloc.state.removeFailure, isNull);
    },
  );
}
