import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';
import 'package:flutter_starter/domain/entity/app_settings.dart';
import 'package:flutter_starter/domain/use_case/settings/load_settings_use_case.dart';
import 'package:flutter_starter/domain/use_case/settings/save_settings_use_case.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_event.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_state.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._loadSettings, this._saveSettings)
    : super(const SettingsState()) {
    on<SettingsEvent>(
      (event, emit) => switch (event) {
        SettingsLoadRequested() => _load(emit),
        SettingsThemeChanged(:final preference) => _apply(
          state.settings.copyWith(themePreference: preference),
          emit,
        ),
        SettingsLocaleChanged(:final preference) => _apply(
          state.settings.copyWith(localePreference: preference),
          emit,
        ),
        SettingsUsageDataSharingChanged(:final enabled) => _apply(
          state.settings.copyWith(usageDataSharing: enabled),
          emit,
        ),
      },
      transformer: sequential(),
    );
  }

  final LoadSettingsUseCase _loadSettings;
  final SaveSettingsUseCase _saveSettings;

  // The repository falls back to the defaults itself; the current settings
  // cover an Err, so startup never waits for a load that failed.
  Future<void> _load(Emitter<SettingsState> emit) async {
    final settings = switch (await _loadSettings(())) {
      Ok(:final value) => value,
      Err() => state.settings,
    };
    emit(SettingsState(settings: settings, isLoaded: true));
  }

  // The new value stays applied when saving fails, until the next restart.
  Future<void> _apply(AppSettings settings, Emitter<SettingsState> emit) async {
    emit(SettingsState(settings: settings, isLoaded: state.isLoaded));
    final result = await _saveSettings((settings: settings));
    if (result case Err(:final failure)) {
      emit(state.copyWith(saveFailure: failure));
    }
  }
}
