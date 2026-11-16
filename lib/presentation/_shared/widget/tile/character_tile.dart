import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/presentation/_shared/l10n/character_status_label.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/_shared/widget/image/character_image.dart';
import 'package:material_ui/material_ui.dart';

class CharacterTile extends StatelessWidget {
  const CharacterTile({
    required this.character,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final Character character;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox.square(
          dimension: 56,
          child: CharacterImage(url: character.imageUrl),
        ),
      ),
      title: Text(character.name),
      subtitle: Text(
        '${character.species} · ${character.status.label(context.l10n)}',
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
