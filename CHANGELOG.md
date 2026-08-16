# Changelog

All notable changes to Shibu are recorded here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] — 2026-08-16

### Fixed

- **No setting was ever saved.** Every write over the platform channel was
  rejected and silently discarded, so the app showed changes it had not
  persisted and the wallpaper never picked them up. `Color.toARGB32()` returns
  values above 2^31 for any opaque colour, the standard message codec promotes
  those to Int64, and the Kotlin side read them as Int — the resulting
  `ClassCastException` aborted the whole write before the first field landed.
  Colours now travel as signed 32-bit, the native side accepts any `Number`,
  and a failed write re-reads instead of echoing back what the caller asked
  for, so a rejection can never look like a success again.

### Added

- **Animated backdrops.** GIF and animated WebP are supported on Android 9+,
  drawn straight from `AnimatedImageDrawable`. Frames are capped at ~20fps and
  only drawn while the wallpaper is visible, and there is a switch to hold an
  animated file on its first frame.
- **Seven built-in gradient backdrops** — Midnight, Fuji, Sumi ink, Sakura
  night, Matcha, Dusk and Deep water — so the wallpaper looks deliberate
  without picking a photo.
- **A warning when Shibu is not your wallpaper**, naming the app that holds the
  slot. Every control on the Style screen affects the Shibu wallpaper, and
  without this the settings appeared to do nothing at all.

### Changed

- The background picker is now `ACTION_OPEN_DOCUMENT` rather than
  `image_picker`, which re-encoded files and flattened animated GIFs to a
  single frame. This also drops the app's last third-party dependency.

## [1.0.0] — 2026-08-16

First public release.

### Added

- **Live wallpaper** that draws the current kanji card over your chosen photo,
  covering both the lock screen and the home screen. This is how Shibu reaches
  the lock screen at all, since Android phones have no third-party lock screen
  widget API.
- **Home screen widget** rendered by the same `CardRenderer` as the wallpaper,
  so the two surfaces cannot look different. Resizable, with transparent, scrim
  or solid backgrounds.
- **419 kanji** bundled in the APK — 80 at JLPT N5, 166 at N4, 173 at N3 — each
  with romaji and kana readings, an English meaning, on'yomi and kun'yomi, and
  an example compound with its own reading and meaning.
- **Rotation modes**: a new kanji on every unlock (requires the wallpaper), or
  on a timer from 15 minutes to once a day.
- **Deterministic shuffle** implemented identically in Dart and Kotlin, so the
  in-app preview always agrees with what is actually on the lock screen.
- **Card styling**: text colour, size, alignment, vertical and horizontal
  position, drop shadow, and independent toggles for the reading, meaning and
  example lines.
- **Background photo** picker with adjustable dimming. The image is copied into
  app-private storage so it survives changes in your gallery.
- **Browse** screen with search across characters, readings and meanings,
  filters by level and favourites, and a detail sheet that can pin any kanji to
  your lock screen immediately.
- **Progress**: favourites, kanji marked learned, and a favourites-only deck.
- **Onboarding** covering level choice, rotation rhythm, and turning the two
  surfaces on.

### Notes

- Requires Android 7.0 (API 24) or newer.
- Shibu declares no internet permission and works entirely offline.

[Unreleased]: https://github.com/Rohan3280/shibu/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/Rohan3280/shibu/releases/tag/v1.0.1
[1.0.0]: https://github.com/Rohan3280/shibu/releases/tag/v1.0.0
