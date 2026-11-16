import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_event.freezed.dart';

/// A business event sent through [AnalyticsService]. The domain names what
/// happened; the event names and parameters sent to the analytics backend are
/// set by the service implementation in data.
@freezed
sealed class AnalyticsEvent with _$AnalyticsEvent {
  /// A sign-in with email and password succeeded (AUTH-8).
  const factory AnalyticsEvent.signedIn() = SignedInAnalyticsEvent;

  /// A sign-up with email and password succeeded (AUTH-8).
  const factory AnalyticsEvent.signedUp() = SignedUpAnalyticsEvent;

  /// A password reset request succeeded (AUTH-8).
  const factory AnalyticsEvent.passwordResetRequested() =
      PasswordResetRequestedAnalyticsEvent;

  /// The user searched the characters list for [term] (CHR-17).
  const factory AnalyticsEvent.searched({required String term}) =
      SearchedAnalyticsEvent;

  /// The user opened the character [characterId] (CHR-18).
  const factory AnalyticsEvent.characterOpened({required int characterId}) =
      CharacterOpenedAnalyticsEvent;

  /// The account was deleted (PRF-8).
  const factory AnalyticsEvent.accountDeleted() = AccountDeletedAnalyticsEvent;

  /// The character [characterId] was added to the favorites (FAV-11).
  const factory AnalyticsEvent.favoriteAdded({required int characterId}) =
      FavoriteAddedAnalyticsEvent;

  /// The character [characterId] was removed from the favorites (FAV-11).
  const factory AnalyticsEvent.favoriteRemoved({required int characterId}) =
      FavoriteRemovedAnalyticsEvent;
}
