# Contributing to Shibu

Thanks for taking a look. Issues and pull requests are both welcome.

## Getting set up

You need **Flutter 3.44 or newer** and **JDK 17**.

```bash
git clone https://github.com/Rohan3280/shibu.git
cd shibu
flutter pub get
flutter test
flutter run           # with a device or emulator attached
```

No secrets are needed. The release build falls back to the debug signing key
when `android/key.properties` is absent, so a fresh clone builds immediately.

## Before you open a pull request

```bash
dart format .
flutter analyze          # must be clean
flutter test             # must pass
```

CI runs exactly these, plus a release APK build.

## Fixing the kanji data

`assets/data/kanji.json` is hand-curated, and corrections are the most useful
contribution there is. Each entry looks like this:

```json
{
  "id": 0, "c": "駅", "l": 5, "s": 14,
  "r": "eki", "k": "えき", "m": "station",
  "on": "エキ", "kun": "",
  "ex": "駅前", "exk": "えきまえ", "exr": "ekimae", "exm": "in front of station"
}
```

| Key | Meaning |
| --- | --- |
| `id` | Position in the file. Contiguous from 0 — do not reorder entries. |
| `c` | The kanji, exactly one character |
| `l` | JLPT level (5 is easiest) |
| `s` | Stroke count |
| `r` / `k` | Primary reading in romaji and kana — this is the `eki・えき` line |
| `m` | English meaning — the bold line |
| `on` / `kun` | Full reading lists, shown in the detail sheet |
| `ex` … `exm` | Example compound, its kana, its romaji, its meaning |

`test/kanji_repository_test.dart` enforces the structural rules: ids contiguous
and unique, characters unique, no empty fields the card would render blank, one
character per entry, and every example word actually containing its own kanji.
Run `flutter test` after editing.

If you add entries, append them and renumber `id` so it stays contiguous.

## Two things that are deliberately duplicated

Please do not "fix" these by unifying them without reading why they exist.

**The card is implemented twice.** `android/…/render/CardRenderer.kt` draws the
real card onto a `Canvas` for the wallpaper and the widget. `lib/widgets/kanji_card.dart`
draws the in-app preview in Flutter. There is no way to share a Canvas layout
between a Flutter widget and a `RemoteViews` bitmap, so they are two
implementations of one design and their size constants mirror each other.
**Change both together.**

**The shuffle is implemented twice.** `lib/services/deck_order.dart` and
`android/…/data/DeckOrder.kt` are the same xorshift32 generator and the same
Fisher–Yates walk. They exist because `dart:math`'s `Random` and
`java.util.Random` are different algorithms, and a mismatch would make the app
show one kanji in its preview and a different one on your lock screen.

`test/deck_order_test.dart` pins the Dart side to goldens produced on the JVM:

```bash
java tool/verify_deck_order/VerifyDeckOrder.java   # prints the expected orders
```

If you change the algorithm, regenerate the goldens and update both files.

## The app icon

`assets/icon/*.png` are generated, not drawn by hand:

```bash
java tool/icon/IconGenerator.java assets/icon
dart run flutter_launcher_icons
```

`tool/icon/IconGenerator.java` is kept ASCII-only so it compiles regardless of
the platform's default source encoding.

## Screenshots

`docs/screenshots/*.png` are captured from a real device:

```bash
adb shell am start -n com.shibu.app/.MainActivity
adb exec-out screencap -p > docs/screenshots/01-today.png
```

`docs/screenshots/rendered/` holds the same screens drawn straight from the
widget tree, for when no phone is to hand:

```bash
flutter test --update-goldens test/screenshots.dart
```

That file is named without the `_test` suffix so a plain `flutter test` skips
it — its output depends on which fonts the host has installed.

## Reporting a bug

Please include your Android version, your phone model, and which surface is
misbehaving — the wallpaper, the widget, or the app itself.

Two behaviours are expected rather than bugs, and are explained in the README:

- **"Every unlock" does nothing without the Shibu wallpaper.** Android does not
  deliver `ACTION_USER_PRESENT` to manifest receivers, so the wallpaper engine
  becoming visible is the only signal Shibu can use without running a
  foreground service.
- **A timed rotation can be up to 15 minutes late.** WorkManager will not run a
  periodic job more often than that, and Doze can delay it further.

## Code style

Follow what is already there: `flutter_lints`, trailing commas, and comments
that explain *why* rather than restating the code. Comments carry their weight
or they come out.
