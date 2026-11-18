import 'package:flutter_starter/presentation/_shared/theme/app_color_extension.dart';
import 'package:flutter_starter/presentation/_shared/theme/const/app_color.dart';
import 'package:flutter_starter/presentation/_shared/theme/const/app_font.dart';
import 'package:material_ui/material_ui.dart';

abstract final class AppTheme {
  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColor.seed,
        brightness: brightness,
      ),
      fontFamily: AppFont.body,
      extensions: [AppColorExtension.of(brightness)],
    );
    return theme.copyWith(textTheme: _withHeadingFont(theme.textTheme));
  }

  static TextTheme _withHeadingFont(TextTheme textTheme) {
    TextStyle? heading(TextStyle? style) =>
        style?.copyWith(fontFamily: AppFont.heading);

    return textTheme.copyWith(
      displayLarge: heading(textTheme.displayLarge),
      displayMedium: heading(textTheme.displayMedium),
      displaySmall: heading(textTheme.displaySmall),
      headlineLarge: heading(textTheme.headlineLarge),
      headlineMedium: heading(textTheme.headlineMedium),
      headlineSmall: heading(textTheme.headlineSmall),
      titleLarge: heading(textTheme.titleLarge),
      titleMedium: heading(textTheme.titleMedium),
      titleSmall: heading(textTheme.titleSmall),
    );
  }
}
