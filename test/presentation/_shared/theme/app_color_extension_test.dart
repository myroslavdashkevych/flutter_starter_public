import 'package:flutter_starter/presentation/_shared/theme/app_color_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final light = AppColorExtension.of(Brightness.light);
  final dark = AppColorExtension.of(Brightness.dark);

  for (final colors in [light, dark]) {
    final name = identical(colors, light) ? 'light' : 'dark';

    test('$name: on-colors meet WCAG AA contrast', () {
      expect(
        _contrast(colors.success, colors.onSuccess),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(colors.warning, colors.onWarning),
        greaterThanOrEqualTo(4.5),
      );
    });
  }

  test('light and dark variants differ', () {
    expect(light.success, isNot(dark.success));
    expect(light.warning, isNot(dark.warning));
  });

  test('copyWith replaces only the given colors', () {
    const red = Color(0xFFFF0000);
    final copy = light.copyWith(success: red);

    expect(copy.success, red);
    expect(copy.onSuccess, light.onSuccess);
    expect(copy.warning, light.warning);
    expect(copy.onWarning, light.onWarning);
  });

  test('lerp returns the ends at 0 and 1', () {
    final start = light.lerp(dark, 0);
    final end = light.lerp(dark, 1);

    expect(start.success, light.success);
    expect(start.onWarning, light.onWarning);
    expect(end.success, dark.success);
    expect(end.onWarning, dark.onWarning);
  });

  test('lerp with no other keeps the colors', () {
    expect(light.lerp(null, 0.5), same(light));
  });
}

/// WCAG contrast ratio of two colors.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
