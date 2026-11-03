import 'package:dio/dio.dart';
import 'package:flutter_starter/data/items/datasources/items_api.dart';
import 'package:flutter_starter/data/items/datasources/items_local_data_source.dart';
import 'package:flutter_starter/data/items/models/characters_page_dto.dart';
import 'package:flutter_starter/data/items/repositories/items_repository_impl.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/paginated.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

import '../../../helpers/items_fixtures.dart';

class _MockApi extends Mock implements ItemsApi {}

class _MockLocalDataSource extends Mock implements ItemsLocalDataSource {}

void main() {
  late _MockApi api;
  late _MockLocalDataSource local;
  late ItemsRepositoryImpl repository;

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

  void stubCachedPage(CharactersPageDto? dto, {DateTime? fetchedAt}) {
    when(() => local.readPage(page: 1, query: 'rick')).thenAnswer(
      (_) async => dto == null
          ? null
          : CachedRecord(data: dto, fetchedAt: fetchedAt ?? fresh()),
    );
  }

  void stubCachedItem({required DateTime fetchedAt}) {
    when(() => local.readItem(2)).thenAnswer(
      (_) async =>
          CachedRecord(data: testCharacterDto(2), fetchedAt: fetchedAt),
    );
  }

  Future<Result<Paginated<Item>>> getPage({bool forceRefresh = false}) =>
      repository.getPage(page: 1, query: 'rick', forceRefresh: forceRefresh);

  Paginated<Item> pageWith(int id) => testPage(1, ids: [id]);

  setUpAll(() {
    registerFallbackValue(networkPage);
    registerFallbackValue(testCharacterDto(1));
  });

  setUp(() {
    api = _MockApi();
    local = _MockLocalDataSource();
    repository = ItemsRepositoryImpl(
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
    when(() => local.writeItem(any())).thenAnswer((_) async {});
    when(() => local.readItem(any())).thenAnswer((_) async => null);
    when(() => api.getCharacters(1, 'rick'))
        .thenAnswer((_) async => networkPage);
  });

  group('getPage', () {
    test('a fresh cache hit does not use the network', () async {
      stubCachedPage(cachedPage);

      final result = await getPage();

      expect((result as Ok<Paginated<Item>>).value, pageWith(2));
      verifyNever(() => api.getCharacters(any(), any()));
    });

    test('a cache miss fetches and stores the page', () async {
      stubCachedPage(null);

      final result = await getPage();

      expect((result as Ok<Paginated<Item>>).value, pageWith(1));
      verify(() => local.writePage(page: 1, query: 'rick', dto: networkPage))
          .called(1);
    });

    test('an expired cache fetches again', () async {
      stubCachedPage(cachedPage, fetchedAt: expired());

      final result = await getPage();

      expect((result as Ok<Paginated<Item>>).value, pageWith(1));
    });

    test('forceRefresh skips a fresh cache', () async {
      stubCachedPage(cachedPage);

      final result = await getPage(forceRefresh: true);

      expect((result as Ok<Paginated<Item>>).value, pageWith(1));
    });

    test('a network failure returns the stale cache', () async {
      stubCachedPage(cachedPage, fetchedAt: expired());
      when(() => api.getCharacters(1, 'rick')).thenThrow(connectionError);

      final result = await getPage();

      expect((result as Ok<Paginated<Item>>).value, pageWith(2));
    });

    test('a server failure returns the stale cache', () async {
      stubCachedPage(cachedPage, fetchedAt: expired());
      when(() => api.getCharacters(1, 'rick')).thenThrow(httpError(500));

      final result = await getPage();

      expect((result as Ok<Paginated<Item>>).value, pageWith(2));
    });

    test('a network failure without cache is a failure', () async {
      stubCachedPage(null);
      when(() => api.getCharacters(1, 'rick')).thenThrow(connectionError);

      final result = await getPage();

      expect((result as Err).failure, const Failure.network());
    });

    test('an unexpected failure ignores the stale cache', () async {
      stubCachedPage(cachedPage, fetchedAt: expired());
      when(() => api.getCharacters(1, 'rick'))
          .thenThrow(const FormatException());

      final result = await getPage();

      expect((result as Err).failure, const Failure.unexpected());
    });

    test('a 404 is an empty last page and is not cached', () async {
      stubCachedPage(null);
      when(() => api.getCharacters(1, 'rick')).thenThrow(httpError(404));

      final result = await getPage();

      expect(
        (result as Ok<Paginated<Item>>).value,
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
    test('a fresh cache hit does not use the network', () async {
      stubCachedItem(fetchedAt: fresh());

      final result = await repository.getById(2);

      expect((result as Ok<Item>).value, testItem(2));
      verifyNever(() => api.getCharacter(any()));
    });

    test('an expired cache fetches and stores the item', () async {
      stubCachedItem(fetchedAt: expired());
      when(() => api.getCharacter(2))
          .thenAnswer((_) async => testCharacterDto(2));

      final result = await repository.getById(2);

      expect((result as Ok<Item>).value, testItem(2));
      verify(() => api.getCharacter(2)).called(1);
      verify(() => local.writeItem(testCharacterDto(2))).called(1);
    });

    test('a network failure returns the stale cache', () async {
      stubCachedItem(fetchedAt: expired());
      when(() => api.getCharacter(2)).thenThrow(connectionError);

      final result = await repository.getById(2);

      expect((result as Ok<Item>).value, testItem(2));
    });

    test('a 404 is a failure, even with a stale cache', () async {
      stubCachedItem(fetchedAt: expired());
      when(() => api.getCharacter(2)).thenThrow(httpError(404));

      final result = await repository.getById(2);

      expect((result as Err).failure, const Failure.notFound());
    });
  });
}
