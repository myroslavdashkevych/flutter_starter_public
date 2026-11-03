import 'package:flutter/widgets.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';

extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
