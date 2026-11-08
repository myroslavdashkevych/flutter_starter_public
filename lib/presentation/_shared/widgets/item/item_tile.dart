import 'package:flutter/material.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/presentation/_shared/l10n/item_status_labels.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/_shared/widgets/item/item_image.dart';

class ItemTile extends StatelessWidget {
  const ItemTile({
    required this.item,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final Item item;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox.square(
          dimension: 56,
          child: ItemImage(url: item.imageUrl),
        ),
      ),
      title: Text(item.name),
      subtitle: Text('${item.species} · ${item.status.label(context.l10n)}'),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
