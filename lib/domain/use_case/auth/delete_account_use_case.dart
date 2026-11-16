import 'dart:async';

import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_service.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/repository/auth_repository.dart';
import 'package:flutter_starter/domain/repository/favorite_repository.dart';
import 'package:injectable/injectable.dart';

/// Deletes the account only after a fresh password check, then the user's
/// favorites.
@injectable
class DeleteAccountUseCase implements UseCase<void, ({String password})> {
  DeleteAccountUseCase(
    this._repository,
    this._favoriteRepository,
    this._analytics,
  );

  final AuthRepository _repository;
  final FavoriteRepository _favoriteRepository;
  final AnalyticsService _analytics;

  @override
  Future<Result<void>> call(({String password}) params) async {
    final reauthentication = await _repository.reauthenticate(
      password: params.password,
    );
    if (reauthentication is Err<void>) return reauthentication;

    // Deleting the account ends the session, so the id is read before it.
    final user = await _repository.authStateChanges().first;
    final deletion = await _repository.deleteAccount();
    if (deletion is Err<void>) return deletion;
    unawaited(_analytics.logEvent(const AnalyticsEvent.accountDeleted()));

    // The repository logs a failure; the account is already gone either way.
    if (user != null) await _favoriteRepository.clearForUser(user.id);
    return deletion;
  }
}
