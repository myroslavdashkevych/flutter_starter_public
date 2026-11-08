import 'package:flutter_starter/app/config/flavor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps known names', () {
    expect(Flavor.fromName('dev'), Flavor.dev);
    expect(Flavor.fromName('prod'), Flavor.prod);
  });

  test('SET-7: usage data is always collected in dev', () {
    expect(Flavor.dev.collectsUsageData(isDebug: true), isTrue);
    expect(Flavor.dev.collectsUsageData(isDebug: false), isTrue);
  });

  test('SET-7: usage data is collected in prod only outside debug builds', () {
    expect(Flavor.prod.collectsUsageData(isDebug: true), isFalse);
    expect(Flavor.prod.collectsUsageData(isDebug: false), isTrue);
  });

  test('throws on a missing or unknown name', () {
    expect(() => Flavor.fromName(null), throwsStateError);
    expect(() => Flavor.fromName('staging'), throwsStateError);
  });
}
