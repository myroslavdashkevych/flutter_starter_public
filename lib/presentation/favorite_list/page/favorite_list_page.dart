import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/_shared/theme/const/app_spacing.dart';
import 'package:flutter_starter/presentation/_shared/widget/tile/character_tile.dart';
import 'package:flutter_starter/presentation/favorite_list/bloc/favorite_list_bloc.dart';
import 'package:flutter_starter/presentation/favorite_list/bloc/favorite_list_state.dart';
import 'package:material_ui/material_ui.dart';

class FavoriteListPage extends StatelessWidget {
  const FavoriteListPage({
    required this.onSignIn,
    required this.onCharacterSelected,
    required this.favoriteToggleBuilder,
    super.key,
  });

  final VoidCallback onSignIn;
  final ValueChanged<int> onCharacterSelected;
  final Widget Function(Character character) favoriteToggleBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.favoriteListTitle)),
      body: BlocBuilder<FavoriteListBloc, FavoriteListState>(
        builder: (context, state) {
          final characters = state.characters;
          return switch (state.authStatus) {
            FavoriteListAuthStatus.guest => _GuestView(onSignIn: onSignIn),
            FavoriteListAuthStatus.signedIn when characters != null =>
              characters.isEmpty
                  ? const _EmptyView()
                  : ListView.builder(
                      itemCount: characters.length,
                      itemBuilder: (context, index) {
                        final character = characters[index];
                        // The key keeps a toggle's state with its character
                        // when a character above it is removed.
                        return CharacterTile(
                          key: ValueKey(character.id),
                          character: character,
                          onTap: () => onCharacterSelected(character.id),
                          trailing: favoriteToggleBuilder(character),
                        );
                      },
                    ),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
    );
  }
}

class _GuestView extends StatelessWidget {
  const _GuestView({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.content),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.item,
          children: [
            Text(l10n.favoriteListGuestMessage, textAlign: TextAlign.center),
            FilledButton(onPressed: onSignIn, child: Text(l10n.profileSignIn)),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.emptyState),
        child: Text(
          context.l10n.favoriteListEmpty,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
