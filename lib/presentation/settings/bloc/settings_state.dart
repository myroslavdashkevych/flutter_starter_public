import 'package:flutter_starter/domain/_shared/failure.dart';
import 'package:flutter_starter/domain/settings/entities/app_settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_state.freezed.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(AppSettings()) AppSettings settings,
    Failure? saveFailure,
  }) = _SettingsState;
}
