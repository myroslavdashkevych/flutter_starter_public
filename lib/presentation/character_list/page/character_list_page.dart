import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/domain/entity/character.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_message.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/presentation/_shared/theme/const/app_spacing.dart';
import 'package:flutter_starter/presentation/_shared/widget/state/failure_view.dart';
import 'package:flutter_starter/presentation/_shared/widget/tile/character_tile.dart';
import 'package:flutter_starter/presentation/character_list/bloc/character_list_bloc.dart';
import 'package:flutter_starter/presentation/character_list/bloc/character_list_event.dart';
import 'package:flutter_starter/presentation/character_list/bloc/character_list_state.dart';
import 'package:material_ui/material_ui.dart';

class CharacterListPage extends StatelessWidget {
  const CharacterListPage({
    required this.onCharacterSelected,
    required this.favoriteToggleBuilder,
    super.key,
  });

  final ValueChanged<int> onCharacterSelected;
  final Widget Function(Character character) favoriteToggleBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      // The search field sits between the bar and the list, so no scroll tint.
      appBar: AppBar(
        title: Text(l10n.navCharacterList),
        notificationPredicate: (_) => false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.content,
              0,
              AppSpacing.content,
              AppSpacing.inline,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.characterListSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (query) => context.read<CharacterListBloc>().add(
                CharacterListSearchChanged(query),
              ),
            ),
          ),
          Expanded(
            child: BlocConsumer<CharacterListBloc, CharacterListState>(
              listenWhen: (previous, current) =>
                  current.refreshFailure != null &&
                  previous.refreshFailure != current.refreshFailure,
              listener: (context, state) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.refreshFailure!.message(context.l10n)),
                  ),
                );
              },
              builder: (context, state) => switch (state.status) {
                CharacterListStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                CharacterListStatus.failure => Center(
                  child: FailureView(
                    failure: state.failure!,
                    onRetry: () => context.read<CharacterListBloc>().add(
                      const CharacterListLoadRequested(),
                    ),
                  ),
                ),
                CharacterListStatus.loaded => _CharacterList(
                  state: state,
                  onCharacterSelected: onCharacterSelected,
                  favoriteToggleBuilder: favoriteToggleBuilder,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterList extends StatelessWidget {
  const _CharacterList({
    required this.state,
    required this.onCharacterSelected,
    required this.favoriteToggleBuilder,
  });

  final CharacterListState state;
  final ValueChanged<int> onCharacterSelected;
  final Widget Function(Character character) favoriteToggleBuilder;

  static const _loadMoreThreshold = 0.8;

  Future<void> _handleRefresh(BuildContext context) async {
    final bloc = context.read<CharacterListBloc>()
      ..add(const CharacterListRefreshRequested());
    await bloc.stream.firstWhere(
      (state) => !state.isRefreshing,
      orElse: () => bloc.state,
    );
  }

  bool _handleScroll(BuildContext context, ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.pixels >= metrics.maxScrollExtent * _loadMoreThreshold &&
        state.hasMore &&
        !state.isLoadingMore &&
        state.loadMoreFailure == null) {
      context.read<CharacterListBloc>().add(
        const CharacterListNextPageRequested(),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final hasFooter = state.isLoadingMore || state.loadMoreFailure != null;
    return RefreshIndicator(
      onRefresh: () => _handleRefresh(context),
      child: state.characters.isEmpty
          ? _EmptyList(query: state.query)
          : NotificationListener<ScrollNotification>(
              onNotification: (notification) =>
                  _handleScroll(context, notification),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: state.characters.length + (hasFooter ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.characters.length) {
                    return _ListFooter(state: state);
                  }
                  final character = state.characters[index];
                  // The key keeps a toggle's state with its character when the
                  // list changes.
                  return CharacterTile(
                    key: ValueKey(character.id),
                    character: character,
                    onTap: () => onCharacterSelected(character.id),
                    trailing: favoriteToggleBuilder(character),
                  );
                },
              ),
            ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.emptyState),
      children: [
        Text(
          query.trim().isEmpty
              ? l10n.characterListEmpty
              : l10n.characterListNoResults,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.state});

  final CharacterListState state;

  @override
  Widget build(BuildContext context) {
    final failure = state.loadMoreFailure;
    if (failure != null) {
      return FailureView(
        failure: failure,
        onRetry: () => context.read<CharacterListBloc>().add(
          const CharacterListNextPageRequested(),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.content),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
