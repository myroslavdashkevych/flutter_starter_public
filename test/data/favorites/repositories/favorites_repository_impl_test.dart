import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_starter/data/favorites/datasources/favorites_local_data_source.dart';
import 'package:flutter_starter/data/favorites/models/favorite_item_mapper.dart';
import 'package:flutter_starter/data/favorites/repositories/favorites_repository_impl.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

import '../../../helpers/items_fixtures.dart';
import '../../../helpers/mocks.dart';

class _MockLocalDataSource extends Mock implements FavoritesLocalDataSource {}

void main() {
  const alice = AppUser(id: 'Alice-1', email: 'alice@example.com');
  const bob = AppUser(id: 'bob-2', email: 'bob@example.com');

  late Directory directory;
  late MockAuthRepository authRepository;
  late StreamController<AppUser?> users;
  late Talker talker;
  AppUser? currentUser;

  FavoritesRepositoryImpl build([FavoritesLocalDataSource? dataSource]) =>
      FavoritesRepositoryImpl(
        authRepository,
        dataSource ?? FavoritesLocalDataSource(Hive, talker),
        talker,
      );

  // Waits for the repository to finish following the change.
  Future<void> switchUser(
    FavoritesRepositoryImpl repository,
    AppUser? user,
  ) async {
    currentUser = user;
    users.add(user);
    await Future<void>.delayed(Duration.zero);
    await repository.clearForUser('flush');
  }

  Future<List<int>> favoriteIds(FavoritesRepositoryImpl repository) async {
    final items = await repository.watchAll().first;
    return items.map((item) => item.id).toList();
  }

  Future<LazyBox<String>> openBox(String uid) =>
      Hive.openLazyBox<String>(FavoritesLocalDataSource.boxName(uid));

  String envelope(Object? schemaVersion, Item item) => jsonEncode({
    'schemaVersion': schemaVersion,
    'addedAt': '2026-01-01T00:00:00.000',
    'data': {
      'id': item.id,
      'name': item.name,
      'imageUrl': item.imageUrl,
      'status': item.status.name,
      'species': item.species,
      'gender': item.gender,
      'originName': item.originName,
      'locationName': item.locationName,
      'episodeCount': item.episodeCount,
    },
  });

  setUp(() {
    directory = Directory.systemTemp.createTempSync('favorites_test');
    Hive.init(directory.path);
    talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    authRepository = MockAuthRepository();
    users = StreamController<AppUser?>.broadcast();
    currentUser = alice;
    // Like Firebase: every new listener gets the current user first.
    when(authRepository.authStateChanges).thenAnswer(
      (_) => Stream.multi((listener) {
        listener.add(currentUser);
        final subscription = users.stream.listen(listener.add);
        listener.onCancel = subscription.cancel;
      }),
    );
  });

  tearDown(() async {
    await users.close();
    await Hive.close();
    directory.deleteSync(recursive: true);
  });

  group('toggle', () {
    test('FAV-1: adds the item, then removes it', () async {
      final repository = build();

      expect(
        await repository.toggle(testItem(1)),
        isA<Ok<bool>>().having((ok) => ok.value, 'value', isTrue),
      );
      expect(await repository.watchAll().first, [testItem(1)]);

      expect(
        await repository.toggle(testItem(1)),
        isA<Ok<bool>>().having((ok) => ok.value, 'value', isFalse),
      );
      expect(await repository.watchAll().first, isEmpty);
    });

    test('FAV-2: a guest cannot change favorites', () async {
      currentUser = null;
      final repository = build();

      final result = await repository.toggle(testItem(1));

      expect(result, isA<Err<bool>>());
      expect(await repository.watchAll().first, isEmpty);
    });

    test('FAV-3: notifies the streams', () async {
      final repository = build();
      final isFavorite = <bool>[];
      final subscription = repository.watchIsFavorite(1).listen(isFavorite.add);
      addTearDown(subscription.cancel);

      await repository.watchAll().first;
      await repository.toggle(testItem(2));
      await repository.toggle(testItem(1));
      await repository.toggle(testItem(1));
      await Future<void>.delayed(Duration.zero);

      expect(isFavorite, [false, true, false]);
    });
  });

  group('storage', () {
    test('FAV-5, FAV-7: survives a restart, newest first', () async {
      final repository = build();
      await repository.toggle(testItem(1));
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repository.toggle(testItem(2));
      expect(await favoriteIds(repository), [2, 1]);
      await Hive.close();

      expect(await favoriteIds(build()), [2, 1]);
    });

    test('keeps every field of the item', () async {
      final item = testItem(1).copyWith(status: ItemStatus.dead);
      await build().toggle(item);
      await Hive.close();

      expect(await build().watchAll().first, [item]);
    });

    test('an unknown status reads as unknown', () async {
      final box = await openBox(alice.id);
      final raw = jsonDecode(envelope(1, testItem(1))) as Map<String, dynamic>;
      (raw['data'] as Map<String, dynamic>)['status'] = 'zombie';
      await box.put('1', jsonEncode(raw));

      final items = await build().watchAll().first;

      expect(items.single.status, ItemStatus.unknown);
    });

    test('writes the envelope with the schema version', () async {
      await build().toggle(testItem(1));

      final box = await openBox(alice.id);
      final stored = jsonDecode((await box.get('1'))!) as Map<String, dynamic>;

      expect(stored['schemaVersion'], 1);
      expect(DateTime.tryParse(stored['addedAt'] as String), isNotNull);
      expect((stored['data'] as Map<String, dynamic>)['name'], 'Item 1');
    });

    test('FAV-8: a record with another schema is skipped and kept', () async {
      final box = await openBox(alice.id);
      await box.put('1', envelope(99, testItem(1)));
      await box.put('2', envelope(1, testItem(2)));

      expect(await favoriteIds(build()), [2]);
      expect(await box.get('1'), envelope(99, testItem(1)));
    });

    test('FAV-8: a corrupt record is skipped, kept and logged', () async {
      final box = await openBox(alice.id);
      await box.put('1', 'not json');
      await box.put('2', envelope(1, testItem(2)));

      expect(await favoriteIds(build()), [2]);
      expect(await box.get('1'), 'not json');
      expect(talker.history, isNotEmpty);
    });

    test('FAV-8: toggling a skipped record overwrites it', () async {
      final box = await openBox(alice.id);
      await box.put('1', 'not json');
      final repository = build();

      final result = await repository.toggle(testItem(1));

      expect(result, isA<Ok<bool>>().having((ok) => ok.value, 'value', isTrue));
      expect(await favoriteIds(repository), [1]);
    });
  });

  group('users', () {
    test('FAV-16: every user has a separate box', () async {
      final repository = build();
      await repository.toggle(testItem(1));

      await switchUser(repository, bob);
      expect(await favoriteIds(repository), isEmpty);
      await repository.toggle(testItem(2));
      expect(await favoriteIds(repository), [2]);

      await switchUser(repository, alice);
      expect(await favoriteIds(repository), [1]);
    });

    test('the box name is the user id in hex', () {
      expect(FavoritesLocalDataSource.boxName('aB'), 'favorites_6142');
      expect(
        FavoritesLocalDataSource.boxName('ab'),
        isNot(FavoritesLocalDataSource.boxName('AB')),
      );
    });

    test('switching closes the old box and opens the new one', () async {
      final repository = build();
      await repository.toggle(testItem(1));

      await switchUser(repository, bob);

      expect(
        Hive.isBoxOpen(FavoritesLocalDataSource.boxName(alice.id)),
        isFalse,
      );
      expect(Hive.isBoxOpen(FavoritesLocalDataSource.boxName(bob.id)), isTrue);
    });

    test(
      'FAV-16: a user change hides the previous favorites at once',
      () async {
        final repository = build();
        await repository.toggle(testItem(1));
        final emitted = <List<Item>>[];
        final subscription = repository.watchAll().listen(emitted.add);
        addTearDown(subscription.cancel);
        await Future<void>.delayed(Duration.zero);

        await switchUser(repository, bob);

        expect(emitted, [
          [testItem(1)],
          isEmpty,
          isEmpty,
        ]);
      },
    );

    test(
      'FAV-16: signing out leaves an empty state and closes the box',
      () async {
        final repository = build();
        await repository.toggle(testItem(1));

        await switchUser(repository, null);

        expect(await favoriteIds(repository), isEmpty);
        expect(
          Hive.isBoxOpen(FavoritesLocalDataSource.boxName(alice.id)),
          isFalse,
        );
      },
    );

    test('FAV-16: signing in again restores the favorites', () async {
      final repository = build();
      await repository.toggle(testItem(1));
      await switchUser(repository, null);

      await switchUser(repository, alice);

      expect(await favoriteIds(repository), [1]);
    });
  });

  group('clearForUser', () {
    Future<bool> boxExists(String uid) =>
        Hive.boxExists(FavoritesLocalDataSource.boxName(uid));

    test('PRF-6: deletes the box of the current user', () async {
      final repository = build();
      await repository.toggle(testItem(1));

      final result = await repository.clearForUser(alice.id);

      expect(result, isA<Ok<void>>());
      expect(await boxExists(alice.id), isFalse);
      expect(await favoriteIds(repository), isEmpty);
    });

    test('works after the session has ended', () async {
      final repository = build();
      await repository.toggle(testItem(1));
      currentUser = null;
      users.add(null);

      final result = await repository.clearForUser(alice.id);

      expect(result, isA<Ok<void>>());
      expect(await boxExists(alice.id), isFalse);
    });

    test('leaves the other users alone', () async {
      final repository = build();
      await repository.toggle(testItem(1));
      await switchUser(repository, bob);

      await repository.clearForUser(alice.id);

      await switchUser(repository, alice);
      expect(await favoriteIds(repository), isEmpty);
    });

    test('does not touch the favorites of the signed-in user', () async {
      final repository = build();
      await repository.toggle(testItem(1));

      await repository.clearForUser(bob.id);

      expect(await favoriteIds(repository), [1]);
    });

    test('a user without a box is fine', () async {
      final result = await build().clearForUser('nobody');

      expect(result, isA<Ok<void>>());
    });
  });

  group('storage failures', () {
    late _MockLocalDataSource dataSource;

    setUpAll(() {
      registerFallbackValue(
        FavoriteRecord(
          item: testItem(0).toFavoriteDto(),
          addedAt: DateTime(2026),
        ),
      );
    });

    setUp(() {
      dataSource = _MockLocalDataSource();
      when(() => dataSource.closeBox(any())).thenAnswer((_) async {});
    });

    test(
      'FAV-9: a box that cannot open gives an empty list and is logged',
      () async {
        when(() => dataSource.readAll(alice.id)).thenThrow(Exception('locked'));

        final items = await build(dataSource).watchAll().first;

        expect(items, isEmpty);
        expect(talker.history, isNotEmpty);
      },
    );

    test('FAV-9: toggle returns a cache failure', () async {
      when(() => dataSource.readAll(alice.id)).thenAnswer((_) async => []);
      when(() => dataSource.write(alice.id, any()))
          .thenThrow(Exception('disk full'));
      final repository = build(dataSource);

      final result = await repository.toggle(testItem(1));

      expect(
        result,
        isA<Err<bool>>().having(
          (e) => e.failure,
          'failure',
          isA<CacheFailure>(),
        ),
      );
      expect(await repository.watchAll().first, isEmpty);
    });

    test(
      'FAV-9: toggle reads the box again after a failed first read',
      () async {
        var attempts = 0;
        when(() => dataSource.readAll(alice.id)).thenAnswer((_) async {
          if (attempts++ == 0) throw Exception('locked');
          return [];
        });
        when(() => dataSource.write(alice.id, any())).thenAnswer((_) async {});
        final repository = build(dataSource);
        await repository.watchAll().first;

        final result = await repository.toggle(testItem(1));

        expect(result, isA<Ok<bool>>());
        expect(attempts, 2);
      },
    );

    test('clearForUser returns a cache failure and logs it', () async {
      when(() => dataSource.readAll(alice.id)).thenAnswer((_) async => []);
      when(() => dataSource.deleteBox(alice.id)).thenThrow(Exception('busy'));

      final result = await build(dataSource).clearForUser(alice.id);

      expect(
        result,
        isA<Err<void>>().having(
          (e) => e.failure,
          'failure',
          isA<CacheFailure>(),
        ),
      );
      expect(talker.history, isNotEmpty);
    });
  });
}
