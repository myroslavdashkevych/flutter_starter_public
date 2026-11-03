import 'package:flutter_starter/data/_shared/network/safe_call.dart';
import 'package:flutter_starter/data/items/datasources/items_api.dart';
import 'package:flutter_starter/data/items/datasources/items_local_data_source.dart';
import 'package:flutter_starter/data/items/models/character_mapper.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/paginated.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/domain/items/repositories/items_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

const itemsCacheTtlName = 'itemsCacheTtl';

@LazySingleton(as: ItemsRepository)
class ItemsRepositoryImpl implements ItemsRepository {
  ItemsRepositoryImpl(
    this._api,
    this._localDataSource,
    @Named(itemsCacheTtlName) this._cacheTtl,
    this._talker,
  );

  final ItemsApi _api;
  final ItemsLocalDataSource _localDataSource;
  final Duration _cacheTtl;
  final Talker _talker;

  @override
  Future<Result<Paginated<Item>>> getPage({
    required int page,
    String? query,
    bool forceRefresh = false,
  }) async {
    final cached = await _localDataSource.readPage(page: page, query: query);
    if (!forceRefresh && cached != null && _isFresh(cached)) {
      return Ok(cached.data.toEntity(page: page));
    }

    final result = await safeCall(
      () => _api.getCharacters(page, query),
      talker: _talker,
    );
    switch (result) {
      case Ok(:final value):
        await _localDataSource.writePage(page: page, query: query, dto: value);
        return Ok(value.toEntity(page: page));
      // The API answers 404 when there is nothing to return.
      case Err(failure: NotFoundFailure()):
        return Ok(Paginated(items: const [], page: page, hasMore: false));
      case Err(:final failure):
        return cached != null && _canUseStale(failure)
            ? Ok(cached.data.toEntity(page: page))
            : Err(failure);
    }
  }

  @override
  Future<Result<Item>> getById(int id) async {
    final cached = await _localDataSource.readItem(id);
    if (cached != null && _isFresh(cached)) {
      return Ok(cached.data.toEntity());
    }

    final result = await safeCall(() => _api.getCharacter(id), talker: _talker);
    switch (result) {
      case Ok(:final value):
        await _localDataSource.writeItem(value);
        return Ok(value.toEntity());
      case Err(:final failure):
        return cached != null && _canUseStale(failure)
            ? Ok(cached.data.toEntity())
            : Err(failure);
    }
  }

  bool _isFresh(CachedRecord<Object> record) =>
      DateTime.now().difference(record.fetchedAt) < _cacheTtl;

  bool _canUseStale(Failure failure) =>
      failure is NetworkFailure || failure is ServerFailure;
}
