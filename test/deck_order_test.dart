import 'package:flutter_test/flutter_test.dart';
import 'package:shibu/services/deck_order.dart';

void main() {
  group('DeckOrder', () {
    test('is deterministic for a given seed', () {
      final source = List.generate(50, (i) => i);
      expect(DeckOrder.shuffled(source, 99), DeckOrder.shuffled(source, 99));
    });

    test('different seeds give different orders', () {
      final source = List.generate(50, (i) => i);
      expect(
        DeckOrder.shuffled(source, 1),
        isNot(equals(DeckOrder.shuffled(source, 2))),
      );
    });

    test('is a permutation, losing and duplicating nothing', () {
      final source = List.generate(419, (i) => i);
      final shuffled = DeckOrder.shuffled(source);
      expect(shuffled.length, source.length);
      expect(shuffled.toSet(), source.toSet());
    });

    test('leaves the source list untouched', () {
      final source = List.generate(10, (i) => i);
      DeckOrder.shuffled(source);
      expect(source, List.generate(10, (i) => i));
    });

    test('handles empty and single-element decks', () {
      expect(DeckOrder.shuffled(<int>[]), isEmpty);
      expect(DeckOrder.shuffled(<int>[7]), [7]);
    });

    // Goldens produced on the JVM by tool/verify_deck_order/VerifyDeckOrder.java,
    // which mirrors DeckOrder.kt operator for operator. If any of these fail,
    // the lock screen and the in-app preview have drifted apart and both
    // implementations must be reconciled. Regenerate with:
    //   java tool/verify_deck_order/VerifyDeckOrder.java
    group('agrees with the JVM implementation', () {
      test('default seed, ten entries', () {
        expect(DeckOrder.shuffled(List.generate(10, (i) => i)), const [
          0,
          9,
          2,
          4,
          3,
          6,
          8,
          1,
          5,
          7,
        ]);
      });

      test('seed 1, ten entries', () {
        expect(DeckOrder.shuffled(List.generate(10, (i) => i), 1), const [
          3,
          1,
          0,
          2,
          6,
          7,
          8,
          5,
          4,
          9,
        ]);
      });

      test('default seed, twenty entries', () {
        expect(DeckOrder.shuffled(List.generate(20, (i) => i)), const [
          9,
          17,
          11,
          1,
          0,
          4,
          18,
          6,
          14,
          2,
          10,
          15,
          13,
          16,
          8,
          3,
          19,
          5,
          12,
          7,
        ]);
      });
    });
  });
}
