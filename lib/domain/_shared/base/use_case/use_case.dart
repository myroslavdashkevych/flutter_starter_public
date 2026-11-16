import 'package:flutter_starter/domain/_shared/wrapper/result/result.dart';

/// A use case that completes once. It never throws: a failure is an [Err].
///
/// [P] is always a record, `()` when the use case takes no parameters
/// (doc/spec/architecture.md, Use cases).
abstract interface class UseCase<T, P> {
  Future<Result<T>> call(P params);
}
