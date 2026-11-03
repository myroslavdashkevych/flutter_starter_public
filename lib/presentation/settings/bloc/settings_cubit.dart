import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/_shared/result.dart';
import 'package:flutter_starter/domain/settings/entities/app_settings.dart';
import 'package:flutter_starter/domain/settings/repositories/settings_repository.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_state.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository) : super(const SettingsState());

  final SettingsRepository _repository;

  Future<void> load() async {
    emit(SettingsState(settings: await _repository.load()));
  }

  Future<void> setTheme(ThemePreference preference) =>
      _apply(state.settings.copyWith(themePreference: preference));

  Future<void> setLocale(LocalePreference preference) =>
      _apply(state.settings.copyWith(localePreference: preference));

  Future<void> setUsageDataSharing(bool enabled) =>
      _apply(state.settings.copyWith(usageDataSharing: enabled));

  // The new value stays applied when saving fails, until the next restart.
  Future<void> _apply(AppSettings settings) async {
    emit(SettingsState(settings: settings));
    final result = await _repository.save(settings);
    if (result case Err(:final failure)) {
      emit(state.copyWith(saveFailure: failure));
    }
  }
}
