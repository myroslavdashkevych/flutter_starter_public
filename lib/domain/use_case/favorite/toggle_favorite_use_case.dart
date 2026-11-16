import 'dart:async';

import 'package:flutter_starter/domain/_shared/base/use_case/use_case.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_event.dart';
import 'package:flutter_starter/domain/_shared/service/analytics/analytics_service.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/domain/repository/auth_repository.dart';
import 'package:flutter_starter/domain/repository/favorite_repository.dart';
import 'package:injectable/injectable.dart';

/// Toggles a character for the current user; a guest cannot (FAV-2).
@injectable
class ToggleFavoriteUseCase implements UseCase<bool, ({Character character})> {
  ToggleFavoriteUseCase(
    this._authRepository,
    this._favoriteRepository,
    this._analytics,
  );

  final AuthRepository _authRepository;
  final FavoriteRepository _favoriteRepository;
  final AnalyticsService _analytics;

  @override
  Future<Result<bool>> call(({Character character}) params) async {
    final character = params.character;
    final user = await _authRepository.authStateChanges().first;
    if (user == null) {
      // A guest sees no toggle (FAV-2), so this state is never reached.
      return const Err(Failure.unexpected());
    }
    final result = await _favoriteRepository.toggle(user.id, character);
    if (result case Ok(value: final isFavorite)) {
      unawaited(
        _analytics.logEvent(
          isFavorite
              ? AnalyticsEvent.favoriteAdded(characterId: character.id)
              : AnalyticsEvent.favoriteRemoved(characterId: character.id),
        ),
      );
    }
    return result;
  }
}
