/// A shuffle that produces byte-identical results in Dart and in Kotlin.
///
/// The in-app preview and the live wallpaper must walk the deck in exactly the
/// same order, otherwise the app would advertise a different kanji from the one
/// actually on the lock screen. Neither `dart:math`'s `Random` nor Java's
/// `java.util.Random` can be relied on for that — they are different
/// algorithms — so both sides implement this same xorshift32 generator and the
/// same Fisher–Yates walk.
///
/// The Kotlin twin lives at
/// `android/app/src/main/kotlin/com/shibu/app/data/DeckOrder.kt`; the two must
/// be changed together.
library;

class DeckOrder {
  const DeckOrder._();

  /// Must match `DeckOrder.DEFAULT_SEED` in the Kotlin sources.
  static const int defaultSeed = 20240623;

  /// Returns a new list shuffled deterministically from [seed].
  static List<T> shuffled<T>(List<T> source, [int seed = defaultSeed]) {
    final result = List<T>.of(source);
    final random = _Xorshift32(seed);
    for (var i = result.length - 1; i > 0; i--) {
      final j = random.next() % (i + 1);
      final tmp = result[i];
      result[i] = result[j];
      result[j] = tmp;
    }
    return result;
  }
}

/// 32-bit xorshift. Chosen because it is trivial to reimplement identically in
/// any language, not for statistical quality — this only orders a flashcard
/// deck.
class _Xorshift32 {
  _Xorshift32(int seed) : _state = (seed & _mask) == 0 ? 1 : seed & _mask;

  static const int _mask = 0xFFFFFFFF;

  int _state;

  /// The next value in the range 0 .. 2^32-1.
  int next() {
    var x = _state;
    x ^= (x << 13) & _mask;
    // _state is always masked to 32 bits and therefore non-negative, so an
    // arithmetic shift here is the same as a logical one.
    x ^= x >> 17;
    x ^= (x << 5) & _mask;
    _state = x & _mask;
    return _state;
  }
}
