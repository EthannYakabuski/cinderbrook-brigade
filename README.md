# Cinderbrook Brigade

One finger. A whole neighborhood worth saving.

Cinderbrook Brigade is a portrait 3D firefighting arcade built in Godot 4.5.1
Compatibility. Drag a hose stream over glowing hotspots, lift to refill, and
choose which neighbors need cooling before the next ember lands. Real Kenney
miniature buildings, campsites, trees and a firetruck frame the action.

The campaign contains 36 individually authored incidents in Maple Mews, Pine
Camp, Warehouse Row, Orchard Bend, Lakeside Fair and Lantern Heights. Endless
Watch and a seeded Daily Incident add repeatable challenges. Brigade XP, five
garage upgrades, daily gifts, quests, 20 achievements and three local records
share an offline profile. Campaign content is designed to be possible with
baseline equipment and without advertisements.

This is a stylized arcade game, not instruction for responding to a real fire.

## Play and review

Implementation is available; native acceptance is incomplete. Emulator control
is now approved. A temporary host GPU option fixed the emulator's black game
area; Windows control-tool capture still times out. See [verification and remaining work](docs/VERIFICATION.md),
[the initial design](INITIAL_VECTOR_PROMPT.txt) and [the acceptance checklist](docs/ACCEPTANCE.md).
Actual Web play cleared the first incident and retained its reward after reopening.
Required Android touch/ad tests and phone/tablet capture evidence remain pending.

Open `project.godot` in Godot 4.5.1 and run the main scene. Android is the primary
target; Web uses the single-threaded Compatibility export. There is no Windows
distribution. Local generated outputs belong in `build/android/` and
`build/site/`; they are not source-controlled.

The HTML review source is `review/index.html`. A complete assembled review lives
at `build/site/review/index.html` after export and assembly. Owner-approved Pages configuration now uses GitHub Actions. Deployment remains
gated on successful validation and Android CI for the exact published commit.

## Native configuration and builds

The package is `com.ethannyakabuski.cinderbrookbrigade`. Development presets use
API 24 minimum, API 36 target and ARM64, x86 and x86_64. The local APK has a
verified development signature; the local AAB is unsigned and is not ready for
Play submission. Use the installed Godot
4.5.1 export templates, JDK 17 and Android SDK. The default Android export is an
AAB; `Android Test APK` produces an installable debug APK.

```powershell
./tools/build.ps1 -Godot '<Godot executable>' -Python '<Python executable>' -Target 'Android Test APK'
./tools/build.ps1 -Godot '<Godot executable>' -Python '<Python executable>' -Target Android
./tools/build.ps1 -Godot '<Godot executable>' -Python '<Python executable>' -Target Web
```

Run exports sequentially. The helper owns and waits for each Godot process;
generated Android files come from the official template, never another game's
credentials or generated build. See [platform setup](platform/README.md).

## Services and monetization

The Poing AdMob and Google Play Games plugins are integrated. Development ads
use Google's official sample IDs. Production mappings are blank and Play Games
is disabled pending owner configuration. Offline and Web progress remains
available without either service.

A reserved menu/result banner avoids controls. An interstitial opportunity
occurs at a natural transition after every third finalized played round. Failure
offers one optional emergency continuation: a genuine earned callback creates
the entitlement, dismissal returns to a paused game, and Resume restarts play.
Unavailable, failed, cancelled and Web ads grant nothing. Production backends,
signing, consent-region verification and Google Play publication remain separate.

## Achievement import

The reproducible import package is
`marketing/play-games-achievements/cinderbrook-brigade-achievements-google-play.zip`.
It follows the successfully imported Beacon archive: headerless
`AchievementsMetadata.csv`, plural `AchievementsIconsMappings.csv` and flat PNGs.
Default English belongs in metadata. The 20 Standard, Revealed achievements
currently propose 700 total points; no Console import has been performed.

```text
python tools/build_achievement_import.py --check
```

See [import instructions and the ID worksheet](docs/ACHIEVEMENT_IMPORT.md).

## Validation and licenses

GitHub-hosted CI validates the source and tests, exports Web, and builds Android
on main pushes. A prepared Pages workflow is manually gated; its presence does
not enable hosting. Final acceptance records must distinguish model simulations,
scripted desktop renders, Android emulator input and physical-device checks.

Original code is Apache-2.0. Preserve [NOTICE](NOTICE), all supplied Kenney CC0
notices and the plugin licenses in `addons/` and `LICENSES/`.
