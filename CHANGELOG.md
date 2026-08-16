# Changelog

All notable changes to Shibu are recorded here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/Rohan3280/shibu/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Rohan3280/shibu/releases/tag/v1.0.0
