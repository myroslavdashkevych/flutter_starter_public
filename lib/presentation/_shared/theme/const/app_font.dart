/// Font families of the theme. Each name matches a `family` under
/// `flutter: fonts:` in `pubspec.yaml`. A new project replaces the files in
/// `assets/font/` and these names.
abstract final class AppFont {
  /// Body text, labels and every role without its own family.
  static const String body = 'Inter';

  /// The display, headline and title roles of the text theme.
  static const String heading = 'Lora';
}
