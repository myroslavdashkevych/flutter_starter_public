import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/settings/entities/app_settings.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_messages.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_cubit.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.appVersion,
    required this.privacyPolicyUrl,
    required this.onOpenLink,
    this.onLogs,
    this.onTestCrash,
    super.key,
  });

  final String appVersion;
  final Uri privacyPolicyUrl;

  /// Opens a web page; returns false when it could not be opened.
  final Future<bool> Function(Uri url) onOpenLink;

  /// Opens the logs; null hides the entry.
  final VoidCallback? onLogs;

  /// Causes an error to check crash reporting; null hides the entry.
  final VoidCallback? onTestCrash;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final cubit = context.read<SettingsCubit>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (previous, current) =>
            current.saveFailure != null &&
            previous.saveFailure != current.saveFailure,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.saveFailure!.message(context.l10n))),
          );
        },
        builder: (context, state) {
          final settings = state.settings;
          return ListView(
            children: [
              _SectionTitle(l10n.settingsAppearanceSection),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.settingsThemeSection,
                  style: textTheme.titleSmall,
                ),
              ),
              RadioGroup<ThemePreference>(
                groupValue: settings.themePreference,
                onChanged: (preference) => cubit.setTheme(preference!),
                child: Column(
                  children: [
                    RadioListTile(
                      value: ThemePreference.system,
                      title: Text(l10n.settingsThemeSystem),
                    ),
                    RadioListTile(
                      value: ThemePreference.light,
                      title: Text(l10n.settingsThemeLight),
                    ),
                    RadioListTile(
                      value: ThemePreference.dark,
                      title: Text(l10n.settingsThemeDark),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.settingsLanguageSection,
                  style: textTheme.titleSmall,
                ),
              ),
              RadioGroup<LocalePreference>(
                groupValue: settings.localePreference,
                onChanged: (preference) => cubit.setLocale(preference!),
                child: Column(
                  children: [
                    RadioListTile(
                      value: LocalePreference.system,
                      title: Text(l10n.settingsLanguageSystem),
                    ),
                    RadioListTile(
                      value: LocalePreference.en,
                      title: Text(l10n.settingsLanguageEnglish),
                    ),
                    RadioListTile(
                      value: LocalePreference.uk,
                      title: Text(l10n.settingsLanguageUkrainian),
                    ),
                  ],
                ),
              ),
              _SectionTitle(l10n.settingsPrivacySection),
              SwitchListTile(
                value: settings.usageDataSharing,
                onChanged: cubit.setUsageDataSharing,
                title: Text(l10n.settingsShareUsageData),
                subtitle: Text(l10n.settingsShareUsageDataDescription),
              ),
              ListTile(
                title: Text(l10n.settingsPrivacyPolicy),
                onTap: () => _openPrivacyPolicy(context),
              ),
              _SectionTitle(l10n.settingsAboutSection),
              ListTile(
                title: Text(l10n.settingsAppVersion),
                subtitle: Text(appVersion),
              ),
              if (onLogs != null)
                ListTile(title: Text(l10n.settingsLogs), onTap: onLogs),
              if (onTestCrash != null)
                ListTile(
                  title: Text(l10n.settingsTestCrash),
                  onTap: onTestCrash,
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final opened = await onOpenLink(privacyPolicyUrl);
    if (opened || !context.mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsLinkOpenFailed),
        action: SnackBarAction(
          label: l10n.settingsCopyLink,
          onPressed: () => Clipboard.setData(
            ClipboardData(text: privacyPolicyUrl.toString()),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
