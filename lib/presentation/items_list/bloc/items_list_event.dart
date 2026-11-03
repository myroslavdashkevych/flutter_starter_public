sealed class ItemsListEvent {
  const ItemsListEvent();
}

/// First load, and retry after it failed.
final class ItemsListLoadRequested extends ItemsListEvent {
  const ItemsListLoadRequested();
}

final class ItemsListSearchChanged extends ItemsListEvent {
  const ItemsListSearchChanged(this.query);

  final String query;
}

final class ItemsListRefreshRequested extends ItemsListEvent {
  const ItemsListRefreshRequested();
}

/// Scrolling near the end, and inline retry after loading more failed.
final class ItemsListNextPageRequested extends ItemsListEvent {
  const ItemsListNextPageRequested();
}
