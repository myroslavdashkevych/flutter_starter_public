import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_starter/presentation/_shared/l10n/failure_messages.dart';
import 'package:flutter_starter/presentation/_shared/l10n/l10n_extension.dart';
import 'package:flutter_starter/domain/items/entities/item.dart';
import 'package:flutter_starter/presentation/_shared/widgets/failure_view.dart';
import 'package:flutter_starter/presentation/_shared/widgets/item_tile.dart';
import 'package:flutter_starter/presentation/items_list/bloc/items_list_bloc.dart';
import 'package:flutter_starter/presentation/items_list/bloc/items_list_event.dart';
import 'package:flutter_starter/presentation/items_list/bloc/items_list_state.dart';

class ItemsListPage extends StatelessWidget {
  const ItemsListPage({
    required this.onItemSelected,
    required this.favoriteToggleBuilder,
    super.key,
  });

  final ValueChanged<int> onItemSelected;
  final Widget Function(Item item) favoriteToggleBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      // The search field sits between the bar and the list, so no scroll tint.
      appBar: AppBar(
        title: Text(l10n.navItems),
        notificationPredicate: (_) => false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.itemsSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (query) => context.read<ItemsListBloc>().add(
                ItemsListSearchChanged(query),
              ),
            ),
          ),
          Expanded(
            child: BlocConsumer<ItemsListBloc, ItemsListState>(
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
                ItemsListStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                ItemsListStatus.failure => Center(
                  child: FailureView(
                    failure: state.failure!,
                    onRetry: () => context.read<ItemsListBloc>().add(
                      const ItemsListLoadRequested(),
                    ),
                  ),
                ),
                ItemsListStatus.loaded => _ItemsList(
                  state: state,
                  onItemSelected: onItemSelected,
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

class _ItemsList extends StatelessWidget {
  const _ItemsList({
    required this.state,
    required this.onItemSelected,
    required this.favoriteToggleBuilder,
  });

  static const _loadMoreThreshold = 0.8;

  final ItemsListState state;
  final ValueChanged<int> onItemSelected;
  final Widget Function(Item item) favoriteToggleBuilder;

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<ItemsListBloc>()
      ..add(const ItemsListRefreshRequested());
    await bloc.stream.firstWhere(
      (state) => !state.isRefreshing,
      orElse: () => bloc.state,
    );
  }

  bool _onScroll(BuildContext context, ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.pixels >= metrics.maxScrollExtent * _loadMoreThreshold &&
        state.hasMore &&
        !state.isLoadingMore &&
        state.loadMoreFailure == null) {
      context.read<ItemsListBloc>().add(const ItemsListNextPageRequested());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final hasFooter = state.isLoadingMore || state.loadMoreFailure != null;
    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: state.items.isEmpty
          ? _EmptyList(query: state.query)
          : NotificationListener<ScrollNotification>(
              onNotification: (notification) =>
                  _onScroll(context, notification),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: state.items.length + (hasFooter ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.items.length) {
                    return _ListFooter(state: state);
                  }
                  final item = state.items[index];
                  // The key keeps a toggle's state with its item when the list
                  // changes.
                  return ItemTile(
                    key: ValueKey(item.id),
                    item: item,
                    onTap: () => onItemSelected(item.id),
                    trailing: favoriteToggleBuilder(item),
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
      padding: const EdgeInsets.all(32),
      children: [
        Text(
          query.trim().isEmpty ? l10n.itemsEmpty : l10n.itemsNoResults,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.state});

  final ItemsListState state;

  @override
  Widget build(BuildContext context) {
    final failure = state.loadMoreFailure;
    if (failure != null) {
      return FailureView(
        failure: failure,
        onRetry: () => context.read<ItemsListBloc>().add(
          const ItemsListNextPageRequested(),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
