import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/l10n/gen/app_localizations.dart';

extension ItemStatusLabel on ItemStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ItemStatus.alive => l10n.itemStatusAlive,
    ItemStatus.dead => l10n.itemStatusDead,
    ItemStatus.unknown => l10n.itemStatusUnknown,
  };
}
