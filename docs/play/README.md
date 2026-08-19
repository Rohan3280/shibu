# Google Play store listing assets

Everything in this folder is generated or captured, and is what the Play Console
forms ask for.

| File | Play field | Spec |
| --- | --- | --- |
| `app-name.txt` | App name | 30 characters |
| `short-description.txt` | Short description | 80 characters |
| `full-description.txt` | Full description | 4000 characters |
| `icon-512.png` | App icon | exactly 512x512, 32-bit PNG, under 1 MB |
| `feature-graphic.png` | Feature graphic | exactly 1024x500 |
| `screenshots/*.png` | Phone screenshots | 9:16, each side 320-3840 px, under 8 MB |

## Regenerating

```bash
java tool/icon/IconGenerator.java assets/icon   # also emits play-icon-512.png
java tool/play/PlayAssets.java                  # feature graphic + 9:16 screenshots
```

`docs/screenshots/` holds the raw device captures at 1080x2400. Play only accepts
16:9 or 9:16 phone screenshots, and a modern phone is taller than that, so
`PlayAssets` centres each capture on a 9:16 canvas filled with the app's own
background colour rather than cropping any UI away.

## The build to upload

Play needs a signed **App Bundle**, not an APK:

```bash
flutter build appbundle --release
# -> build/app/outputs/bundle/release/app-release.aab
```

This requires `android/key.properties` and the upload keystore it points at.
Neither is committed. Without them the release build silently falls back to the
debug key, which Play rejects.
