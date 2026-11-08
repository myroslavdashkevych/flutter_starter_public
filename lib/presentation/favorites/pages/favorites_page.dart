import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/_shared/widgets/item/item_tile.dart';
import 'package:flutter_starter/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:flutter_starter/presentation/favorites/bloc/favorites_state.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({
    required this.onSignIn,
    required this.onItemSelected,
    required this.favoriteToggleBuilder,
    super.key,
  });

  final VoidCallback onSignIn;
  final ValueChanged<int> onItemSelected;
  final Widget Function(Item item) favoriteToggleBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.favoritesTitle)),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          final items = state.items;
          return switch (state.authStatus) {
            FavoritesAuthStatus.guest => _GuestView(onSignIn: onSignIn),
            FavoritesAuthStatus.signedIn when items != null =>
              items.isEmpty
                  ? const _EmptyView()
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        // The key keeps a toggle's state with its item when
                        // an item above it is removed.
                        return ItemTile(
                          key: ValueKey(item.id),
                          item: item,
                          onTap: () => onItemSelected(item.id),
                          trailing: favoriteToggleBuilder(item),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(l10n.favoritesGuestMessage, textAlign: TextAlign.center),
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
        padding: const EdgeInsets.all(32),
        child: Text(context.l10n.favoritesEmpty, textAlign: TextAlign.center),
      ),
    );
  }
}
