import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/entity/app_settings.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_message.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/_shared/theme/const/app_spacing.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_bloc.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_event.dart';
import 'package:flutter_starter/presentation/settings/bloc/settings_state.dart';
import 'package:material_ui/material_ui.dart';

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

  Future<void> _handlePrivacyPolicyTap(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final bloc = context.read<SettingsBloc>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: BlocConsumer<SettingsBloc, SettingsState>(
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
                padding: const EdgeInsets.all(AppSpacing.content),
                child: Text(
                  l10n.settingsThemeSection,
                  style: textTheme.titleSmall,
                ),
              ),
              RadioGroup<ThemePreference>(
                groupValue: settings.themePreference,
                onChanged: (preference) =>
                    bloc.add(SettingsThemeChanged(preference!)),
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
                padding: const EdgeInsets.all(AppSpacing.content),
                child: Text(
                  l10n.settingsLanguageSection,
                  style: textTheme.titleSmall,
                ),
              ),
              RadioGroup<LocalePreference>(
                groupValue: settings.localePreference,
                onChanged: (preference) =>
                    bloc.add(SettingsLocaleChanged(preference!)),
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
                onChanged: (enabled) =>
                    bloc.add(SettingsUsageDataSharingChanged(enabled)),
                title: Text(l10n.settingsShareUsageData),
                subtitle: Text(l10n.settingsShareUsageDataDescription),
              ),
              ListTile(
                title: Text(l10n.settingsPrivacyPolicy),
                onTap: () => _handlePrivacyPolicyTap(context),
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.content,
        AppSpacing.section,
        AppSpacing.content,
        0,
      ),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
