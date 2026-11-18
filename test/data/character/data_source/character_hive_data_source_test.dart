import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_starter/data/character/data_source/character_hive_data_source.dart';
import 'package:flutter_starter/shared/utils/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

import '../../../helper/character_fixture.dart';

class _MockHive extends Mock implements HiveInterface {}

class _MockBox extends Mock implements LazyBox<String> {}

void main() {
  final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
  final now = DateTime.utc(2026, 11, 17, 12);
  final clock = Clock.from(() => now);

  group('with a real box', () {
    late Directory directory;
    late CharacterHiveDataSource dataSource;

    Future<void> putRaw(String key, String value) async {
      final box = await Hive.openLazyBox<String>(
        CharacterHiveDataSource.boxName,
      );
      await box.put(key, value);
    }

    setUp(() {
      directory = Directory.systemTemp.createTempSync('character_cache_test');
      Hive.init(directory.path);
      dataSource = CharacterHiveDataSource(Hive, clock, talker);
    });

    tearDown(() async {
      await Hive.close();
      directory.deleteSync(recursive: true);
    });

    test('a written page is read back with its fetch time', () async {
      await dataSource.writePage(page: 2, query: 'rick', dto: testPageDto());

      final record = await dataSource.readPage(page: 2, query: 'rick');

      expect(record!.data, testPageDto());
      expect(record.fetchedAt, now);
    });

    test('CHR-10: a written record stores fetchedAt in UTC', () async {
      await dataSource.writeCharacter(testCharacterDto(1));

      final box = await Hive.openLazyBox<String>(
        CharacterHiveDataSource.boxName,
      );
      final stored =
          jsonDecode((await box.get('character:1'))!) as Map<String, dynamic>;
      final record = await dataSource.readCharacter(1);

      expect(stored['fetchedAt'], '2026-11-17T12:00:00.000Z');
      expect(record!.fetchedAt.isUtc, isTrue);
    });

    test('pages are stored per page and query', () async {
      await dataSource.writePage(page: 1, query: 'rick', dto: testPageDto());

      expect(await dataSource.readPage(page: 2, query: 'rick'), isNull);
      expect(await dataSource.readPage(page: 1), isNull);
    });

    test('CHR-12: writing a page also stores each of its characters', () async {
      await dataSource.writePage(page: 1, dto: testPageDto(ids: [3, 4]));

      expect((await dataSource.readCharacter(3))!.data, testCharacterDto(3));
      expect((await dataSource.readCharacter(4))!.data, testCharacterDto(4));
    });

    test('a written character is read back', () async {
      await dataSource.writeCharacter(testCharacterDto(5));

      expect((await dataSource.readCharacter(5))!.data, testCharacterDto(5));
    });

    test('a record stored before CachedRecordDto is still read', () async {
      // The envelope as the data source wrote it by hand before it became a
      // DTO: the keys and the date format must not change.
      await putRaw(
        'character:5',
        '{"schemaVersion":1,"fetchedAt":"2026-11-01T10:00:00.000",'
            '"data":${jsonEncode(testCharacterDto(5).toJson())}}',
      );

      final record = await dataSource.readCharacter(5);

      expect(record!.data, testCharacterDto(5));
      expect(record.fetchedAt, DateTime(2026, 11, 1, 10));
    });

    test('values use the documented keys and envelope', () async {
      await dataSource.writeCharacter(testCharacterDto(5));

      final box = await Hive.openLazyBox<String>(
        CharacterHiveDataSource.boxName,
      );
      final envelope = jsonDecode((await box.get('character:5'))!) as Map;
      expect(envelope['schemaVersion'], 1);
      expect(envelope['data'], jsonDecode(jsonEncode(testCharacterDto(5))));
      expect(DateTime.tryParse(envelope['fetchedAt'] as String), isNotNull);
      expect(
        CharacterHiveDataSource.pageKey(page: 2, query: 'rick'),
        'list:page=2:q=rick',
      );
      expect(CharacterHiveDataSource.pageKey(page: 2), 'list:page=2:q=');
    });

    test('a record with another schema version is missing', () async {
      await putRaw(
        'character:1',
        jsonEncode({
          'schemaVersion': 0,
          'fetchedAt': now.toIso8601String(),
          'data': testCharacterDto(1).toJson(),
        }),
      );

      expect(await dataSource.readCharacter(1), isNull);
    });

    test('a corrupt record is missing', () async {
      await putRaw('character:1', 'not json');
      await putRaw(
        'character:2',
        jsonEncode({
          'schemaVersion': 1,
          'fetchedAt': now.toIso8601String(),
          'data': {'id': 'wrong'},
        }),
      );

      expect(await dataSource.readCharacter(1), isNull);
      expect(await dataSource.readCharacter(2), isNull);
    });

    group('evictExpired', () {
      String envelope({
        int ageInDays = 0,
        Duration? age,
        int schemaVersion = 1,
      }) => jsonEncode({
        'schemaVersion': schemaVersion,
        'fetchedAt': now
            .subtract(age ?? Duration(days: ageInDays))
            .toIso8601String(),
        'data': testCharacterDto(1).toJson(),
      });

      Future<Iterable<dynamic>> cachedKeys() async =>
          (await Hive.openLazyBox<String>(CharacterHiveDataSource.boxName))
              .keys;

      test(
        'CHR-13: deletes records older than maxAge and keeps newer ones',
        () async {
          expect(CharacterHiveDataSource.maxAge, const Duration(days: 90));
          await putRaw('character:1', envelope(ageInDays: 91));
          await putRaw('character:2', envelope(ageInDays: 89));

          await dataSource.evictExpired();

          expect(await cachedKeys(), ['character:2']);
        },
      );

      test('CHR-13: eviction deletes a record exactly maxAge old and keeps one '
          'a second younger', () async {
        const maxAge = CharacterHiveDataSource.maxAge;
        await putRaw('character:1', envelope(age: maxAge));
        await putRaw(
          'character:2',
          envelope(age: maxAge - const Duration(seconds: 1)),
        );

        await dataSource.evictExpired();

        expect(await cachedKeys(), ['character:2']);
      });

      test('deletes records with another schema or unreadable', () async {
        await putRaw('character:1', envelope(ageInDays: 0, schemaVersion: 0));
        await putRaw('character:2', 'not json');
        await putRaw('character:3', envelope(ageInDays: 0));

        await dataSource.evictExpired();

        expect(await cachedKeys(), ['character:3']);
      });

      test('an empty cache stays empty', () async {
        await dataSource.evictExpired();

        expect(await cachedKeys(), isEmpty);
      });

      test('never touches user data in other boxes', () async {
        final favorites = await Hive.openLazyBox<String>('favorite_6162');
        await favorites.put('1', envelope(ageInDays: 200));
        await putRaw('character:1', envelope(ageInDays: 200));

        await dataSource.evictExpired();

        expect(await cachedKeys(), isEmpty);
        expect(favorites.keys, ['1']);
        expect(await favorites.get('1'), isNotNull);
      });
    });
  });

  group('opening the box', () {
    late _MockHive hive;
    late _MockBox box;
    late CharacterHiveDataSource dataSource;

    setUp(() {
      hive = _MockHive();
      box = _MockBox();
      dataSource = CharacterHiveDataSource(hive, clock, talker);
      when(() => box.get(any<dynamic>())).thenAnswer((_) async => null);
    });

    test('parallel first calls open it once', () async {
      final opening = Completer<LazyBox<String>>();
      when(() => hive.openLazyBox<String>(CharacterHiveDataSource.boxName))
          .thenAnswer((_) => opening.future);

      final reads = Future.wait([
        dataSource.readCharacter(1),
        dataSource.readCharacter(2),
        dataSource.readPage(page: 1),
      ]);
      opening.complete(box);
      await reads;

      verify(() => hive.openLazyBox<String>(CharacterHiveDataSource.boxName))
          .called(1);
    });

    test('a failed open is not surfaced and is retried', () async {
      when(() => hive.openLazyBox<String>(CharacterHiveDataSource.boxName))
          .thenThrow(const FileSystemException());

      expect(await dataSource.readCharacter(1), isNull);
      await dataSource.writeCharacter(testCharacterDto(1));

      verify(() => hive.openLazyBox<String>(CharacterHiveDataSource.boxName))
          .called(2);
    });

    test('a failed open during eviction is not surfaced', () async {
      when(() => hive.openLazyBox<String>(CharacterHiveDataSource.boxName))
          .thenThrow(const FileSystemException());

      await expectLater(dataSource.evictExpired(), completes);
    });
  });
}
