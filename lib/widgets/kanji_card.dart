import 'package:flutter/material.dart';

import '../models/kanji.dart';
import '../models/settings.dart';

/// The kanji card, exactly as the wallpaper and widget draw it.
///
///     駅   eki・えき
///          station
///          駅前・in front of station
///
/// This is a faithful Flutter port of `CardRenderer.kt`. The two are separate
/// implementations of one design, so the sizes below intentionally mirror the
/// `*_SP` and `*_DP` constants there — change them together.
class KanjiCard extends StatelessWidget {
  const KanjiCard({
    super.key,
    required this.kanji,
    required this.settings,
    this.scaleOverride,
  });

  final Kanji kanji;
  final ShibuSettings settings;

  /// Shrinks the whole card for previews that are smaller than a real screen.
  final double? scaleOverride;

  // Mirrors CardRenderer.KANJI_SP and friends.
  static const double _kanjiSp = 46;
  static const double _readingSp = 13;
  static const double _meaningSp = 17;
  static const double _exampleSp = 12;
  static const double _columnGap = 14;
  static const double _lineGap = 2;

  @override
  Widget build(BuildContext context) {
    final scale = (scaleOverride ?? 1.0) * settings.fontScale;
    final primary = settings.textColor;
    final secondary = primary.withValues(alpha: primary.a * 0.86);

    final shadows = settings.shadow
        ? <Shadow>[
            Shadow(
              blurRadius: 8 * scale,
              offset: Offset(0, 1.5 * scale),
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ]
        : const <Shadow>[];

    final lines = <Widget>[
      if (settings.showReading)
        _line(
          kanji.readingLine,
          _readingSp * scale,
          FontWeight.w500,
          secondary,
          shadows,
        ),
      if (settings.showMeaning)
        _line(
          kanji.meaning,
          _meaningSp * scale,
          FontWeight.w700,
          primary,
          shadows,
        ),
      if (settings.showExample)
        _line(
          kanji.exampleLine,
          _exampleSp * scale,
          FontWeight.w400,
          secondary,
          shadows,
        ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          kanji.character,
          style: TextStyle(
            fontSize: _kanjiSp * scale,
            height: 1.0,
            color: primary,
            shadows: shadows,
          ),
        ),
        if (lines.isNotEmpty) ...[
          SizedBox(width: _columnGap * scale),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: _crossAxis,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) SizedBox(height: _lineGap * scale),
                  lines[i],
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  CrossAxisAlignment get _crossAxis => switch (settings.align) {
    CardAlign.left => CrossAxisAlignment.start,
    CardAlign.center => CrossAxisAlignment.center,
    CardAlign.right => CrossAxisAlignment.end,
  };

  TextAlign get _textAlign => switch (settings.align) {
    CardAlign.left => TextAlign.start,
    CardAlign.center => TextAlign.center,
    CardAlign.right => TextAlign.end,
  };

  Widget _line(
    String text,
    double size,
    FontWeight weight,
    Color color,
    List<Shadow> shadows,
  ) => Text(
    text,
    textAlign: _textAlign,
    style: TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.22,
      shadows: shadows,
    ),
  );
}
