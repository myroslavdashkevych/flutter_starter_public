import 'package:flutter_starter/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// The delegates of every `MaterialApp` in the app and in tests.
///
/// `AppLocalizations.localizationsDelegates` brings the app's strings and the
/// translations of the SDK's legacy `package:flutter/material.dart`, which
/// `TalkerScreen` (talker_flutter) still uses. `material_ui` widgets read their
/// own translations, added here from `material_ui`.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  ...AppLocalizations.localizationsDelegates,
  ...GlobalMaterialLocalizations.delegates,
];
