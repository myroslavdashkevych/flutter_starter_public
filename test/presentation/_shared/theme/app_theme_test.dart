import 'package:flutter_starter/presentation/_shared/theme/app_color_extension.dart';
import 'package:flutter_starter/presentation/_shared/theme/app_theme.dart';
import 'package:flutter_starter/presentation/_shared/theme/const/app_color.dart';
import 'package:flutter_starter/presentation/_shared/theme/const/app_font.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    group('${theme.brightness.name} theme', () {
      test('builds the color scheme from the brand seed', () {
        final expected = ColorScheme.fromSeed(
          seedColor: AppColor.seed,
          brightness: theme.brightness,
        );
        expect(theme.colorScheme.primary, expected.primary);
        expect(theme.colorScheme.surface, expected.surface);
      });

      test('uses the heading font for display, headline and title', () {
        final textTheme = theme.textTheme;
        final headings = [
          textTheme.displayLarge,
          textTheme.displayMedium,
          textTheme.displaySmall,
          textTheme.headlineLarge,
          textTheme.headlineMedium,
          textTheme.headlineSmall,
          textTheme.titleLarge,
          textTheme.titleMedium,
          textTheme.titleSmall,
        ];
        for (final style in headings) {
          expect(style?.fontFamily, AppFont.heading);
        }
      });

      test('uses the body font for body and label', () {
        final textTheme = theme.textTheme;
        final bodies = [
          textTheme.bodyLarge,
          textTheme.bodyMedium,
          textTheme.bodySmall,
          textTheme.labelLarge,
          textTheme.labelMedium,
          textTheme.labelSmall,
        ];
        for (final style in bodies) {
          expect(style?.fontFamily, AppFont.body);
        }
      });

      test('registers the extra color roles of its brightness', () {
        final expected = AppColorExtension.of(theme.brightness);
        expect(theme.appColor.success, expected.success);
        expect(theme.appColor.warning, expected.warning);
      });
    });
  }
}
