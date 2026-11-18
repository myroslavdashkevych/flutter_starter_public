import 'package:injectable/injectable.dart';

/// The current time (doc/spec/architecture.md, Time).
@lazySingleton
class Clock {
  Clock() : _now = DateTime.timestamp;

  /// For tests: a clock that reads the time from [now], so a test sets and
  /// moves it.
  Clock.from(DateTime Function() now) : _now = now;

  final DateTime Function() _now;

  /// The current time in UTC.
  DateTime now() => _now();
}
