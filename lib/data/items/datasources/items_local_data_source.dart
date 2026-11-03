import 'dart:convert';

import 'package:flutter_starter/data/_shared/storage/expiring_cache.dart';
import 'package:flutter_starter/data/items/models/character_dto.dart';
import 'package:flutter_starter/data/items/models/characters_page_dto.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

class CachedRecord<T> {
  const CachedRecord({required this.data, required this.fetchedAt});

  final T data;
  final DateTime fetchedAt;
}

/// A cache (see [ExpiringCache]): every record can be fetched again.
/// Cache failures never reach the caller: a read returns null, a write is
/// skipped, and both are logged.
@lazySingleton
class ItemsLocalDataSource implements ExpiringCache {
  ItemsLocalDataSource(this._hive, this._talker);

  static const boxName = 'items_cache';
  static const schemaVersion = 1;

  /// How long a record can still be shown offline. Freshness is the separate,
  /// much shorter TTL in the repository.
  static const maxAge = Duration(days: 90);

  final HiveInterface _hive;
  final Talker _talker;
  Future<LazyBox<String>>? _box;

  static String pageKey({required int page, String? query}) =>
      'list:page=$page:q=${query ?? ''}';

  static String itemKey(int id) => 'item:$id';

  Future<CachedRecord<CharactersPageDto>?> readPage({
    required int page,
    String? query,
  }) => _read(pageKey(page: page, query: query), CharactersPageDto.fromJson);

  Future<CachedRecord<CharacterDto>?> readItem(int id) =>
      _read(itemKey(id), CharacterDto.fromJson);

  /// Also stores every item of the page, so its details open offline.
  Future<void> writePage({
    required int page,
    String? query,
    required CharactersPageDto dto,
  }) => _write({
    pageKey(page: page, query: query): _encode(dto.toJson()),
    for (final character in dto.results)
      itemKey(character.id): _encode(character.toJson()),
  });

  Future<void> writeItem(CharacterDto dto) =>
      _write({itemKey(dto.id): _encode(dto.toJson())});

  @override
  Future<void> evictExpired() async {
    try {
      final box = await _openBox();
      final oldest = DateTime.now().subtract(maxAge);
      final evicted = [
        for (final key in box.keys)
          if (!_isKept(await box.get(key), oldest)) key,
      ];
      await box.deleteAll(evicted);
      if (evicted.isNotEmpty) {
        _talker.info('Evicted ${evicted.length} items cache records');
      }
    } on Object catch (error, stackTrace) {
      _talker.handle(error, stackTrace, 'Could not evict the items cache');
    }
  }

  // Parallel first calls share one Future; a failed open can be retried.
  Future<LazyBox<String>> _openBox() => _box ??= _hive
      .openLazyBox<String>(boxName)
      .catchError((Object error, StackTrace stackTrace) {
        _box = null;
        Error.throwWithStackTrace(error, stackTrace);
      });

  Future<CachedRecord<T>?> _read<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    try {
      final box = await _openBox();
      final value = await box.get(key);
      if (value == null) return null;

      final envelope = jsonDecode(value) as Map<String, dynamic>;
      if (envelope['schemaVersion'] != schemaVersion) {
        _talker.info('Ignoring cached $key with an old schema');
        return null;
      }
      return CachedRecord(
        data: fromJson(envelope['data'] as Map<String, dynamic>),
        fetchedAt: DateTime.parse(envelope['fetchedAt'] as String),
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
      _talker.handle(error, stackTrace, 'Could not write to the items cache');
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

  String _encode(Map<String, dynamic> json) => jsonEncode({
    'schemaVersion': schemaVersion,
    'fetchedAt': DateTime.now().toIso8601String(),
    'data': json,
  });
}
