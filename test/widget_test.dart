import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shibu/models/kanji.dart';
import 'package:shibu/models/settings.dart';
import 'package:shibu/widgets/kanji_card.dart';

const Kanji _eki = Kanji(
  id: 0,
  character: '駅',
  level: 5,
  strokes: 14,
  romaji: 'eki',
  kana: 'えき',
  meaning: 'station',
  onyomi: 'エキ',
  kunyomi: '',
  example: '駅前',
  exampleKana: 'えきまえ',
  exampleRomaji: 'ekimae',
  exampleMeaning: 'in front of station',
);

Future<void> _pump(WidgetTester tester, ShibuSettings settings) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: KanjiCard(kanji: _eki, settings: settings),
        ),
      ),
    ),
  );
}

void main() {
  group('KanjiCard', () {
    testWidgets('shows character, reading, meaning and example', (
      tester,
    ) async {
      await _pump(tester, ShibuSettings.defaults);

      expect(find.text('駅'), findsOneWidget);
      expect(find.text('eki・えき'), findsOneWidget);
      expect(find.text('station'), findsOneWidget);
      expect(find.text('駅前・in front of station'), findsOneWidget);
    });

    testWidgets('hides the lines the user turned off', (tester) async {
      await _pump(
        tester,
        ShibuSettings.defaults.copyWith(showReading: false, showExample: false),
      );

      expect(find.text('駅'), findsOneWidget);
      expect(find.text('station'), findsOneWidget);
      expect(find.text('eki・えき'), findsNothing);
      expect(find.text('駅前・in front of station'), findsNothing);
    });

    testWidgets('renders the character alone when every line is off', (
      tester,
    ) async {
      await _pump(
        tester,
        ShibuSettings.defaults.copyWith(
          showReading: false,
          showMeaning: false,
          showExample: false,
        ),
      );

      expect(find.text('駅'), findsOneWidget);
      expect(find.text('station'), findsNothing);
    });

    testWidgets('font scale changes the rendered size', (tester) async {
      await _pump(tester, ShibuSettings.defaults);
      final small = tester.widget<Text>(find.text('駅')).style!.fontSize!;

      await _pump(tester, ShibuSettings.defaults.copyWith(fontScale: 1.5));
      final large = tester.widget<Text>(find.text('駅')).style!.fontSize!;

      expect(large, greaterThan(small));
      expect(large / small, closeTo(1.5, 0.001));
    });

    testWidgets('drop shadow can be turned off', (tester) async {
      await _pump(tester, ShibuSettings.defaults.copyWith(shadow: false));
      expect(tester.widget<Text>(find.text('駅')).style!.shadows, isEmpty);

      await _pump(tester, ShibuSettings.defaults.copyWith(shadow: true));
      expect(tester.widget<Text>(find.text('駅')).style!.shadows, isNotEmpty);
    });
  });

  group('ShibuSettings', () {
    test('survives a round trip through the channel format', () {
      const original = ShibuSettings.defaults;
      final restored = ShibuSettings.fromMap(original.toMap());

      expect(restored.levels, original.levels);
      expect(restored.deck, original.deck);
      expect(restored.rotationMode, original.rotationMode);
      expect(restored.intervalMinutes, original.intervalMinutes);
      expect(restored.fontScale, original.fontScale);
      expect(restored.align, original.align);
      expect(restored.textColor.toARGB32(), original.textColor.toARGB32());
      expect(restored.widgetBackground, original.widgetBackground);
    });

    test('falls back to defaults for an empty payload', () {
      final settings = ShibuSettings.fromMap(const {});
      expect(settings.levels, {5});
      expect(settings.rotationMode, RotationMode.interval);
      expect(settings.onboarded, isFalse);
    });

    test('clearWallpaperPath removes a stored photo', () {
      final withPhoto = ShibuSettings.defaults.copyWith(
        wallpaperPath: '/tmp/a.jpg',
      );
      expect(withPhoto.wallpaperPath, isNotNull);
      expect(
        withPhoto.copyWith(clearWallpaperPath: true).wallpaperPath,
        isNull,
      );
    });
  });
}
