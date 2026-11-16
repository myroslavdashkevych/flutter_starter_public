import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_message.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/favorite_list/bloc/favorite_list_bloc.dart';
import 'package:flutter_starter/presentation/favorite_list/bloc/favorite_list_event.dart';
import 'package:flutter_starter/presentation/favorite_list/bloc/favorite_list_state.dart';
import 'package:material_ui/material_ui.dart';

/// Removes a favorite whose character no longer exists. Shown only while the character
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
        BlocListener<FavoriteListBloc, FavoriteListState>(
          listenWhen: (previous, current) =>
              previous.contains(id) && !current.contains(id),
          listener: (_, _) => onRemoved(),
        ),
        BlocListener<FavoriteListBloc, FavoriteListState>(
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
      child: BlocBuilder<FavoriteListBloc, FavoriteListState>(
        builder: (context, state) {
          if (!state.contains(id)) return const SizedBox.shrink();
          return FilledButton(
            onPressed: () => context.read<FavoriteListBloc>().add(
              FavoriteListRemoveRequested(id),
            ),
            child: Text(context.l10n.favoriteRemove),
          );
        },
      ),
    );
  }
}
