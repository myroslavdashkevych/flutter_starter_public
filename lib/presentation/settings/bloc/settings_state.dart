import 'package:flutter_starter/domain/_shared/wrapper/result/failure.dart';
import 'package:flutter_starter/domain/entity/app_settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_state.freezed.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(AppSettings()) AppSettings settings,
    Failure? saveFailure,

    /// True once the stored settings were read; bootstrap waits for it (SET-4).
    @Default(false) bool isLoaded,
  }) = _SettingsState;
}
