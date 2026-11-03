import 'dart:async';

import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_events.dart';
import 'package:flutter_starter/domain/_shared/services/analytics_service.dart';
import 'package:flutter_starter/domain/favorites/repositories/favorites_repository.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:injectable/injectable.dart';

@injectable
class ToggleFavoriteUseCase {
  ToggleFavoriteUseCase(this._repository, this._analytics);

  final FavoritesRepository _repository;
  final AnalyticsService _analytics;

  Future<Result<bool>> call(Item item) async {
    final result = await _repository.toggle(item);
    if (result case Ok(value: final isFavorite)) {
      unawaited(
        _analytics.logEvent(
          isFavorite
              ? AnalyticsEvents.addToWishlist
              : AnalyticsEvents.removeFromWishlist,
          parameters: {AnalyticsParams.itemId: item.id.toString()},
        ),
      );
    }
    return result;
  }
}
