import 'package:flutter_starter/data/_shared/data_source/network/safe_call.dart';
import 'package:flutter_starter/data/character/data_source/character_api_data_source.dart';
import 'package:flutter_starter/data/character/data_source/character_hive_data_source.dart';
import 'package:flutter_starter/data/character/mapper/character_mapper.dart';
import 'package:flutter_starter/data/character/model/cached_record_dto.dart';
import 'package:flutter_starter/domain/_shared/wrapper/pagination/paginated.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/domain/repository/character_repository.dart';
import 'package:flutter_starter/shared/utils/clock.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

const characterCacheTtlName = 'characterCacheTtl';

@LazySingleton(as: CharacterRepository)
class CharacterRepositoryImpl implements CharacterRepository {
  CharacterRepositoryImpl(
    this._api,
    this._localDataSource,
    @Named(characterCacheTtlName) this._cacheTtl,
    this._clock,
    this._talker,
  );

  final CharacterApiDataSource _api;
  final CharacterHiveDataSource _localDataSource;
  final Duration _cacheTtl;
  final Clock _clock;
  final Talker _talker;

  @override
  Future<Result<Paginated<Character>>> getPage({
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
  Future<Result<Character>> getById(int id) async {
    final cached = await _localDataSource.readCharacter(id);
    if (cached != null && _isFresh(cached)) {
      return Ok(cached.data.toEntity());
    }

    final result = await safeCall(() => _api.getCharacter(id), talker: _talker);
    switch (result) {
      case Ok(:final value):
        await _localDataSource.writeCharacter(value);
        return Ok(value.toEntity());
      case Err(:final failure):
        return cached != null && _canUseStale(failure)
            ? Ok(cached.data.toEntity())
            : Err(failure);
    }
  }

  bool _isFresh(CachedRecordDto<Object> record) =>
      _clock.now().difference(record.fetchedAt) < _cacheTtl;

  bool _canUseStale(Failure failure) =>
      failure is NetworkFailure || failure is ServerFailure;
}
