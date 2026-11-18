import 'dart:async';

import 'package:flutter_starter/data/favorite/data_source/favorite_hive_data_source.dart';
import 'package:flutter_starter/data/favorite/mapper/favorite_character_mapper.dart';
import 'package:flutter_starter/data/favorite/model/favorite_record_dto.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/domain/repository/favorite_repository.dart';
import 'package:flutter_starter/shared/utils/clock.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

/// Keeps the records of every user that has listeners in memory. A user's box
/// is opened on first use and closed when nothing uses it any more: no
/// listener and no operation for that user. Storage operations run one at a
/// time, so closing a box never overlaps a write.
@LazySingleton(as: FavoriteRepository)
class FavoriteRepositoryImpl implements FavoriteRepository {
  FavoriteRepositoryImpl(this._localDataSource, this._clock, this._talker);

  final FavoriteHiveDataSource _localDataSource;
  final Clock _clock;
  final Talker _talker;
  final _users = <String, _UserRecords>{};
  Future<void> _queue = Future.value();

  @override
  Stream<List<Character>> watchAll(String uid) => _watchRecords(uid).map(
    (records) => records
        .map((record) => record.character.toEntity())
        .toList(growable: false),
  );

  @override
  Stream<bool> watchIsFavorite(String uid, int id) =>
      _watchRecords(uid)
          .map((records) => records.any((record) => record.character.id == id))
          .distinct();

  @override
  Future<Result<bool>> toggle(String uid, Character character) => _useUser(
    uid,
    (user) => _guard(() async {
      if (user.records == null) await _load(uid, user);

      final records = user.records ?? const <FavoriteRecordDto>[];
      final isFavorite = records.any(
        (record) => record.character.id == character.id,
      );
      if (isFavorite) {
        await _localDataSource.delete(uid, character.id);
        user.publish([
          for (final record in records)
            if (record.character.id != character.id) record,
        ]);
      } else {
        final record = FavoriteRecordDto(
          schemaVersion: FavoriteHiveDataSource.schemaVersion,
          addedAt: _clock.now(),
          character: character.toFavoriteDto(),
        );
        await _localDataSource.write(uid, record);
        user.publish([record, ...records]);
      }
      return Ok(!isFavorite);
    }),
  );

  @override
  Future<Result<void>> clearForUser(String uid) => _useUser(
    uid,
    (user) => _guard(() async {
      await _localDataSource.deleteBox(uid);
      user.publish(const []);
      return const Ok(null);
    }),
  );

  Stream<List<FavoriteRecordDto>> _watchRecords(String uid) =>
      Stream.multi((listener) {
        final user = _users[uid] ??= _UserRecords();
        user.listeners++;
        final records = user.records;
        if (records != null) listener.add(records);
        final subscription = user.changes.stream.listen(listener.add);
        // A queued load is skipped once the records are read; after a failed
        // read, a new listener tries again.
        if (records == null) {
          unawaited(_enqueue(() => _loadForListeners(uid, user)));
        }
        listener.onCancel = () async {
          await subscription.cancel();
          user.listeners--;
          unawaited(_enqueue(() => _releaseIfUnused(uid, user)));
        };
      });

  /// Runs [operation] for [uid] in the queue and releases the user after it,
  /// unless something else still uses them.
  Future<T> _useUser<T>(
    String uid,
    Future<T> Function(_UserRecords user) operation,
  ) {
    final user = _users[uid] ??= _UserRecords();
    user.operations++;
    return _enqueue(() async {
      try {
        return await operation(user);
      } finally {
        user.operations--;
        await _releaseIfUnused(uid, user);
      }
    });
  }

  Future<void> _loadForListeners(String uid, _UserRecords user) async {
    if (user.records != null || user.listeners == 0) return;
    final result = await _guard<void>(() async {
      await _load(uid, user);
      return const Ok(null);
    });
    // The list stays empty, but the next toggle reads again (FAV-9).
    if (result is Err<void>) user.changes.add(const []);
  }

  Future<void> _load(String uid, _UserRecords user) async {
    user.publish(await _localDataSource.readAll(uid));
  }

  Future<void> _releaseIfUnused(String uid, _UserRecords user) async {
    if (user.listeners > 0 || user.operations > 0) return;
    if (_users[uid] != user) return;
    _users.remove(uid);
    await user.changes.close();
    try {
      await _localDataSource.closeBox(uid);
    } on Object catch (error, stackTrace) {
      _talker.handle(error, stackTrace, 'Could not close the favorites box');
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() call) async {
    try {
      return await call();
    } on Object catch (error, stackTrace) {
      _talker.handle(error, stackTrace, 'Favorites storage error');
      return const Err(Failure.cache());
    }
  }
}

/// What the repository holds for one user while something uses them.
class _UserRecords {
  final changes = StreamController<List<FavoriteRecordDto>>.broadcast();
  int listeners = 0;
  int operations = 0;

  /// Null until read; a failed read leaves it null (FAV-9).
  List<FavoriteRecordDto>? records;

  void publish(List<FavoriteRecordDto> value) {
    records = value;
    changes.add(value);
  }
}
