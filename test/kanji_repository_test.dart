import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shibu/models/settings.dart';
import 'package:shibu/services/kanji_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KanjiRepository repository;

  setUpAll(() async {
    repository = KanjiRepository(bundle: rootBundle);
    await repository.load();
  });

  group('bundled deck', () {
    test('loads a non-trivial number of entries', () {
      expect(repository.all.length, greaterThan(300));
    });

    test('ids are unique and contiguous', () {
      final ids = repository.all.map((k) => k.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids, List.generate(ids.length, (i) => i));
    });

    test('characters are unique', () {
      final characters = repository.all.map((k) => k.character).toSet();
      expect(characters.length, repository.all.length);
    });

    test('every entry has the fields the card renders', () {
      for (final kanji in repository.all) {
        expect(kanji.character, isNotEmpty, reason: 'id ${kanji.id}');
        expect(kanji.romaji, isNotEmpty, reason: kanji.character);
        expect(kanji.kana, isNotEmpty, reason: kanji.character);
        expect(kanji.meaning, isNotEmpty, reason: kanji.character);
        expect(kanji.example, isNotEmpty, reason: kanji.character);
        expect(kanji.exampleMeaning, isNotEmpty, reason: kanji.character);
      }
    });

    test('every entry is a single character', () {
      for (final kanji in repository.all) {
        expect(kanji.character.runes.length, 1, reason: kanji.character);
      }
    });

    test('levels are within the JLPT range the app offers', () {
      for (final kanji in repository.all) {
        expect(kanji.level, inInclusiveRange(1, 5), reason: kanji.character);
      }
    });

    test('the example word contains its own kanji', () {
      for (final kanji in repository.all) {
        expect(
          kanji.example.contains(kanji.character),
          isTrue,
          reason: '${kanji.character} example is ${kanji.example}',
        );
      }
    });
  });

  group('deck selection', () {
    test('filters by the selected levels', () {
      final deck = repository.deck(
        ShibuSettings.defaults.copyWith(levels: {5}),
      );
      expect(deck, isNotEmpty);
      expect(deck.every((k) => k.level == 5), isTrue);
    });

    test('falls back to the full deck when favourites are empty', () {
      final deck = repository.deck(
        ShibuSettings.defaults.copyWith(
          deck: DeckMode.favorites,
          favorites: {},
        ),
      );
      expect(deck.length, repository.all.length);
    });

    test('uses only favourites when some are set', () {
      final favorites = {1, 2, 3};
      final deck = repository.deck(
        ShibuSettings.defaults.copyWith(
          deck: DeckMode.favorites,
          favorites: favorites,
        ),
      );
      expect(deck.map((k) => k.id).toSet(), favorites);
    });

    test('current wraps around rather than overflowing', () {
      final settings = ShibuSettings.defaults.copyWith(levels: {5});
      final size = repository.deck(settings).length;
      final first = repository.current(settings);
      final wrapped = repository.current(settings.copyWith(currentIndex: size));
      expect(wrapped?.id, first?.id);
    });

    test('unshuffled order is stable', () {
      final settings = ShibuSettings.defaults.copyWith(shuffle: false);
      expect(
        repository.orderedDeck(settings).map((k) => k.id),
        repository.deck(settings).map((k) => k.id),
      );
    });
  });

  group('search', () {
    test('matches on meaning', () {
      final results = repository.search('station');
      expect(results.map((k) => k.character), contains('駅'));
    });

    test('matches on romaji', () {
      final results = repository.search('yama');
      expect(results.map((k) => k.character), contains('山'));
    });

    test('matches on the character itself', () {
      expect(repository.search('水').map((k) => k.character), contains('水'));
    });

    test('an empty query returns everything', () {
      expect(repository.search('').length, repository.all.length);
    });
  });
}
