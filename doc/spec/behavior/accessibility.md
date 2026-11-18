# Accessibility

Screen reader labels, tap target sizes, text contrast and large text on every screen. Applies
to SCR-1 to SCR-9; SCR-10 (Logs) is a package screen and is not covered.

## Requirements

- **ACC-1** Every interactive element on a screen has a label that a screen reader announces.
  - WHEN a screen opens THEN every tappable element has a semantic label
  - WHEN a screen reader focuses the favorite toggle THEN it announces "Add to favorites"
- **ACC-2** Every tap target is at least 48×48 dp.
  - WHEN a screen opens THEN every tappable element meets the Android (48×48) and iOS (44×44)
    minimum sizes
- **ACC-3** Text contrast meets WCAG AA in the light and the dark theme.
  - WHEN a screen opens in the light or the dark theme THEN its text meets the minimum
    contrast
- **ACC-4** At a text scale of 200% no screen overflows.
  - GIVEN a text scale of 200% WHEN a screen opens THEN no layout overflow is reported

## Implementation notes

- An icon-only button gets a `tooltip`, which is also its screen reader label (ACC-1).
- An image that repeats text shown next to it gets no label: the character image always sits
  next to the character's name (ACC-1).
- Colors come only from the theme: its `colorScheme` and its extra color roles (ACC-3). The
  on-colors of the extra roles keep a contrast of at least 4.5:1 in both themes, checked by
  `app_color_extension_test.dart`.
- A row that holds text uses `Flexible` or `Expanded` and lets the text wrap; nothing that
  holds text has a fixed height (ACC-4).

Retired: none
