import 'package:dio/dio.dart';
import 'package:flutter_starter/data/character/character_repository_impl.dart';
import 'package:flutter_starter/data/character/data_source/character_api_data_source.dart';
import 'package:flutter_starter/data/character/data_source/character_hive_data_source.dart';
import 'package:flutter_starter/data/character/model/cached_record_dto.dart';
import 'package:flutter_starter/data/character/model/character_page_dto.dart';
import 'package:flutter_starter/domain/_shared/wrapper/pagination/paginated.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

import '../../helper/character_fixture.dart';

class _MockApi extends Mock implements CharacterApiDataSource {}

class _MockLocalDataSource extends Mock implements CharacterHiveDataSource {}

void main() {
  late _MockApi api;
  late _MockLocalDataSource local;
  late CharacterRepositoryImpl repository;

  const ttl = Duration(minutes: 30);
  final networkPage = testPageDto(ids: [1]);
  final cachedPage = testPageDto(ids: [2]);
  final requestOptions = RequestOptions(path: '/character');

  DateTime fresh() => DateTime.now().subtract(const Duration(minutes: 29));
  DateTime expired() => DateTime.now().subtract(const Duration(minutes: 31));

  DioException httpError(int statusCode) => DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.badResponse,
    response: Response<void>(
      requestOptions: requestOptions,
      statusCode: statusCode,
    ),
  );

  final connectionError = DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.connectionError,
  );

  void stubCachedPage(CharacterPageDto? dto, {DateTime? fetchedAt}) {
    when(() => local.readPage(page: 1, query: 'rick')).thenAnswer(
      (_) async => dto == null
          ? null
          : CachedRecordDto(
              schemaVersion: CharacterHiveDataSource.schemaVersion,
              fetchedAt: fetchedAt ?? fresh(),
              data: dto,
            ),
    );
  }

  void stubCachedCharacter({required DateTime fetchedAt}) {
    when(() => local.readCharacter(2)).thenAnswer(
      (_) async => CachedRecordDto(
        schemaVersion: CharacterHiveDataSource.schemaVersion,
        fetchedAt: fetchedAt,
        data: testCharacterDto(2),
      ),
    );
  }

  Future<Result<Paginated<Character>>> getPage({bool forceRefresh = false}) =>
      repository.getPage(page: 1, query: 'rick', forceRefresh: forceRefresh);

  Paginated<Character> pageWith(int id) => testPage(1, ids: [id]);

  setUpAll(() {
    registerFallbackValue(networkPage);
    registerFallbackValue(testCharacterDto(1));
  });

  setUp(() {
    api = _MockApi();
    local = _MockLocalDataSource();
    repository = CharacterRepositoryImpl(
      api,
      local,
      ttl,
      Talker(settings: TalkerSettings(useConsoleLogs: false)),
    );
    when(
      () => local.writePage(
        page: any(named: 'page'),
        query: any(named: 'query'),
        dto: any(named: 'dto'),
      ),
    ).thenAnswer((_) async {});
    when(() => local.writeCharacter(any())).thenAnswer((_) async {});
    when(() => local.readCharacter(any())).thenAnswer((_) async => null);
    when(() => api.getCharacters(1, 'rick'))
        .thenAnswer((_) async => networkPage);
  });

  group('getPage', () {
    test('CHR-10: a fresh cache hit does not use the network', () async {
      stubCachedPage(cachedPage);

      final result = await getPage();

      expect((result as Ok<Paginated<Character>>).value, pageWith(2));
      verifyNever(() => api.getCharacters(any(), any()));
    });

    test('a cache miss fetches and stores the page', () async {
      stubCachedPage(null);

      final result = await getPage();

      expect((result as Ok<Paginated<Character>>).value, pageWith(1));
      verify(() => local.writePage(page: 1, query: 'rick', dto: networkPage))
          .called(1);
    });

    test('CHR-10: an expired cache fetches again', () async {
      stubCachedPage(cachedPage, fetchedAt: expired());

      final result = await getPage();

      expect((result as Ok<Paginated<Character>>).value, pageWith(1));
    });

    test('CHR-4: forceRefresh skips a fresh cache', () async {
      stubCachedPage(cachedPage);

      final result = await getPage(forceRefresh: true);

      expect((result as Ok<Paginated<Character>>).value, pageWith(1));
    });

    test('CHR-11: a network failure returns the stale cache', () async {
      stubCachedPage(cachedPage, fetchedAt: expired());
      when(() => api.getCharacters(1, 'rick')).thenThrow(connectionError);

      final result = await getPage();

      expect((result as Ok<Paginated<Character>>).value, pageWith(2));
    });

    test(
      'CHR-4, CHR-11: a refresh without a connection returns the cache',
      () async {
        stubCachedPage(cachedPage);
        when(() => api.getCharacters(1, 'rick')).thenThrow(connectionError);

        final result = await getPage(forceRefresh: true);

        expect((result as Ok<Paginated<Character>>).value, pageWith(2));
      },
    );

    test('CHR-11: a server failure returns the stale cache', () async {
      stubCachedPage(cachedPage, fetchedAt: expired());
      when(() => api.getCharacters(1, 'rick')).thenThrow(httpError(500));

      final result = await getPage();

      expect((result as Ok<Paginated<Character>>).value, pageWith(2));
    });

    test('CHR-11: a network failure without cache is a failure', () async {
      stubCachedPage(null);
      when(() => api.getCharacters(1, 'rick')).thenThrow(connectionError);

      final result = await getPage();

      expect((result as Err).failure, const Failure.network());
    });

    test('CHR-11: an unexpected failure ignores the stale cache', () async {
      stubCachedPage(cachedPage, fetchedAt: expired());
      when(() => api.getCharacters(1, 'rick'))
          .thenThrow(const FormatException());

      final result = await getPage();

      expect((result as Err).failure, const Failure.unexpected());
    });

    test('CHR-6: a 404 is an empty last page and is not cached', () async {
      stubCachedPage(null);
      when(() => api.getCharacters(1, 'rick')).thenThrow(httpError(404));

      final result = await getPage();

      expect(
        (result as Ok<Paginated<Character>>).value,
        testPage(1, ids: [], hasMore: false),
      );
      verifyNever(
        () => local.writePage(
          page: any(named: 'page'),
          query: any(named: 'query'),
          dto: any(named: 'dto'),
        ),
      );
    });
  });

  group('getById', () {
    test('CHR-10: a fresh cache hit does not use the network', () async {
      stubCachedCharacter(fetchedAt: fresh());

      final result = await repository.getById(2);

      expect((result as Ok<Character>).value, testCharacter(2));
      verifyNever(() => api.getCharacter(any()));
    });

    test('CHR-10: an expired cache fetches and stores the character', () async {
      stubCachedCharacter(fetchedAt: expired());
      when(() => api.getCharacter(2))
          .thenAnswer((_) async => testCharacterDto(2));

      final result = await repository.getById(2);

      expect((result as Ok<Character>).value, testCharacter(2));
      verify(() => api.getCharacter(2)).called(1);
      verify(() => local.writeCharacter(testCharacterDto(2))).called(1);
    });

    test('CHR-11: a network failure returns the stale cache', () async {
      stubCachedCharacter(fetchedAt: expired());
      when(() => api.getCharacter(2)).thenThrow(connectionError);

      final result = await repository.getById(2);

      expect((result as Ok<Character>).value, testCharacter(2));
    });

    test('CHR-16: a 404 is a failure, even with a stale cache', () async {
      stubCachedCharacter(fetchedAt: expired());
      when(() => api.getCharacter(2)).thenThrow(httpError(404));

      final result = await repository.getById(2);

      expect((result as Err).failure, const Failure.notFound());
    });
  });
}
