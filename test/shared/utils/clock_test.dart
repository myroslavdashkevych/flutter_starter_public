import 'package:flutter_starter/shared/utils/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('now() is the current time in UTC', () {
    final before = DateTime.now();

    final now = Clock().now();

    expect(now.isUtc, isTrue);
    expect(now.isBefore(before), isFalse);
    expect(now.isAfter(DateTime.now()), isFalse);
  });

  test('Clock.from returns the time of its function', () {
    var time = DateTime.utc(2026, 11, 17, 12);
    final clock = Clock.from(() => time);

    expect(clock.now(), DateTime.utc(2026, 11, 17, 12));

    time = time.add(const Duration(minutes: 1));

    expect(clock.now(), DateTime.utc(2026, 11, 17, 12, 1));
  });
}
