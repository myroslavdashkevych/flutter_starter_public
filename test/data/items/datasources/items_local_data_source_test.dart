import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_starter/data/items/datasources/items_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

import '../../../helpers/items_fixtures.dart';

class _MockHive extends Mock implements HiveInterface {}

class _MockBox extends Mock implements LazyBox<String> {}

void main() {
  final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));

  group('with a real box', () {
    late Directory directory;
    late ItemsLocalDataSource dataSource;

    Future<void> putRaw(String key, String value) async {
      final box = await Hive.openLazyBox<String>(ItemsLocalDataSource.boxName);
      await box.put(key, value);
    }

    setUp(() {
      directory = Directory.systemTemp.createTempSync('items_cache_test');
      Hive.init(directory.path);
      dataSource = ItemsLocalDataSource(Hive, talker);
    });

    tearDown(() async {
      await Hive.close();
      directory.deleteSync(recursive: true);
    });

    test('a written page is read back with its fetch time', () async {
      final before = DateTime.now();
      await dataSource.writePage(page: 2, query: 'rick', dto: testPageDto());

      final record = await dataSource.readPage(page: 2, query: 'rick');

      expect(record!.data, testPageDto());
      expect(record.fetchedAt.isBefore(before), isFalse);
    });

    test('pages are stored per page and query', () async {
      await dataSource.writePage(page: 1, query: 'rick', dto: testPageDto());

      expect(await dataSource.readPage(page: 2, query: 'rick'), isNull);
      expect(await dataSource.readPage(page: 1), isNull);
    });

    test('writing a page also stores each of its items', () async {
      await dataSource.writePage(page: 1, dto: testPageDto(ids: [3, 4]));

      expect((await dataSource.readItem(3))!.data, testCharacterDto(3));
      expect((await dataSource.readItem(4))!.data, testCharacterDto(4));
    });

    test('a written item is read back', () async {
      await dataSource.writeItem(testCharacterDto(5));

      expect((await dataSource.readItem(5))!.data, testCharacterDto(5));
    });

    test('values use the documented keys and envelope', () async {
      await dataSource.writeItem(testCharacterDto(5));

      final box = await Hive.openLazyBox<String>(ItemsLocalDataSource.boxName);
      final envelope = jsonDecode((await box.get('item:5'))!) as Map;
      expect(envelope['schemaVersion'], 1);
      expect(envelope['data'], jsonDecode(jsonEncode(testCharacterDto(5))));
      expect(DateTime.tryParse(envelope['fetchedAt'] as String), isNotNull);
      expect(
        ItemsLocalDataSource.pageKey(page: 2, query: 'rick'),
        'list:page=2:q=rick',
      );
      expect(ItemsLocalDataSource.pageKey(page: 2), 'list:page=2:q=');
    });

    test('a record with another schema version is missing', () async {
      await putRaw(
        'item:1',
        jsonEncode({
          'schemaVersion': 0,
          'fetchedAt': DateTime.now().toIso8601String(),
          'data': testCharacterDto(1).toJson(),
        }),
      );

      expect(await dataSource.readItem(1), isNull);
    });

    test('a corrupt record is missing', () async {
      await putRaw('item:1', 'not json');
      await putRaw(
        'item:2',
        jsonEncode({
          'schemaVersion': 1,
          'fetchedAt': DateTime.now().toIso8601String(),
          'data': {'id': 'wrong'},
        }),
      );

      expect(await dataSource.readItem(1), isNull);
      expect(await dataSource.readItem(2), isNull);
    });

    group('evictExpired', () {
      String envelope({required int ageInDays, int schemaVersion = 1}) =>
          jsonEncode({
            'schemaVersion': schemaVersion,
            'fetchedAt': DateTime.now()
                .subtract(Duration(days: ageInDays))
                .toIso8601String(),
            'data': testCharacterDto(1).toJson(),
          });

      Future<Iterable<dynamic>> cachedKeys() async =>
          (await Hive.openLazyBox<String>(ItemsLocalDataSource.boxName)).keys;

      test('deletes records older than maxAge and keeps newer ones', () async {
        expect(ItemsLocalDataSource.maxAge, const Duration(days: 90));
        await putRaw('item:1', envelope(ageInDays: 91));
        await putRaw('item:2', envelope(ageInDays: 89));

        await dataSource.evictExpired();

        expect(await cachedKeys(), ['item:2']);
      });

      test('deletes records with another schema or unreadable', () async {
        await putRaw('item:1', envelope(ageInDays: 0, schemaVersion: 0));
        await putRaw('item:2', 'not json');
        await putRaw('item:3', envelope(ageInDays: 0));

        await dataSource.evictExpired();

        expect(await cachedKeys(), ['item:3']);
      });

      test('an empty cache stays empty', () async {
        await dataSource.evictExpired();

        expect(await cachedKeys(), isEmpty);
      });

      test('never touches user data in other boxes', () async {
        final favorites = await Hive.openLazyBox<String>('favorites_6162');
        await favorites.put('1', envelope(ageInDays: 200));
        await putRaw('item:1', envelope(ageInDays: 200));

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
    late ItemsLocalDataSource dataSource;

    setUp(() {
      hive = _MockHive();
      box = _MockBox();
      dataSource = ItemsLocalDataSource(hive, talker);
      when(() => box.get(any<dynamic>())).thenAnswer((_) async => null);
    });

    test('parallel first calls open it once', () async {
      final opening = Completer<LazyBox<String>>();
      when(() => hive.openLazyBox<String>(ItemsLocalDataSource.boxName))
          .thenAnswer((_) => opening.future);

      final reads = Future.wait([
        dataSource.readItem(1),
        dataSource.readItem(2),
        dataSource.readPage(page: 1),
      ]);
      opening.complete(box);
      await reads;

      verify(() => hive.openLazyBox<String>(ItemsLocalDataSource.boxName))
          .called(1);
    });

    test('a failed open is not surfaced and is retried', () async {
      when(() => hive.openLazyBox<String>(ItemsLocalDataSource.boxName))
          .thenThrow(const FileSystemException());

      expect(await dataSource.readItem(1), isNull);
      await dataSource.writeItem(testCharacterDto(1));

      verify(() => hive.openLazyBox<String>(ItemsLocalDataSource.boxName))
          .called(2);
    });

    test('a failed open during eviction is not surfaced', () async {
      when(() => hive.openLazyBox<String>(ItemsLocalDataSource.boxName))
          .thenThrow(const FileSystemException());

      await expectLater(dataSource.evictExpired(), completes);
    });
  });
}
