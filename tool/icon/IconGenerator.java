import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.GraphicsEnvironment;
import java.awt.RenderingHints;
import java.awt.geom.Area;
import java.awt.geom.Rectangle2D;
import java.awt.geom.RoundRectangle2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.util.Random;
import javax.imageio.ImageIO;

/**
 * Generates the Shibu app icon: a pixel-art Mt. Fuji scene with a torii gate,
 * a lake and cherry blossom, plus the kanji wordmark.
 *
 * The scene is authored on a 64x64 logical grid and scaled up with
 * nearest-neighbour sampling so it stays crisp pixel art. Three files are
 * produced:
 *
 *   icon.png             1024x1024, rounded corners  -> legacy launcher icon
 *   icon_background.png  1024x1024, square, padded   -> adaptive icon background
 *   icon_foreground.png  1024x1024, transparent      -> adaptive icon foreground (wordmark)
 *
 * Run with:  java tool/icon/IconGenerator.java assets/icon
 */
public final class IconGenerator {

    private static final int GRID = 64;
    private static final int OUT = 1024;

    /** "kanji" written in kanji. Escaped so the source stays pure ASCII. */
    private static final String MARK = "\u6F22\u5B57";

    // Palette ---------------------------------------------------------------
    private static final int SKY_TOP = 0xFF9AD3F1;
    private static final int SKY_BOTTOM = 0xFFC2E6F8;
    private static final int SUN = 0xFFF7D264;
    private static final int SUN_GLOW = 0xFFFAE6A4;
    private static final int CLOUD = 0xFFFFFFFF;
    private static final int CLOUD_SHADE = 0xFFDCEDF9;
    private static final int FUJI_OUTLINE = 0xFF262F5C;
    private static final int FUJI_LIGHT = 0xFF505E97;
    private static final int FUJI_DARK = 0xFF3B477A;
    private static final int SNOW = 0xFFF4F8FC;
    private static final int SNOW_SHADE = 0xFFC7D5E6;
    private static final int TREES = 0xFF1E5449;
    private static final int TREES_DARK = 0xFF143C34;
    private static final int SHORE = 0xFF8C7C4F;
    private static final int WATER = 0xFF2F93D8;
    private static final int WATER_LIGHT = 0xFF7FC7EF;
    private static final int TORII = 0xFFCE3A2C;
    private static final int TORII_DARK = 0xFF4C181A;
    private static final int BRANCH = 0xFF5C2038;
    private static final int SAKURA = 0xFFF4B2CA;
    private static final int SAKURA_DARK = 0xFFDE6E9A;

    // Scene geometry --------------------------------------------------------
    private static final int PEAK_Y = 17;
    private static final int MOUNTAIN_BASE_Y = 50;
    private static final int PEAK_X = 32;
    private static final int TREE_TOP_Y = 48;
    private static final int SHORE_Y = 52;
    private static final int WATER_Y = 54;

    private final int[][] px = new int[GRID][GRID];
    private final Random rng = new Random(20240623L);

    public static void main(String[] args) throws Exception {
        File outDir = new File(args.length > 0 ? args[0] : "assets/icon");
        if (!outDir.exists() && !outDir.mkdirs()) {
            throw new IllegalStateException("could not create " + outDir);
        }

        IconGenerator gen = new IconGenerator();
        gen.paintScene();

        BufferedImage scene = gen.toImage();

        ImageIO.write(withRoundedCorners(withMark(upscale(scene, OUT))), "png",
                new File(outDir, "icon.png"));
        ImageIO.write(upscale(pad(scene, 16), OUT), "png",
                new File(outDir, "icon_background.png"));
        ImageIO.write(foregroundMark(), "png",
                new File(outDir, "icon_foreground.png"));

        // Google Play wants exactly 512x512, square and opaque: it applies its
        // own corner mask, so a pre-rounded icon with transparency shows dark
        // wedges in the corners once masked.
        ImageIO.write(flatten(withMark(upscale(scene, 512))), "png",
                new File(outDir, "play-icon-512.png"));

        System.out.println("wrote icon.png, icon_background.png, icon_foreground.png to " + outDir);
    }

    // Scene painting --------------------------------------------------------

    private void paintScene() {
        sky();
        sun();
        clouds();
        mountain();
        trees();
        water();
        torii();
        sakura();
    }

    private void sky() {
        for (int y = 0; y < GRID; y++) {
            int c = lerp(SKY_TOP, SKY_BOTTOM, y / (float) WATER_Y);
            for (int x = 0; x < GRID; x++) {
                px[y][x] = c;
            }
        }
    }

    private void sun() {
        disc(47, 11, 6.4f, SUN_GLOW);
        disc(47, 11, 4.6f, SUN);
    }

    private void clouds() {
        // Each row is {x, y, width}; two stacked rows read as a puffy cloud.
        int[][] puffs = {
                {14, 14, 9}, {12, 15, 13}, {17, 13, 4},
                {33, 9, 7}, {31, 10, 11}, {36, 8, 3},
                {4, 25, 7}, {3, 26, 10},
                {52, 24, 8}, {51, 25, 11},
        };
        for (int[] p : puffs) {
            for (int i = 0; i < p[2]; i++) {
                set(p[0] + i, p[1], CLOUD);
            }
        }
        // A soft underside so the clouds do not read as flat bars.
        for (int[] p : new int[][]{{12, 16, 13}, {31, 11, 11}, {3, 27, 10}, {51, 26, 11}}) {
            for (int i = 0; i < p[2]; i++) {
                set(p[0] + i, p[1], CLOUD_SHADE);
            }
        }
    }

    private void mountain() {
        // Jagged lower edge of the snow cap, sampled per column.
        int[] snowEdge = new int[GRID];
        for (int x = 0; x < GRID; x++) {
            snowEdge[x] = 27 + rng.nextInt(4);
        }

        for (int y = PEAK_Y; y <= MOUNTAIN_BASE_Y; y++) {
            // Fuji's silhouette flares out towards the base, so the half-width
            // follows a mild power curve rather than a straight line.
            float t = (y - PEAK_Y) / (float) (MOUNTAIN_BASE_Y - PEAK_Y);
            float half = 3.0f + (float) Math.pow(t, 1.35) * 28.0f;
            int left = Math.round(PEAK_X - half);
            int right = Math.round(PEAK_X + half);

            for (int x = left; x <= right; x++) {
                boolean rightFace = x > PEAK_X + 1;
                int color;
                if (y <= snowEdge[Math.floorMod(x, GRID)]) {
                    color = rightFace ? SNOW_SHADE : SNOW;
                } else {
                    color = rightFace ? FUJI_DARK : FUJI_LIGHT;
                }
                set(x, y, color);
            }

            // Crisp silhouette on both flanks.
            set(left, y, FUJI_OUTLINE);
            set(right, y, FUJI_OUTLINE);
        }

        // Flatten and outline the crater rim.
        for (int x = PEAK_X - 3; x <= PEAK_X + 3; x++) {
            set(x, PEAK_Y, FUJI_OUTLINE);
        }
    }

    private void trees() {
        for (int x = 0; x < GRID; x++) {
            int top = TREE_TOP_Y + rng.nextInt(3);
            for (int y = top; y < SHORE_Y; y++) {
                set(x, y, y == top ? TREES : TREES_DARK);
            }
        }
        for (int x = 0; x < GRID; x++) {
            for (int y = SHORE_Y; y < WATER_Y; y++) {
                set(x, y, SHORE);
            }
        }
    }

    private void water() {
        for (int y = WATER_Y; y < GRID; y++) {
            for (int x = 0; x < GRID; x++) {
                set(x, y, WATER);
            }
        }
        // Horizontal highlights suggesting ripples.
        int[][] ripples = {{6, 57, 9}, {20, 59, 7}, {38, 56, 11}, {44, 61, 8}, {12, 62, 6}};
        for (int[] r : ripples) {
            for (int i = 0; i < r[2]; i++) {
                set(r[0] + i, r[1], WATER_LIGHT);
            }
        }
    }

    private void torii() {
        // Kasagi: the curved top lintel.
        fill(8, 39, 27, 40, TORII);
        fill(8, 38, 27, 38, TORII_DARK);
        // Nuki: the lower tie beam.
        fill(10, 44, 25, 44, TORII);
        // Pillars.
        fill(12, 41, 14, 57, TORII);
        fill(21, 41, 23, 57, TORII);
        // Shaded right edge of each pillar for a hint of volume.
        fill(14, 41, 14, 57, TORII_DARK);
        fill(23, 41, 23, 57, TORII_DARK);
    }

    private void sakura() {
        // A branch sweeping in from the right edge.
        int[][] branch = {
                {63, 40}, {62, 41}, {61, 41}, {60, 42}, {59, 43}, {58, 43},
                {57, 44}, {56, 45}, {55, 46}, {54, 47}, {53, 48}, {52, 50},
                {51, 52}, {50, 54}, {49, 56}, {48, 58},
        };
        for (int[] b : branch) {
            set(b[0], b[1], BRANCH);
        }

        int[][] blossoms = {
                {61, 37}, {58, 39}, {55, 41}, {52, 44}, {50, 47}, {48, 51},
                {60, 44}, {57, 47}, {54, 50}, {51, 56}, {62, 48}, {59, 52},
                {63, 34}, {56, 36},
        };
        for (int[] b : blossoms) {
            blossom(b[0], b[1]);
        }
    }

    private void blossom(int cx, int cy) {
        set(cx, cy, SAKURA_DARK);
        set(cx - 1, cy, SAKURA);
        set(cx + 1, cy, SAKURA);
        set(cx, cy - 1, SAKURA);
        set(cx, cy + 1, SAKURA);
    }

    // Pixel helpers ---------------------------------------------------------

    private void set(int x, int y, int argb) {
        if (x >= 0 && x < GRID && y >= 0 && y < GRID) {
            px[y][x] = argb;
        }
    }

    private void fill(int x0, int y0, int x1, int y1, int argb) {
        for (int y = y0; y <= y1; y++) {
            for (int x = x0; x <= x1; x++) {
                set(x, y, argb);
            }
        }
    }

    private void disc(int cx, int cy, float r, int argb) {
        int ri = (int) Math.ceil(r);
        for (int y = cy - ri; y <= cy + ri; y++) {
            for (int x = cx - ri; x <= cx + ri; x++) {
                float dx = x - cx;
                float dy = y - cy;
                if (dx * dx + dy * dy <= r * r) {
                    set(x, y, argb);
                }
            }
        }
    }

    private static int lerp(int a, int b, float t) {
        t = Math.max(0f, Math.min(1f, t));
        int ar = (a >> 16) & 0xFF, ag = (a >> 8) & 0xFF, ab = a & 0xFF;
        int br = (b >> 16) & 0xFF, bg = (b >> 8) & 0xFF, bb = b & 0xFF;
        int r = Math.round(ar + (br - ar) * t);
        int g = Math.round(ag + (bg - ag) * t);
        int bl = Math.round(ab + (bb - ab) * t);
        return 0xFF000000 | (r << 16) | (g << 8) | bl;
    }

    private BufferedImage toImage() {
        BufferedImage img = new BufferedImage(GRID, GRID, BufferedImage.TYPE_INT_ARGB);
        for (int y = 0; y < GRID; y++) {
            for (int x = 0; x < GRID; x++) {
                img.setRGB(x, y, px[y][x]);
            }
        }
        return img;
    }

    // Output composition ----------------------------------------------------

    /** Extends the scene outward so an adaptive icon mask has room to crop. */
    private static BufferedImage pad(BufferedImage src, int pad) {
        int w = src.getWidth() + pad * 2;
        int h = src.getHeight() + pad * 2;
        BufferedImage out = new BufferedImage(w, h, BufferedImage.TYPE_INT_ARGB);
        for (int y = 0; y < h; y++) {
            int sy = clamp(y - pad, 0, src.getHeight() - 1);
            for (int x = 0; x < w; x++) {
                int sx = clamp(x - pad, 0, src.getWidth() - 1);
                out.setRGB(x, y, src.getRGB(sx, sy));
            }
        }
        return out;
    }

    private static BufferedImage upscale(BufferedImage src, int size) {
        BufferedImage out = new BufferedImage(size, size, BufferedImage.TYPE_INT_ARGB);
        for (int y = 0; y < size; y++) {
            int sy = Math.min(src.getHeight() - 1, y * src.getHeight() / size);
            for (int x = 0; x < size; x++) {
                int sx = Math.min(src.getWidth() - 1, x * src.getWidth() / size);
                out.setRGB(x, y, src.getRGB(sx, sy));
            }
        }
        return out;
    }

    private static BufferedImage withMark(BufferedImage src) {
        Graphics2D g = src.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING,
                RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        float k = src.getWidth() / 1024f;
        g.setFont(japaneseFont(112f * k));
        g.setColor(new Color(0x11, 0x14, 0x1A));
        g.drawString(MARK, 150 * k, 200 * k);
        g.dispose();
        return src;
    }

    private static BufferedImage foregroundMark() {
        BufferedImage out = new BufferedImage(OUT, OUT, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = out.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING,
                RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

        Font font = japaneseFont(300f);
        g.setFont(font);
        String mark = MARK;
        Rectangle2D bounds = g.getFontMetrics().getStringBounds(mark, g);

        // Centre the mark inside the 66% adaptive-icon safe zone.
        float x = (float) ((OUT - bounds.getWidth()) / 2.0);
        float y = (float) ((OUT - bounds.getHeight()) / 2.0 - bounds.getY());

        g.setColor(new Color(0, 0, 0, 70));
        g.drawString(mark, x + 6, y + 8);
        g.setColor(Color.WHITE);
        g.drawString(mark, x, y);
        g.dispose();
        return out;
    }

    /** Drops the alpha channel by compositing onto opaque black. */
    private static BufferedImage flatten(BufferedImage src) {
        BufferedImage out = new BufferedImage(
                src.getWidth(), src.getHeight(), BufferedImage.TYPE_INT_RGB);
        Graphics2D g = out.createGraphics();
        g.setColor(Color.BLACK);
        g.fillRect(0, 0, src.getWidth(), src.getHeight());
        g.drawImage(src, 0, 0, null);
        g.dispose();
        return out;
    }

    private static BufferedImage withRoundedCorners(BufferedImage src) {
        int size = src.getWidth();
        float radius = size * 0.225f;
        BufferedImage out = new BufferedImage(size, size, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = out.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.setClip(new Area(new RoundRectangle2D.Float(0, 0, size, size, radius * 2, radius * 2)));
        g.drawImage(src, 0, 0, null);
        g.setClip(null);
        g.setColor(new Color(255, 255, 255, 40));
        g.setStroke(new BasicStroke(size * 0.008f));
        g.draw(new RoundRectangle2D.Float(1, 1, size - 2, size - 2, radius * 2, radius * 2));
        g.dispose();
        return out;
    }

    /** Picks the first installed font that can render kanji. */
    private static Font japaneseFont(float size) {
        String[] preferred = {
                "Yu Gothic UI", "Yu Gothic", "Meiryo", "MS Gothic",
                "Noto Sans CJK JP", "Noto Sans JP", "Hiragino Sans", "SimSun",
        };
        for (String name : preferred) {
            Font f = new Font(name, Font.BOLD, (int) size);
            if (canRenderMark(f)) {
                return f.deriveFont(size);
            }
        }
        for (String name : GraphicsEnvironment.getLocalGraphicsEnvironment()
                .getAvailableFontFamilyNames()) {
            Font f = new Font(name, Font.BOLD, (int) size);
            if (canRenderMark(f)) {
                System.out.println("using fallback font: " + name);
                return f.deriveFont(size);
            }
        }
        throw new IllegalStateException("no installed font can render kanji");
    }

    private static boolean canRenderMark(Font f) {
        return f.canDisplayUpTo(MARK) == -1;
    }

    private static int clamp(int v, int lo, int hi) {
        return Math.max(lo, Math.min(hi, v));
    }
}
