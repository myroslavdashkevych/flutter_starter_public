import 'package:material_ui/material_ui.dart';

/// Every color value of the theme, as seeds. Material 3 derives the light and
/// dark variants of each role from its seed, with readable on-colors. A new
/// project replaces the values with the colors of its design.
abstract final class AppColor {
  /// Brand color: the seed of the whole `ColorScheme`.
  static const Color seed = Color(0xFF1E40AF);

  /// Seed of the success role (`AppColorExtension.success`).
  static const Color successSeed = Color(0xFF2E7D32);

  /// Seed of the warning role (`AppColorExtension.warning`).
  static const Color warningSeed = Color(0xFFF9A825);
}
