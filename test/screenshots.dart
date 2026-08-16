import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shibu/main.dart';
import 'package:shibu/models/settings.dart';
import 'package:shibu/screens/browse_screen.dart';
import 'package:shibu/screens/home_shell.dart';
import 'package:shibu/screens/onboarding_screen.dart';
import 'package:shibu/screens/settings_screen.dart';
import 'package:shibu/screens/style_screen.dart';
import 'package:shibu/screens/today_screen.dart';
import 'package:shibu/services/kanji_repository.dart';
import 'package:shibu/services/settings_controller.dart';
import 'package:shibu/services/shibu_bridge.dart';
import 'package:shibu/theme.dart';

/// Renders the real screens to PNGs for the README.
///
/// This is not a test — nothing here asserts anything about behaviour. It uses
/// the widget tester purely as a renderer, because a screenshot produced from
/// the actual widget tree stays honest as the UI changes, and does not need a
/// device attached. Regenerate with:
///
///     flutter test --update-goldens test/screenshots.dart
///
/// The filename deliberately lacks the `_test` suffix, so `flutter test` does
/// not pick it up on a normal run — its output depends on which fonts the host
/// has installed.
void main() {
  const size = Size(411, 890);

  setUpAll(() async {
    await _loadHostFonts();
  });

  Future<void> capture(
    WidgetTester tester,
    String name,
    Widget Function(SettingsController) build, {
    ShibuSettings? settings,
    // Individual screens are normally hosted in HomeShell's Scaffold, and
    // Material widgets such as TextField require it. HomeShell brings its own.
    bool wrapInScaffold = true,
  }) async {
    // 2x is a deliberate ceiling. flutter_tester rasterises in software, and a
    // 3x full-screen surface takes long enough to look like a hang.
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // runAsync is required: loading the deck from the asset bundle is real
    // asynchronous I/O, and awaiting it directly inside testWidgets deadlocks
    // against the fake clock, which never advances on its own.
    final controller = (await tester.runAsync(
      () => _controller(settings ?? _demoSettings),
    ))!;

    await tester.pumpWidget(
      ShibuScope(
        controller: controller,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme,
          home: wrapInScaffold
              ? Scaffold(body: build(controller))
              : build(controller),
        ),
      ),
    );
    // Fixed pumps rather than pumpAndSettle: the theme's ink splash and the
    // navigation bar keep a ticker alive, so "settled" never arrives and the
    // renderer would sit there until the 10 minute default timeout.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/$name.png'),
    );
    debugPrint('[shot] wrote $name.png');
  }

  testWidgets(
    'today',
    (t) => capture(t, '01-today', (_) => const TodayScreen()),
    timeout: const Timeout(Duration(seconds: 90)),
  );

  testWidgets(
    'browse',
    (t) => capture(t, '02-browse', (_) => const BrowseScreen()),
  );

  testWidgets(
    'style',
    (t) => capture(t, '03-style', (_) => const StyleScreen()),
  );

  testWidgets(
    'settings',
    (t) => capture(t, '04-settings', (_) => const SettingsScreen()),
  );

  testWidgets(
    'onboarding',
    (t) => capture(
      t,
      '05-onboarding',
      (_) => const OnboardingScreen(),
      settings: _demoSettings.copyWith(onboarded: false),
    ),
  );

  testWidgets(
    'shell',
    (t) =>
        capture(t, '06-shell', (_) => const HomeShell(), wrapInScaffold: false),
  );
}

/// Settings chosen to show the card off rather than the bare defaults.
final ShibuSettings _demoSettings = ShibuSettings.defaults.copyWith(
  levels: {5, 4},
  favorites: {12, 34, 56},
  learned: {1, 2, 3, 4, 5, 6, 7},
  onboarded: true,
  wallpaperDim: 0.22,
);

/// Builds a controller backed by a stub channel, so no native side is needed.
Future<SettingsController> _controller(ShibuSettings settings) async {
  const channel = MethodChannel('com.shibu.app/bridge');
  var current = settings;
  var index = 3;

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'readSettings':
            return current.toMap();
          case 'applySettings':
            current = ShibuSettings.fromMap(
              call.arguments as Map<dynamic, dynamic>,
            );
            return current.toMap();
          case 'currentKanjiId':
            return index;
          case 'nextKanji':
            return ++index;
          case 'previousKanji':
            return --index;
          case 'isWallpaperActive':
            return true;
          case 'widgetCount':
            return 1;
          default:
            return null;
        }
      });

  final controller = SettingsController(
    repository: KanjiRepository(),
    bridge: ShibuBridge(channel: channel),
  );
  await controller.load();
  return controller;
}

/// The app theme with concrete font families, since the test environment has no
/// Roboto and no CJK fallback of its own.
///
/// The component themes need naming individually: a `TextStyle` set on a button
/// theme does not inherit the family from `textTheme`, so button labels would
/// otherwise render as placeholder boxes.
ThemeData get _screenshotTheme {
  final base = ShibuTheme.dark;

  TextStyle named([double size = 15, FontWeight weight = FontWeight.w600]) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        fontFamily: _sans,
        fontFamilyFallback: const [_cjk],
      );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: _sans,
      fontFamilyFallback: const [_cjk],
    ),
    primaryTextTheme: base.primaryTextTheme.apply(
      fontFamily: _sans,
      fontFamilyFallback: const [_cjk],
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(named(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(named(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: named(15)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: base.segmentedButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(named(14, FontWeight.w500)),
      ),
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      labelTextStyle: WidgetStatePropertyAll(named(12, FontWeight.w600)),
    ),
    chipTheme: base.chipTheme.copyWith(labelStyle: named(13, FontWeight.w500)),
  );
}

const String _sans = 'ScreenshotSans';
const String _cjk = 'ScreenshotCJK';

/// Registers host fonts so kanji render as glyphs rather than tofu.
Future<void> _loadHostFonts() async {
  const latin = [
    r'C:\Windows\Fonts\segoeui.ttf',
    '/System/Library/Fonts/SFNS.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  ];
  const cjk = [
    r'C:\Windows\Fonts\YuGothM.ttc',
    r'C:\Windows\Fonts\msgothic.ttc',
    '/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc',
    '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
  ];

  await _load(_sans, latin);
  await _load(_cjk, cjk);

  // Without this every Icon renders as an empty box: flutter_test does not
  // register the icon font by default.
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    await _load('MaterialIcons', [
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
  }
}

Future<void> _load(String family, List<String> candidates) async {
  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final loader = FontLoader(family)
      ..addFont(file.readAsBytes().then((b) => ByteData.view(b.buffer)));
    await loader.load();
    return;
  }
  // ignore: avoid_print
  print(
    'No font found for "$family"; screenshots will show placeholder boxes.',
  );
}
