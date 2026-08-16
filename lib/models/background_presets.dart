import 'package:flutter/material.dart';

/// Built-in gradient backdrops, so the wallpaper looks deliberate before the
/// user picks a photo of their own.
///
/// Every preset is dark enough for white card text at the default dim level;
/// that is the whole selection criterion. The Kotlin twin lives at
/// `android/app/src/main/kotlin/com/shibu/app/data/BackgroundPresets.kt` and
/// must be kept in step — that one draws the real wallpaper, this one draws
/// the preview.
@immutable
class BackgroundPreset {
  const BackgroundPreset({
    required this.id,
    required this.label,
    required this.colors,
  });

  final String id;
  final String label;

  /// Vertical gradient stops, top to bottom.
  final List<Color> colors;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: colors,
  );
}

abstract final class BackgroundPresets {
  static const String defaultId = 'midnight';

  static const List<BackgroundPreset> all = [
    BackgroundPreset(
      id: 'midnight',
      label: 'Midnight',
      colors: [Color(0xFF1E2A3A), Color(0xFF0A0E14)],
    ),
    BackgroundPreset(
      id: 'fuji',
      label: 'Fuji',
      colors: [Color(0xFF4A5891), Color(0xFF1B2140)],
    ),
    BackgroundPreset(
      id: 'sumi',
      label: 'Sumi ink',
      colors: [Color(0xFF33333A), Color(0xFF0F0F12)],
    ),
    BackgroundPreset(
      id: 'sakura',
      label: 'Sakura night',
      colors: [Color(0xFF7A4560), Color(0xFF241320)],
    ),
    BackgroundPreset(
      id: 'matcha',
      label: 'Matcha',
      colors: [Color(0xFF2F5D50), Color(0xFF0E201B)],
    ),
    BackgroundPreset(
      id: 'dusk',
      label: 'Dusk',
      colors: [Color(0xFF6B4470), Color(0xFF1E1630)],
    ),
    BackgroundPreset(
      id: 'ocean',
      label: 'Deep water',
      colors: [Color(0xFF1E4F6B), Color(0xFF081720)],
    ),
  ];

  static BackgroundPreset byId(String? id) => all.firstWhere(
    (p) => p.id == id,
    orElse: () => all.firstWhere((p) => p.id == defaultId),
  );
}
