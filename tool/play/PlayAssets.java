import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.GradientPaint;
import java.awt.Font;
import java.awt.RenderingHints;
import java.awt.geom.RoundRectangle2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import javax.imageio.ImageIO;

/**
 * Builds the Google Play store listing artwork from assets already in the repo.
 *
 *   feature-graphic.png   1024x500, required by Play for every listing
 *   screenshots/*.png     the device captures padded to a 9:16 canvas
 *
 * Play accepts phone screenshots at a 16:9 or 9:16 aspect ratio only, and a
 * modern phone capture is taller than that (1080x2400 is roughly 9:20). Rather
 * than crop away part of the UI, each shot is centred on a 9:16 canvas whose
 * height matches the original, and the margins are filled with the app's own
 * background colour so the padding reads as intentional.
 *
 * Run with:  java tool/play/PlayAssets.java
 */
public final class PlayAssets {

    private static final int FEATURE_W = 1024;
    private static final int FEATURE_H = 500;

    // Straight from ShibuTheme / BackgroundPresets.
    private static final Color FUJI_TOP = new Color(0x4A, 0x58, 0x91);
    private static final Color FUJI_BOTTOM = new Color(0x1B, 0x21, 0x40);
    private static final Color INK = new Color(0x0E, 0x12, 0x20);
    private static final Color SAKURA = new Color(0xE8, 0x7B, 0xA4);

    public static void main(String[] args) throws Exception {
        File out = new File("docs/play");
        File shots = new File(out, "screenshots");
        if (!shots.exists() && !shots.mkdirs()) {
            throw new IllegalStateException("could not create " + shots);
        }

        ImageIO.write(featureGraphic(), "png", new File(out, "feature-graphic.png"));
        System.out.println("wrote feature-graphic.png (1024x500)");

        File source = new File("docs/screenshots");
        File[] files = source.listFiles((d, n) -> n.endsWith(".png"));
        if (files == null) throw new IllegalStateException("no screenshots in " + source);
        Arrays.sort(files);

        List<String> written = new ArrayList<>();
        for (File f : files) {
            BufferedImage src = ImageIO.read(f);
            if (src == null) continue;
            BufferedImage padded = toNineBySixteen(src);
            File target = new File(shots, f.getName());
            ImageIO.write(padded, "png", target);
            written.add(f.getName() + " -> " + padded.getWidth() + "x" + padded.getHeight());
        }
        for (String s : written) System.out.println("  " + s);
        System.out.println("wrote " + written.size() + " screenshots");
    }

    /** Icon on the left, wordmark and tagline on the right. */
    private static BufferedImage featureGraphic() throws Exception {
        BufferedImage out = new BufferedImage(FEATURE_W, FEATURE_H, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = out.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING,
                RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
                RenderingHints.VALUE_INTERPOLATION_BILINEAR);

        g.setPaint(new GradientPaint(0, 0, FUJI_TOP, 0, FEATURE_H, FUJI_BOTTOM));
        g.fillRect(0, 0, FEATURE_W, FEATURE_H);

        BufferedImage icon = ImageIO.read(new File("assets/icon/icon.png"));
        int size = 300;
        int x = 84;
        int y = (FEATURE_H - size) / 2;
        g.drawImage(icon, x, y, size, size, null);

        int textX = x + size + 72;
        g.setColor(Color.WHITE);
        g.setFont(uiFont(Font.BOLD, 96f));
        g.drawString("Shibu", textX, 238);

        g.setColor(new Color(0xFF, 0xFF, 0xFF, 0xD8));
        g.setFont(uiFont(Font.PLAIN, 38f));
        g.drawString("Kanji on your lock screen", textX, 296);

        g.setColor(SAKURA);
        g.fillRoundRect(textX, 330, 132, 6, 6, 6);

        g.dispose();
        return out;
    }

    /**
     * Centres [src] on a 9:16 canvas of the same height.
     *
     * If the source is already at or narrower than 9:16 it is only padded; a
     * wider source is scaled down first so nothing is ever cropped.
     */
    private static BufferedImage toNineBySixteen(BufferedImage src) {
        int height = src.getHeight();
        int width = Math.round(height * 9f / 16f);

        BufferedImage scaled = src;
        if (src.getWidth() > width) {
            float scale = width / (float) src.getWidth();
            int sw = width;
            int sh = Math.round(src.getHeight() * scale);
            BufferedImage tmp = new BufferedImage(sw, sh, BufferedImage.TYPE_INT_RGB);
            Graphics2D sg = tmp.createGraphics();
            sg.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
                    RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            sg.drawImage(src, 0, 0, sw, sh, null);
            sg.dispose();
            scaled = tmp;
            height = Math.max(height, sh);
            width = Math.round(height * 9f / 16f);
        }

        BufferedImage out = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = out.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.setColor(INK);
        g.fillRect(0, 0, width, height);

        int dx = (width - scaled.getWidth()) / 2;
        int dy = (height - scaled.getHeight()) / 2;

        // A hairline keeps the capture from bleeding into the identical mat.
        g.setColor(new Color(0xFF, 0xFF, 0xFF, 0x1F));
        g.draw(new RoundRectangle2D.Float(
                dx - 1, dy - 1, scaled.getWidth() + 2, scaled.getHeight() + 2, 8, 8));
        g.drawImage(scaled, dx, dy, null);
        g.dispose();
        return out;
    }

    private static Font uiFont(int style, float size) {
        for (String name : new String[]{"Segoe UI", "Helvetica Neue", "Arial", "SansSerif"}) {
            Font f = new Font(name, style, (int) size);
            if (f.getFamily().toLowerCase().contains(name.toLowerCase().split(" ")[0])
                    || name.equals("SansSerif")) {
                return f.deriveFont(size);
            }
        }
        return new Font(Font.SANS_SERIF, style, (int) size).deriveFont(size);
    }
}
