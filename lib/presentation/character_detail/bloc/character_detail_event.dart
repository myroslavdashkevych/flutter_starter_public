sealed class CharacterDetailEvent {
  const CharacterDetailEvent();
}

/// A load of the character. Opening and retrying share one handler, so the newest
/// load replaces a running one.
sealed class CharacterDetailLoad extends CharacterDetailEvent {
  const CharacterDetailLoad(this.id);

  final int id;
}

/// The user has just opened the character: sends `select_content` (CHR-18).
final class CharacterDetailOpened extends CharacterDetailLoad {
  const CharacterDetailOpened(super.id);
}

/// A retry after a failure: sends no analytics event.
final class CharacterDetailRetried extends CharacterDetailLoad {
  const CharacterDetailRetried(super.id);
}
