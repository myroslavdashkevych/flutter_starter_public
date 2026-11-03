import 'dart:async';

import 'package:flutter_starter/data/favorites/datasources/favorites_local_data_source.dart';
import 'package:flutter_starter/data/favorites/models/favorite_item_mapper.dart';
import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/auth/entities/app_user.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';
import 'package:flutter_starter/domain/favorites/repositories/favorites_repository.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

/// Keeps the current user's records in memory and follows the auth state for
/// as long as the app lives. Storage operations run one at a time, so a user
/// change never overlaps a write.
@LazySingleton(as: FavoritesRepository)
class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(
    AuthRepository authRepository,
    this._localDataSource,
    this._talker,
  ) {
    authRepository.authStateChanges().listen(_onUserChanged);
  }

  final FavoritesLocalDataSource _localDataSource;
  final Talker _talker;
  final _changes = StreamController<List<FavoriteRecord>>.broadcast();
  final _authKnown = Completer<void>();
  late Future<void> _queue = _authKnown.future;

  String? _uid;
  bool _isLoaded = false;
  List<FavoriteRecord>? _records;

  @override
  Stream<List<Item>> watchAll() => _watchRecords().map(
    (records) =>
        records.map((record) => record.item.toEntity()).toList(growable: false),
  );

  @override
  Stream<bool> watchIsFavorite(int id) => _watchRecords()
      .map((records) => records.any((record) => record.item.id == id))
      .distinct();

  @override
  Future<Result<bool>> toggle(Item item) => _enqueue(
    () => _guard(() async {
      final uid = _uid;
      if (uid == null) {
        return const Err(Failure.auth(AuthFailureReason.unknown));
      }
      if (!_isLoaded) await _load(uid);

      final records = _records ?? const <FavoriteRecord>[];
      final isFavorite = records.any((record) => record.item.id == item.id);
      if (isFavorite) {
        await _localDataSource.delete(uid, item.id);
        _publishFor(uid, [
          for (final record in records)
            if (record.item.id != item.id) record,
        ]);
      } else {
        final record = FavoriteRecord(
          item: item.toFavoriteDto(),
          addedAt: DateTime.now(),
        );
        await _localDataSource.write(uid, record);
        _publishFor(uid, [record, ...records]);
      }
      return Ok(!isFavorite);
    }),
  );

  @override
  Future<Result<void>> clearForUser(String uid) => _enqueue(
    () => _guard(() async {
      await _localDataSource.deleteBox(uid);
      _publishFor(uid, const []);
      return const Ok(null);
    }),
  );

  void _onUserChanged(AppUser? user) {
    final previous = _uid;
    final uid = user?.id;
    final isFirstEvent = !_authKnown.isCompleted;
    if (!isFirstEvent && uid == previous) return;

    _uid = uid;
    _isLoaded = false;
    // Screens must not keep showing the previous user's favorites meanwhile.
    if (previous != null || uid == null) _publish(const []);
    if (isFirstEvent) _authKnown.complete();

    unawaited(
      _enqueue(() async {
        final result = await _guard<void>(() async {
          if (previous != null) await _localDataSource.closeBox(previous);
          if (uid != null) await _load(uid);
          return const Ok(null);
        });
        if (result is Err<void> && uid != null) _publishFor(uid, const []);
      }),
    );
  }

  Future<void> _load(String uid) async {
    final records = await _localDataSource.readAll(uid);
    if (uid != _uid) return;
    _isLoaded = true;
    _publish(records);
  }

  Stream<List<FavoriteRecord>> _watchRecords() => Stream.multi((listener) {
    final records = _records;
    if (records != null) listener.add(records);
    final subscription = _changes.stream.listen(listener.add);
    listener.onCancel = subscription.cancel;
  });

  void _publishFor(String uid, List<FavoriteRecord> records) {
    if (uid == _uid) _publish(records);
  }

  void _publish(List<FavoriteRecord> records) {
    _records = records;
    _changes.add(records);
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
