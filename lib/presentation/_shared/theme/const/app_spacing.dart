/// Spacing tokens, named by role. A new project replaces the values with the
/// scale of its design.
abstract final class AppSpacing {
  /// Small gap between a message and its secondary action, or below a field
  /// that sits above a list.
  static const double inline = 8;

  /// Padding around a block of content: a page body, a form, a failure view.
  static const double content = 16;

  /// Gap between stacked items: form fields, a message and its main button.
  static const double item = 16;

  /// Space above a section title.
  static const double section = 24;

  /// Padding around an empty-state message.
  static const double emptyState = 32;
}
