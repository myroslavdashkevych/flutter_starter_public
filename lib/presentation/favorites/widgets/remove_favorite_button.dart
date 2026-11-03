import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_messages.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:flutter_starter/presentation/favorites/bloc/favorites_state.dart';

/// Removes a favorite whose item no longer exists. Shown only while the item
/// is a favorite; [onRemoved] runs once it is gone.
class RemoveFavoriteButton extends StatelessWidget {
  const RemoveFavoriteButton({
    required this.id,
    required this.onRemoved,
    super.key,
  });

  final int id;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FavoritesCubit, FavoritesState>(
          listenWhen: (previous, current) =>
              previous.contains(id) && !current.contains(id),
          listener: (_, _) => onRemoved(),
        ),
        BlocListener<FavoritesCubit, FavoritesState>(
          listenWhen: (previous, current) =>
              current.removeFailure != null &&
              previous.removeFailure != current.removeFailure,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.removeFailure!.message(context.l10n)),
              ),
            );
          },
        ),
      ],
      child: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          if (!state.contains(id)) return const SizedBox.shrink();
          return FilledButton(
            onPressed: () => context.read<FavoritesCubit>().remove(id),
            child: Text(context.l10n.favoritesRemove),
          );
        },
      ),
    );
  }
}
