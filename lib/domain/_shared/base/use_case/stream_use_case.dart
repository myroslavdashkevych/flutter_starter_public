/// A use case that emits values over time. It never emits an error.
///
/// [P] is always a record, `()` when the use case takes no parameters
/// (doc/spec/architecture.md, Use cases).
abstract interface class StreamUseCase<T, P> {
  Stream<T> call(P params);
}
