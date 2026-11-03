import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/presentation/_shared/favorites/favorite_toggle_cubit.dart';
import 'package:flutter_starter/presentation/_shared/favorites/favorite_toggle_state.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_messages.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';

/// Takes no space for a guest.
class FavoriteToggle extends StatelessWidget {
  const FavoriteToggle({required this.item, super.key});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<FavoriteToggleCubit, FavoriteToggleState>(
      listenWhen: (previous, current) =>
          current.failure != null && previous.failure != current.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.failure!.message(l10n))));
      },
      builder: (context, state) {
        if (!state.isSignedIn) return const SizedBox.shrink();
        return IconButton(
          icon: Icon(state.isFavorite ? Icons.favorite : Icons.favorite_border),
          tooltip: state.isFavorite ? l10n.favoritesRemove : l10n.favoritesAdd,
          onPressed: () => context.read<FavoriteToggleCubit>().toggle(item),
        );
      },
    );
  }
}
