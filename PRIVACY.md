# Privacy Policy

**Shibu** — last updated 20 August 2026.

## The short version

Shibu collects nothing, sends nothing, and cannot reach the internet. The app
declares no `INTERNET` permission in its manifest, so this is enforced by
Android rather than promised by us.

## What is stored, and where

Everything stays in Shibu's private app storage on your device.

| What | Where | Why |
| --- | --- | --- |
| Your settings — levels, rotation, colours, position | `SharedPreferences` (`shibu_settings`) | So the wallpaper and widget know what to draw |
| Favourites and kanji marked learned | `SharedPreferences` (`shibu_settings`) | Your progress |
| A copy of the background image or GIF you choose | App-private files directory | So the wallpaper can draw it without needing storage permission each time, and so it keeps working if you move or delete the original |

No account, no identifier, no analytics, no crash reporting, no advertising.

## Permissions

| Permission | Why it is requested |
| --- | --- |
| `RECEIVE_BOOT_COMPLETED` | Re-arms the rotation schedule after you restart your phone. Without it, the card would stop changing until you next opened the app. |
| `BIND_WALLPAPER` | Declared on the wallpaper service. This is a permission Android requires the *system* to hold in order to bind to Shibu, not a permission Shibu holds over you. |

Choosing a backdrop uses the system document picker, which hands Shibu the
single file you selected. Shibu never requests broad storage access.

## Backups

If you have Android backup enabled, your settings file may be included in your
Google account backup, under Google's terms. The copied background photo is
explicitly excluded — see `android/app/src/main/res/xml/backup_rules.xml`.

## Removing your data

Uninstalling Shibu deletes everything above. There is nothing held anywhere
else, because there is nowhere else.

## Questions

Open an issue at <https://github.com/Rohan3280/shibu/issues>.
