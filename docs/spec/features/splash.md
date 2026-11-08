# Native splash

Configuration and regeneration: [guides/setup.md](../../guides/setup.md), Native splash.

## Requirements

- **SPL-1** The operating system shows the logo centered on the theme's `surface` color until
  Flutter draws its first frame, so a cold start has no white frame.
  - WHEN the app cold-starts THEN the logo on the `surface` color is shown until the first frame
- **SPL-2** Logo and background follow the **system** theme, not the theme chosen in Settings.
  With an explicit theme that differs from the system one, the background changes when the
  first app screen appears.
  - GIVEN the device is in light mode and the app theme is Dark WHEN the app starts THEN the
    splash is light and the background turns dark with the first screen
- **SPL-3** Android 12+ shows the logo through the system splash API, which clips it to a circle.
  - GIVEN Android 12 or later WHEN the app starts THEN the logo is shown clipped to a circle

A launch from a notification on Android may show the splash without the logo (NTF-8).

## Implementation notes

- SPL-2: a native splash is shown before any Dart code runs, so it cannot read the Settings
  preference.

Manual: SPL-1, SPL-2, SPL-3

Retired: none
