import java.util.ArrayList;
import java.util.List;

/**
 * Prints the deck order the JVM side produces, so the Dart golden test can
 * assert against it.
 *
 * This mirrors DeckOrder.kt operator for operator. Kotlin's `Int`, `shl`,
 * `ushr` and `xor` compile to exactly the Java `int`, `<<`, `>>>` and `^` used
 * here, so agreement with this file is agreement with the Kotlin sources.
 *
 * Run with:  java tool/verify_deck_order/VerifyDeckOrder.java
 */
public final class VerifyDeckOrder {

    private static final int DEFAULT_SEED = 20240623;

    public static void main(String[] args) {
        System.out.println("seed " + DEFAULT_SEED + ", 0..9  -> " + shuffled(10, DEFAULT_SEED));
        System.out.println("seed 1, 0..9           -> " + shuffled(10, 1));
        System.out.println("seed " + DEFAULT_SEED + ", 0..19 -> " + shuffled(20, DEFAULT_SEED));
    }

    private static List<Integer> shuffled(int size, int seed) {
        List<Integer> result = new ArrayList<>();
        for (int i = 0; i < size; i++) result.add(i);

        Xorshift32 random = new Xorshift32(seed);
        for (int i = result.size() - 1; i > 0; i--) {
            int j = (int) (random.next() % (i + 1));
            Integer tmp = result.get(i);
            result.set(i, result.get(j));
            result.set(j, tmp);
        }
        return result;
    }

    private static final class Xorshift32 {
        private int state;

        Xorshift32(int seed) {
            this.state = seed == 0 ? 1 : seed;
        }

        long next() {
            int x = state;
            x = x ^ (x << 13);
            x = x ^ (x >>> 17);
            x = x ^ (x << 5);
            state = x;
            return ((long) x) & 0xFFFFFFFFL;
        }
    }
}
