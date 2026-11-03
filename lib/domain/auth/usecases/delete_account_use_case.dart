import 'dart:async';

import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_events.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_service.dart';
import 'package:flutter_starter/domain/auth/repositories/auth_repository.dart';
import 'package:flutter_starter/domain/favorites/repositories/favorites_repository.dart';
import 'package:injectable/injectable.dart';

/// Deletes the account only after a fresh password check, then the user's
/// favorites.
@injectable
class DeleteAccountUseCase {
  DeleteAccountUseCase(
    this._repository,
    this._favoritesRepository,
    this._analytics,
  );

  final AuthRepository _repository;
  final FavoritesRepository _favoritesRepository;
  final AnalyticsService _analytics;

  Future<Result<void>> call({required String password}) async {
    final reauthentication = await _repository.reauthenticate(
      password: password,
    );
    if (reauthentication is Err<void>) return reauthentication;

    // Deleting the account ends the session, so the id is read before it.
    final user = await _repository.authStateChanges().first;
    final deletion = await _repository.deleteAccount();
    if (deletion is Err<void>) return deletion;
    unawaited(_analytics.logEvent(AnalyticsEvents.accountDeleted));

    // The repository logs a failure; the account is already gone either way.
    if (user != null) await _favoritesRepository.clearForUser(user.id);
    return deletion;
  }
}
