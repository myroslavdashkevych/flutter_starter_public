# Design

## Status

No approved designs yet. The demo app is theme-based: every screen uses theme tokens and shared
widgets only, and every screen entry in `docs/spec/features/` says `Design: pending`.

## Tool

Not chosen yet: Figma or Claude Design. Record the choice and the links to the files here
when a project starts designing.

## Source of truth

Who owns what (spec, design, theme tokens) and what to do on a conflict:
[docs/README.md](../README.md), Source of truth. For design work:

- The theme in `lib/presentation/_shared/theme` is Material 3, `ColorScheme.fromSeed`, light
  and dark.
- A design system's tokens are mapped into the theme, never hard-coded in widgets.

## Screens

- Only approved versions are stored, as WebP at 2x, under `screens/<area>/<screen>--<state>.webp`,
  for example `screens/favorites/favorites--empty.webp`. `<screen>` and `<state>` match the
  screen entry (`SCR-n`) and its states in the spec.
- The screen entry links the file and the Figma node or Claude Design link:
  `Design: docs/design/screens/favorites/favorites--empty.webp, <link>`.
- Source files (`.fig`) are not stored in the repository.
- A screen with an approved design is implemented from its files in `screens/`.
- A screen without an approved design: [docs/README.md](../README.md), Screens
  (`Design: pending`).

## Repository size

Git LFS is not set up. When the repository passes roughly 150 MB, move `docs/design/screens/**`
to Git LFS.
