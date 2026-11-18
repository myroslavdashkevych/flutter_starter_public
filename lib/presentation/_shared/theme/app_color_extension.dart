import 'package:flutter_starter/presentation/_shared/theme/const/app_color.dart';
import 'package:material_ui/material_ui.dart';

/// Color roles that `ColorScheme` does not have, for one brightness.
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  const AppColorExtension({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
  });

  /// Derives each role from its seed in [AppColor] the way Material 3 derives
  /// `primary` and `onPrimary`, so the pair stays readable in both themes.
  factory AppColorExtension.of(Brightness brightness) {
    final success = ColorScheme.fromSeed(
      seedColor: AppColor.successSeed,
      brightness: brightness,
    );
    final warning = ColorScheme.fromSeed(
      seedColor: AppColor.warningSeed,
      brightness: brightness,
    );
    return AppColorExtension(
      success: success.primary,
      onSuccess: success.onPrimary,
      warning: warning.primary,
      onWarning: warning.onPrimary,
    );
  }

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;

  @override
  AppColorExtension copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
  }) => AppColorExtension(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
  );

  @override
  AppColorExtension lerp(AppColorExtension? other, double t) {
    if (other == null) return this;
    return AppColorExtension(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
    );
  }
}

/// Reads [AppColorExtension] from a theme built by `AppTheme`.
extension AppColorTheme on ThemeData {
  // AppTheme registers the extension in every theme it builds.
  AppColorExtension get appColor => extension<AppColorExtension>()!;
}
