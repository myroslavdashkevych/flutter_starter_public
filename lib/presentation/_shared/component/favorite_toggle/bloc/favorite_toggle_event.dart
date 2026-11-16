import 'package:flutter_starter/domain/entity/character.dart';

sealed class FavoriteToggleEvent {
  const FavoriteToggleEvent();
}

/// Starts following the user and the mark of [characterId]; a new one replaces
/// the previous subscription.
final class FavoriteToggleStarted extends FavoriteToggleEvent {
  const FavoriteToggleStarted(this.characterId);

  final int characterId;
}

final class FavoriteToggleTapped extends FavoriteToggleEvent {
  const FavoriteToggleTapped(this.character);

  final Character character;
}
