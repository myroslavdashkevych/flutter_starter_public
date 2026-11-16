import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/presentation/_shared/component/favorite_toggle/bloc/favorite_toggle_bloc.dart';
import 'package:flutter_starter/presentation/_shared/component/favorite_toggle/bloc/favorite_toggle_event.dart';
import 'package:flutter_starter/presentation/_shared/component/favorite_toggle/bloc/favorite_toggle_state.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_message.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:material_ui/material_ui.dart';

/// Takes no space for a guest.
class FavoriteToggle extends StatelessWidget {
  const FavoriteToggle({required this.character, super.key});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<FavoriteToggleBloc, FavoriteToggleState>(
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
          tooltip: state.isFavorite ? l10n.favoriteRemove : l10n.favoriteAdd,
          onPressed: () => context.read<FavoriteToggleBloc>().add(
            FavoriteToggleTapped(character),
          ),
        );
      },
    );
  }
}
