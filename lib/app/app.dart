import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/app/locale_resolution.dart';
import 'package:flutter_starter/domain/settings/entities/app_settings.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/_shared/theme/app_theme.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_cubit.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_state.dart';
import 'package:go_router/go_router.dart';

class App extends StatelessWidget {
  const App({required this.router, required this.settingsCubit, super.key});

  final GoRouter router;
  final SettingsCubit settingsCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: settingsCubit,
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (previous, current) => previous.settings != current.settings,
        builder: (context, state) => MaterialApp.router(
          onGenerateTitle: (context) => context.l10n.appTitle,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeMode(state.settings.themePreference),
          locale: _locale(state.settings.localePreference),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeListResolutionCallback: resolveDeviceLocale,
          routerConfig: router,
        ),
      ),
    );
  }

  ThemeMode _themeMode(ThemePreference preference) => switch (preference) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };

  Locale? _locale(LocalePreference preference) => switch (preference) {
    LocalePreference.system => null,
    LocalePreference.en => const Locale('en'),
    LocalePreference.uk => const Locale('uk'),
  };
}
