package com.shibu.app.data

/**
 * A shuffle that produces byte-identical results in Kotlin and in Dart.
 *
 * The in-app preview and the live wallpaper must walk the deck in exactly the
 * same order, otherwise the app would advertise a different kanji from the one
 * actually on the lock screen. Neither `java.util.Random` nor Dart's `Random`
 * can be relied on for that — they are different algorithms — so both sides
 * implement this same xorshift32 generator and the same Fisher-Yates walk.
 *
 * The Dart twin lives at `lib/services/deck_order.dart`; the two must be
 * changed together.
 */
object DeckOrder {

    /** Must match `DeckOrder.defaultSeed` in the Dart sources. */
    const val DEFAULT_SEED = 20240623

    /** Returns a new list shuffled deterministically from [seed]. */
    fun <T> shuffled(source: List<T>, seed: Int = DEFAULT_SEED): List<T> {
        val result = ArrayList(source)
        val random = Xorshift32(seed)
        for (i in result.size - 1 downTo 1) {
            val j = (random.next() % (i + 1)).toInt()
            val tmp = result[i]
            result[i] = result[j]
            result[j] = tmp
        }
        return result
    }

    /**
     * 32-bit xorshift. Chosen because it is trivial to reimplement identically
     * in any language, not for statistical quality — this only orders a
     * flashcard deck.
     */
    private class Xorshift32(seed: Int) {
        private var state: Int = if (seed == 0) 1 else seed

        /** The next value in the range 0 .. 2^32-1. */
        fun next(): Long {
            var x = state
            x = x xor (x shl 13)
            x = x xor (x ushr 17)
            x = x xor (x shl 5)
            state = x
            return x.toLong() and 0xFFFFFFFFL
        }
    }
}
