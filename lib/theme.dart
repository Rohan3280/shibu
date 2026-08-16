import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shibu's visual language: deep indigo ground, sakura accent, generous
/// spacing. Dark first, because the app is mostly used to preview a lock
/// screen.
abstract final class ShibuTheme {
  static const Color indigo = Color(0xFF2A3566);
  static const Color sakura = Color(0xFFE87BA4);
  static const Color fujiBlue = Color(0xFF505E97);
  static const Color ink = Color(0xFF0E1220);
  static const Color surface = Color(0xFF161B2E);
  static const Color surfaceHigh = Color(0xFF1E2438);

  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: indigo,
          brightness: Brightness.dark,
        ).copyWith(
          primary: sakura,
          onPrimary: const Color(0xFF3A0E20),
          secondary: fujiBlue,
          surface: surface,
          surfaceContainerHighest: surfaceHigh,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ink,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: Colors.white,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        space: 1,
        thickness: 1,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(
            BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: sakura.withValues(alpha: 0.18),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: sakura,
        thumbColor: sakura,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
        overlayColor: sakura.withValues(alpha: 0.16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceHigh,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  /// Muted label used above grouped settings.
  static TextStyle sectionLabel(BuildContext context) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
    color: Colors.white.withValues(alpha: 0.44),
  );
}
