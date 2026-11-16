import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';

extension CharacterStatusLabel on CharacterStatus {
  String label(AppLocalizations l10n) => switch (this) {
    CharacterStatus.alive => l10n.characterStatusAlive,
    CharacterStatus.dead => l10n.characterStatusDead,
    CharacterStatus.unknown => l10n.characterStatusUnknown,
  };
}
