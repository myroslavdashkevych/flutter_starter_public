sealed class CharacterListEvent {
  const CharacterListEvent();
}

/// First load, and retry after it failed.
final class CharacterListLoadRequested extends CharacterListEvent {
  const CharacterListLoadRequested();
}

final class CharacterListSearchChanged extends CharacterListEvent {
  const CharacterListSearchChanged(this.query);

  final String query;
}

final class CharacterListRefreshRequested extends CharacterListEvent {
  const CharacterListRefreshRequested();
}

/// Scrolling near the end, and inline retry after loading more failed.
final class CharacterListNextPageRequested extends CharacterListEvent {
  const CharacterListNextPageRequested();
}
