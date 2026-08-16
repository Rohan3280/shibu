import 'dart:io';

import 'package:flutter/material.dart';

import '../models/kanji.dart';
import '../models/settings.dart';
import 'kanji_card.dart';

/// A phone-shaped preview of the lock screen.
///
/// Shows the chosen background, the clock, and the kanji card positioned by the
/// user's offset and alignment settings — so what the preview shows is what the
/// wallpaper will draw. The card is scaled down by the ratio between this
/// preview's width and a typical phone width, keeping the proportions honest.
class LockScreenPreview extends StatelessWidget {
  const LockScreenPreview({
    super.key,
    required this.kanji,
    required this.settings,
    this.showChrome = true,
    this.aspectRatio = 9 / 19.5,
  });

  final Kanji? kanji;
  final ShibuSettings settings;

  /// Draws the clock and status bar. Off for the compact widget preview.
  final bool showChrome;
  final double aspectRatio;

  /// Width in logical pixels of the phone the card was designed against.
  static const double _referenceWidth = 411;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / _referenceWidth;
          return ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Background(settings: settings),
                if (showChrome) _Clock(scale: scale),
                if (kanji != null)
                  Positioned(
                    left: constraints.maxWidth * settings.offsetX,
                    right: constraints.maxWidth * settings.offsetX,
                    top: constraints.maxHeight * settings.offsetY,
                    child: FractionalTranslation(
                      translation: const Offset(0, -0.5),
                      child: Align(
                        alignment: _alignment,
                        child: KanjiCard(
                          kanji: kanji!,
                          settings: settings,
                          scaleOverride: scale,
                        ),
                      ),
                    ),
                  ),
                _Border(),
              ],
            ),
          );
        },
      ),
    );
  }

  Alignment get _alignment => switch (settings.align) {
    CardAlign.left => Alignment.centerLeft,
    CardAlign.center => Alignment.center,
    CardAlign.right => Alignment.centerRight,
  };
}

class _Background extends StatelessWidget {
  const _Background({required this.settings});

  final ShibuSettings settings;

  @override
  Widget build(BuildContext context) {
    final path = settings.wallpaperPath;
    final hasImage = path != null && File(path).existsSync();

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage)
          Image.file(
            File(path),
            fit: BoxFit.cover,
            // The file is overwritten in place when the user picks a new photo,
            // so the decoded image must not be served from cache.
            key: ValueKey(File(path).lastModifiedSync()),
            errorBuilder: (_, _, _) =>
                ColoredBox(color: settings.wallpaperColor),
          )
        else
          _DefaultBackdrop(color: settings.wallpaperColor),
        if (settings.wallpaperDim > 0)
          ColoredBox(
            color: Colors.black.withValues(alpha: settings.wallpaperDim),
          ),
      ],
    );
  }
}

/// Stand-in backdrop shown before the user picks a photo.
class _DefaultBackdrop extends StatelessWidget {
  const _DefaultBackdrop({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(color, Colors.white, 0.16)!,
          color,
          Color.lerp(color, Colors.black, 0.35)!,
        ],
      ),
    ),
  );
}

class _Clock extends StatelessWidget {
  const _Clock({required this.scale});

  final double scale;

  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');

    return Padding(
      padding: EdgeInsets.only(top: 56 * scale),
      child: Column(
        children: [
          Text(
            '${_days[now.weekday - 1]} ${_months[now.month - 1]} ${now.day}',
            style: TextStyle(
              fontSize: 15 * scale,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: _shadow(scale),
            ),
          ),
          Text(
            '$hour:$minute',
            style: TextStyle(
              fontSize: 76 * scale,
              fontWeight: FontWeight.w400,
              height: 1.1,
              color: Colors.white,
              shadows: _shadow(scale),
            ),
          ),
        ],
      ),
    );
  }

  static List<Shadow> _shadow(double scale) => [
    Shadow(
      blurRadius: 10 * scale,
      offset: Offset(0, 2 * scale),
      color: Colors.black.withValues(alpha: 0.35),
    ),
  ];
}

/// Subtle inner hairline so the preview reads as a device.
class _Border extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1,
        ),
      ),
    ),
  );
}
