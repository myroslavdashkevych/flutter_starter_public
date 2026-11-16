import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_starter/data/favorite/data_source/favorite_hive_data_source.dart';
import 'package:flutter_starter/data/favorite/favorite_repository_impl.dart';
import 'package:flutter_starter/data/favorite/mapper/favorite_character_mapper.dart';
import 'package:flutter_starter/data/favorite/model/favorite_record_dto.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

import '../../helper/character_fixture.dart';

class _MockLocalDataSource extends Mock implements FavoriteHiveDataSource {}

FavoriteRecordDto record(Character character) => FavoriteRecordDto(
  schemaVersion: FavoriteHiveDataSource.schemaVersion,
  addedAt: DateTime(2026),
  character: character.toFavoriteDto(),
);

void main() {
  const alice = 'Alice-1';
  const bob = 'bob-2';

  late Directory directory;
  late Talker talker;

  FavoriteRepositoryImpl build([FavoriteHiveDataSource? dataSource]) =>
      FavoriteRepositoryImpl(
        dataSource ?? FavoriteHiveDataSource(Hive, talker),
        talker,
      );

  Future<List<int>> favoriteIds(
    FavoriteRepositoryImpl repository, [
    String uid = alice,
  ]) async {
    final characters = await repository.watchAll(uid).first;
    return characters.map((character) => character.id).toList();
  }

  // Waits until the queued storage operations have run.
  Future<void> settle(FavoriteRepositoryImpl repository) async {
    await Future<void>.delayed(Duration.zero);
    await repository.clearForUser('flush');
  }

  bool isOpen(String uid) =>
      Hive.isBoxOpen(FavoriteHiveDataSource.boxName(uid));

  Future<LazyBox<String>> openBox(String uid) =>
      Hive.openLazyBox<String>(FavoriteHiveDataSource.boxName(uid));

  String envelope(Object? schemaVersion, Character character) => jsonEncode({
    'schemaVersion': schemaVersion,
    'addedAt': '2026-01-01T00:00:00.000',
    'data': {
      'id': character.id,
      'name': character.name,
      'imageUrl': character.imageUrl,
      'status': character.status.name,
      'species': character.species,
      'gender': character.gender,
      'originName': character.originName,
      'locationName': character.locationName,
      'episodeCount': character.episodeCount,
    },
  });

  setUp(() {
    directory = Directory.systemTemp.createTempSync('favorite_test');
    Hive.init(directory.path);
    talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
  });

  tearDown(() async {
    await Hive.close();
    directory.deleteSync(recursive: true);
  });

  group('toggle', () {
    test('FAV-1: adds the character, then removes it', () async {
      final repository = build();

      expect(
        await repository.toggle(alice, testCharacter(1)),
        isA<Ok<bool>>().having((ok) => ok.value, 'value', isTrue),
      );
      expect(await repository.watchAll(alice).first, [testCharacter(1)]);

      expect(
        await repository.toggle(alice, testCharacter(1)),
        isA<Ok<bool>>().having((ok) => ok.value, 'value', isFalse),
      );
      expect(await repository.watchAll(alice).first, isEmpty);
    });

    test('FAV-3: notifies the streams', () async {
      final repository = build();
      final isFavorite = <bool>[];
      final all = <List<Character>>[];
      final markSubscription = repository
          .watchIsFavorite(alice, 1)
          .listen(isFavorite.add);
      final allSubscription = repository.watchAll(alice).listen(all.add);
      addTearDown(markSubscription.cancel);
      addTearDown(allSubscription.cancel);

      await settle(repository);
      await repository.toggle(alice, testCharacter(2));
      await repository.toggle(alice, testCharacter(1));
      await repository.toggle(alice, testCharacter(1));
      await Future<void>.delayed(Duration.zero);

      expect(isFavorite, [false, true, false]);
      expect(all.last, [testCharacter(2)]);
    });
  });

  group('storage', () {
    test('FAV-5, FAV-7: survives a restart, newest first', () async {
      final repository = build();
      await repository.toggle(alice, testCharacter(1));
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repository.toggle(alice, testCharacter(2));
      expect(await favoriteIds(repository), [2, 1]);
      await Hive.close();

      expect(await favoriteIds(build()), [2, 1]);
    });

    test('keeps every field of the character', () async {
      final character = testCharacter(1).copyWith(status: CharacterStatus.dead);
      await build().toggle(alice, character);
      await Hive.close();

      expect(await build().watchAll(alice).first, [character]);
    });

    test('an unknown status reads as unknown', () async {
      final box = await openBox(alice);
      final raw =
          jsonDecode(envelope(1, testCharacter(1))) as Map<String, dynamic>;
      (raw['data'] as Map<String, dynamic>)['status'] = 'zombie';
      await box.put('1', jsonEncode(raw));

      final characters = await build().watchAll(alice).first;

      expect(characters.single.status, CharacterStatus.unknown);
    });

    test('a record stored before FavoriteRecordDto is still read', () async {
      // The envelope as the data source wrote it by hand before it became a
      // DTO: user data must stay readable without a migration.
      final box = await openBox(alice);
      await box.put('1', envelope(1, testCharacter(1)));

      expect(await build().watchAll(alice).first, [testCharacter(1)]);
    });

    test('writes the envelope with the schema version', () async {
      await build().toggle(alice, testCharacter(1));

      final box = await openBox(alice);
      final stored = jsonDecode((await box.get('1'))!) as Map<String, dynamic>;

      expect(stored['schemaVersion'], 1);
      expect(DateTime.tryParse(stored['addedAt'] as String), isNotNull);
      expect((stored['data'] as Map<String, dynamic>)['name'], 'Character 1');
    });

    test('FAV-8: a record with another schema is skipped and kept', () async {
      final box = await openBox(alice);
      await box.put('1', envelope(99, testCharacter(1)));
      await box.put('2', envelope(1, testCharacter(2)));

      expect(await favoriteIds(build()), [2]);
      expect(
        await (await openBox(alice)).get('1'),
        envelope(99, testCharacter(1)),
      );
    });

    test('FAV-8: a corrupt record is skipped, kept and logged', () async {
      final box = await openBox(alice);
      await box.put('1', 'not json');
      await box.put('2', envelope(1, testCharacter(2)));

      expect(await favoriteIds(build()), [2]);
      expect(await (await openBox(alice)).get('1'), 'not json');
      expect(talker.history, isNotEmpty);
    });

    test('FAV-8: toggling a skipped record overwrites it', () async {
      final box = await openBox(alice);
      await box.put('1', 'not json');
      final repository = build();

      final result = await repository.toggle(alice, testCharacter(1));

      expect(result, isA<Ok<bool>>().having((ok) => ok.value, 'value', isTrue));
      expect(await favoriteIds(repository), [1]);
    });
  });

  group('users', () {
    test('FAV-16: every user has a separate box', () async {
      final repository = build();
      await repository.toggle(alice, testCharacter(1));
      await repository.toggle(bob, testCharacter(2));

      expect(await favoriteIds(repository, alice), [1]);
      expect(await favoriteIds(repository, bob), [2]);
    });

    test('FAV-16: two users watched at once never see each other', () async {
      final repository = build();
      final aliceCharacters = <List<Character>>[];
      final bobCharacters = <List<Character>>[];
      final aliceSubscription = repository
          .watchAll(alice)
          .listen(aliceCharacters.add);
      final bobSubscription = repository
          .watchAll(bob)
          .listen(bobCharacters.add);
      addTearDown(aliceSubscription.cancel);
      addTearDown(bobSubscription.cancel);
      await settle(repository);

      await repository.toggle(alice, testCharacter(1));
      await Future<void>.delayed(Duration.zero);

      expect(aliceCharacters.last, [testCharacter(1)]);
      expect(bobCharacters, [isEmpty]);
    });

    test(
      "FAV-16: a user's favorites come back after the box was closed",
      () async {
        final repository = build();
        await repository.toggle(alice, testCharacter(1));
        await settle(repository);
        expect(isOpen(alice), isFalse);

        expect(await favoriteIds(repository), [1]);
      },
    );

    test('the box name is the user id in hex', () {
      expect(FavoriteHiveDataSource.boxName('aB'), 'favorite_6142');
      expect(
        FavoriteHiveDataSource.boxName('ab'),
        isNot(FavoriteHiveDataSource.boxName('AB')),
      );
    });

    test('a box stays open while the user has a listener', () async {
      final repository = build();
      final subscription = repository.watchAll(alice).listen((_) {});
      await settle(repository);
      expect(isOpen(alice), isTrue);

      await subscription.cancel();
      await settle(repository);

      expect(isOpen(alice), isFalse);
    });

    test('a toggle without listeners closes the box after it', () async {
      final repository = build();

      await repository.toggle(alice, testCharacter(1));
      await settle(repository);

      expect(isOpen(alice), isFalse);
    });

    test('two listeners of one user share one read', () async {
      final dataSource = _MockLocalDataSource();
      when(() => dataSource.readAll(alice)).thenAnswer((_) async => []);
      when(() => dataSource.closeBox(any())).thenAnswer((_) async {});
      when(() => dataSource.deleteBox(any())).thenAnswer((_) async {});
      final repository = build(dataSource);
      final first = repository.watchAll(alice).listen((_) {});
      final second = repository.watchIsFavorite(alice, 1).listen((_) {});
      addTearDown(first.cancel);
      addTearDown(second.cancel);

      await settle(repository);

      verify(() => dataSource.readAll(alice)).called(1);
    });
  });

  group('clearForUser', () {
    Future<bool> boxExists(String uid) =>
        Hive.boxExists(FavoriteHiveDataSource.boxName(uid));

    test('PRF-6: deletes the box of the user', () async {
      final repository = build();
      await repository.toggle(alice, testCharacter(1));

      final result = await repository.clearForUser(alice);

      expect(result, isA<Ok<void>>());
      expect(await boxExists(alice), isFalse);
      expect(await favoriteIds(repository), isEmpty);
    });

    test('empties the list of a user who is watched', () async {
      final repository = build();
      await repository.toggle(alice, testCharacter(1));
      final emitted = <List<Character>>[];
      final subscription = repository.watchAll(alice).listen(emitted.add);
      addTearDown(subscription.cancel);
      await settle(repository);

      await repository.clearForUser(alice);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [
        [testCharacter(1)],
        isEmpty,
      ]);
    });

    test('a watched user can add favorites again after it', () async {
      final repository = build();
      await repository.toggle(alice, testCharacter(1));
      final emitted = <List<Character>>[];
      final subscription = repository.watchAll(alice).listen(emitted.add);
      addTearDown(subscription.cancel);
      await settle(repository);

      await repository.clearForUser(alice);
      await repository.toggle(alice, testCharacter(2));
      await Future<void>.delayed(Duration.zero);

      expect(emitted.last, [testCharacter(2)]);
      await subscription.cancel();
      await settle(repository);
      expect(await favoriteIds(repository), [2]);
    });

    test('leaves the other users alone', () async {
      final repository = build();
      await repository.toggle(alice, testCharacter(1));
      await repository.toggle(bob, testCharacter(2));

      await repository.clearForUser(alice);

      expect(await favoriteIds(repository, alice), isEmpty);
      expect(await favoriteIds(repository, bob), [2]);
    });

    test('a user without a box is fine', () async {
      final result = await build().clearForUser('nobody');

      expect(result, isA<Ok<void>>());
    });
  });

  group('storage failures', () {
    late _MockLocalDataSource dataSource;

    setUpAll(() {
      registerFallbackValue(record(testCharacter(0)));
    });

    setUp(() {
      dataSource = _MockLocalDataSource();
      when(() => dataSource.closeBox(any())).thenAnswer((_) async {});
    });

    test(
      'FAV-9: a box that cannot open gives an empty list and is logged',
      () async {
        when(() => dataSource.readAll(alice)).thenThrow(Exception('locked'));

        final characters = await build(dataSource).watchAll(alice).first;

        expect(characters, isEmpty);
        expect(talker.history, isNotEmpty);
      },
    );

    test('FAV-9: toggle returns a cache failure', () async {
      when(() => dataSource.readAll(alice)).thenAnswer((_) async => []);
      when(() => dataSource.write(alice, any()))
          .thenThrow(Exception('disk full'));
      final repository = build(dataSource);

      final result = await repository.toggle(alice, testCharacter(1));

      expect(
        result,
        isA<Err<bool>>().having(
          (e) => e.failure,
          'failure',
          isA<CacheFailure>(),
        ),
      );
      expect(await repository.watchAll(alice).first, isEmpty);
    });

    test(
      'FAV-9: toggle reads the box again after a failed first read',
      () async {
        var attempts = 0;
        when(() => dataSource.readAll(alice)).thenAnswer((_) async {
          if (attempts++ == 0) throw Exception('locked');
          return [];
        });
        when(() => dataSource.write(alice, any())).thenAnswer((_) async {});
        final repository = build(dataSource);
        final subscription = repository.watchAll(alice).listen((_) {});
        addTearDown(subscription.cancel);
        await Future<void>.delayed(Duration.zero);

        final result = await repository.toggle(alice, testCharacter(1));

        expect(result, isA<Ok<bool>>());
        expect(attempts, 2);
      },
    );

    test('FAV-9: a failed toggle read returns a cache failure', () async {
      when(() => dataSource.readAll(alice)).thenThrow(Exception('locked'));

      final result = await build(dataSource).toggle(alice, testCharacter(1));

      expect(
        result,
        isA<Err<bool>>().having(
          (e) => e.failure,
          'failure',
          isA<CacheFailure>(),
        ),
      );
    });

    test('FAV-9: a new listener reads again after a failed read', () async {
      var attempts = 0;
      when(() => dataSource.readAll(alice)).thenAnswer((_) async {
        if (attempts++ == 0) throw Exception('locked');
        return [record(testCharacter(1))];
      });
      final repository = build(dataSource);
      final first = repository.watchAll(alice).listen((_) {});
      addTearDown(first.cancel);
      await Future<void>.delayed(Duration.zero);

      final characters = await repository.watchAll(alice).first;

      expect(characters, [testCharacter(1)]);
      expect(attempts, 2);
    });

    test(
      'a listener that comes back before the release keeps the state',
      () async {
        when(() => dataSource.readAll(alice))
            .thenAnswer((_) async => [record(testCharacter(1))]);
        final repository = build(dataSource);
        final first = repository.watchAll(alice).listen((_) {});
        await Future<void>.delayed(Duration.zero);

        await first.cancel();
        final emitted = <List<Character>>[];
        final second = repository.watchAll(alice).listen(emitted.add);
        addTearDown(second.cancel);
        await Future<void>.delayed(Duration.zero);

        expect(emitted, [
          [testCharacter(1)],
        ]);
        verify(() => dataSource.readAll(alice)).called(1);
        verifyNever(() => dataSource.closeBox(alice));
      },
    );

    test(
      'a toggle that runs while the last listener leaves closes the box after '
      'it',
      () async {
        final write = Completer<void>();
        when(() => dataSource.readAll(alice)).thenAnswer((_) async => []);
        when(() => dataSource.write(alice, any()))
            .thenAnswer((_) => write.future);
        final repository = build(dataSource);
        final subscription = repository.watchAll(alice).listen((_) {});
        await Future<void>.delayed(Duration.zero);

        final toggle = repository.toggle(alice, testCharacter(1));
        await Future<void>.delayed(Duration.zero);
        await subscription.cancel();
        await Future<void>.delayed(Duration.zero);
        verifyNever(() => dataSource.closeBox(alice));

        write.complete();
        expect(await toggle, isA<Ok<bool>>());
        await Future<void>.delayed(Duration.zero);
        verify(() => dataSource.closeBox(alice)).called(1);
      },
    );

    test('a box that cannot close is logged, not thrown', () async {
      when(() => dataSource.readAll(alice)).thenAnswer((_) async => []);
      when(() => dataSource.closeBox(alice)).thenThrow(Exception('busy'));
      when(() => dataSource.deleteBox('other')).thenAnswer((_) async {});
      final repository = build(dataSource);

      await repository.watchAll(alice).first;
      await Future<void>.delayed(Duration.zero);
      final result = await repository.clearForUser('other');

      expect(result, isA<Ok<void>>());
      expect(talker.history, isNotEmpty);
    });

    test('clearForUser returns a cache failure and logs it', () async {
      when(() => dataSource.deleteBox(alice)).thenThrow(Exception('busy'));

      final result = await build(dataSource).clearForUser(alice);

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
