import 'dart:convert';

import 'package:flutter_starter/data/_shared/base/data_source/expiring_cache.dart';
import 'package:flutter_starter/data/character/model/cached_record_dto.dart';
import 'package:flutter_starter/data/character/model/character_dto.dart';
import 'package:flutter_starter/data/character/model/character_page_dto.dart';
import 'package:flutter_starter/shared/utils/clock.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

/// A cache (see [ExpiringCache]): every record can be fetched again.
/// Cache failures never reach the caller: a read returns null, a write is
/// skipped, and both are logged.
@lazySingleton
class CharacterHiveDataSource implements ExpiringCache {
  CharacterHiveDataSource(this._hive, this._clock, this._talker);

  final HiveInterface _hive;
  final Clock _clock;
  final Talker _talker;
  Future<LazyBox<String>>? _box;

  static const boxName = 'character_cache';
  static const schemaVersion = 1;

  /// How long a record can still be shown offline. Freshness is the separate,
  /// much shorter TTL in the repository.
  static const maxAge = Duration(days: 90);

  static String pageKey({required int page, String? query}) =>
      'list:page=$page:q=${query ?? ''}';

  static String characterKey(int id) => 'character:$id';

  Future<CachedRecordDto<CharacterPageDto>?> readPage({
    required int page,
    String? query,
  }) => _read(pageKey(page: page, query: query), CharacterPageDto.fromJson);

  Future<CachedRecordDto<CharacterDto>?> readCharacter(int id) =>
      _read(characterKey(id), CharacterDto.fromJson);

  /// Also stores every character of the page, so its details open offline.
  Future<void> writePage({
    required int page,
    String? query,
    required CharacterPageDto dto,
  }) => _write({
    pageKey(page: page, query: query): _encode(dto.toJson()),
    for (final character in dto.results)
      characterKey(character.id): _encode(character.toJson()),
  });

  Future<void> writeCharacter(CharacterDto dto) =>
      _write({characterKey(dto.id): _encode(dto.toJson())});

  @override
  Future<void> evictExpired() async {
    try {
      final box = await _openBox();
      final oldest = _clock.now().subtract(maxAge);
      final evicted = [
        for (final key in box.keys)
          if (!_isKept(await box.get(key), oldest)) key,
      ];
      await box.deleteAll(evicted);
      if (evicted.isNotEmpty) {
        _talker.info('Evicted ${evicted.length} character cache records');
      }
    } on Object catch (error, stackTrace) {
      _talker.handle(error, stackTrace, 'Could not evict the character cache');
    }
  }

  // Parallel first calls share one Future; a failed open can be retried.
  Future<LazyBox<String>> _openBox() => _box ??= _hive
      .openLazyBox<String>(boxName)
      .catchError((Object error, StackTrace stackTrace) {
        _box = null;
        Error.throwWithStackTrace(error, stackTrace);
      });

  Future<CachedRecordDto<T>?> _read<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    try {
      final box = await _openBox();
      final value = await box.get(key);
      if (value == null) return null;

      // The version is checked first: data of another schema may not parse.
      final envelope = jsonDecode(value) as Map<String, dynamic>;
      if (envelope['schemaVersion'] != schemaVersion) {
        _talker.info('Ignoring cached $key with an old schema');
        return null;
      }
      return CachedRecordDto.fromJson(
        envelope,
        (json) => fromJson(json! as Map<String, dynamic>),
      );
    } on Object catch (error, stackTrace) {
      _talker.handle(error, stackTrace, 'Could not read cached $key');
      return null;
    }
  }

  Future<void> _write(Map<String, String> entries) async {
    try {
      final box = await _openBox();
      await box.putAll(entries);
    } on Object catch (error, stackTrace) {
      _talker.handle(
        error,
        stackTrace,
        'Could not write to the character cache',
      );
    }
  }

  // An envelope that cannot be decoded is unreadable, so it is not kept.
  bool _isKept(String? value, DateTime oldest) {
    if (value == null) return false;
    try {
      final envelope = jsonDecode(value) as Map<String, dynamic>;
      return envelope['schemaVersion'] == schemaVersion &&
          DateTime.parse(envelope['fetchedAt'] as String).isAfter(oldest);
    } on Object {
      return false;
    }
  }

  String _encode(Map<String, dynamic> json) => jsonEncode(
    CachedRecordDto(
      schemaVersion: schemaVersion,
      fetchedAt: _clock.now(),
      data: json,
    ).toJson((data) => data),
  );
}
