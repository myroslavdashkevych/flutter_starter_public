import 'dart:convert';

import 'package:flutter_starter/data/favorite/model/favorite_record_dto.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

/// User data, not a cache (doc/spec/architecture.md, Local storage): the user created
/// it and it cannot be fetched again. Never expires and is never deleted
/// automatically: only [delete] (the user removes a favorite) and [deleteBox]
/// (the user deletes the account) remove records. Must not implement
/// `ExpiringCache`.
///
/// One box per user. Storage failures reach the caller. A single unreadable
/// record is skipped and stays in the box, so a later version can still
/// migrate it.
@lazySingleton
class FavoriteHiveDataSource {
  FavoriteHiveDataSource(this._hive, this._talker);

  final HiveInterface _hive;
  final Talker _talker;

  static const schemaVersion = 1;

  /// Hive lower-cases box names and user ids are case-sensitive, so the id is
  /// stored in hex.
  static String boxName(String uid) {
    final hex = utf8
        .encode(uid)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'favorite_$hex';
  }

  /// Returns the readable records, newest first.
  Future<List<FavoriteRecordDto>> readAll(String uid) async {
    final box = await _openBox(uid);
    final records = <FavoriteRecordDto>[];
    for (final key in box.keys) {
      final value = await box.get(key);
      final record = value == null ? null : _decode(key, value);
      if (record != null) records.add(record);
    }
    records.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return records;
  }

  Future<void> write(String uid, FavoriteRecordDto record) async {
    final box = await _openBox(uid);
    await box.put(_key(record.character.id), _encode(record));
  }

  Future<void> delete(String uid, int id) async {
    final box = await _openBox(uid);
    await box.delete(_key(id));
  }

  Future<void> closeBox(String uid) async {
    final name = boxName(uid);
    if (_hive.isBoxOpen(name)) await _hive.lazyBox<String>(name).close();
  }

  Future<void> deleteBox(String uid) => _hive.deleteBoxFromDisk(boxName(uid));

  Future<LazyBox<String>> _openBox(String uid) =>
      _hive.openLazyBox<String>(boxName(uid));

  String _key(int id) => '$id';

  FavoriteRecordDto? _decode(Object? key, String value) {
    try {
      // The version is checked first: data of another schema may not parse.
      final envelope = jsonDecode(value) as Map<String, dynamic>;
      if (envelope['schemaVersion'] != schemaVersion) {
        _talker.info('Skipping favorite $key with another schema');
        return null;
      }
      return FavoriteRecordDto.fromJson(envelope);
    } on Object catch (error, stackTrace) {
      _talker.handle(error, stackTrace, 'Could not read favorite $key');
      return null;
    }
  }

  String _encode(FavoriteRecordDto record) => jsonEncode(record.toJson());
}
