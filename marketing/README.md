# Cinderbrook Brigade — store and review package

This local package is prepared for owner review. No Google Play submission or website-hosting change is performed by these files. `store/store-listing.json` is the English copy source of truth; no invented translations are included. App title: 19 characters. Short description: 69 characters. Full description: 2,632 characters.

## Upload artwork

| Asset | File | Format |
| --- | --- | --- |
| App icon | `app-icon-512.png` | 512×512 RGBA PNG |
| Feature graphic | `feature-graphic-1024x500.png` | 1024×500 RGB PNG |
| Portrait splash/key art | `splash-1080x1920.png` | 1080×1920 RGB PNG |
| Achievement art | `achievements/<catalog-id>.png` | 20 distinct 512×512 RGB PNGs |
| Leaderboard art | `leaderboards/<catalog-id>.png` | 3 distinct 512×512 RGB PNGs |
| Actual gameplay captures | `screenshots/` | See screenshot manifest for the device/profile and provenance |

The illustrations were generated with the built-in imagegen tool. Five original sources and their full prompts are preserved in `source/`; `art-manifest.json` records output hashes, sizes and measured crops. `tools/prepare_art.py` reproduces delivery formatting with Pillow. Individually measured atlas crops preserve the full badge shapes, then aspect-preserving sizing adds neutral delivery margins. It does not create or alter gameplay screenshots. Store badges and the matching runtime catalog icons use identical 512×512 art. The corrected contact sheet is `source/badges-contact-sheet.jpg`; `source/badge-edge-validation.json` verifies all four outer 40-pixel strips of every badge remain dark and free of gold/cream fragments.

All source art and final badge crops were visually inspected. Uniform atlas-cell crops initially admitted neighboring badge tips and a laurel fragment beside Crew Leader. Individually measured bounds and aspect-preserving containment fixed those artifacts while restoring the full shield tips and Chief's left laurel. All 23 edges were then re-inspected and their neutral margins validated. No illustration is represented as gameplay. Native emulator captures must be labeled emulator evidence, and physical-device evidence requires an actual physical device.

## Copy and store setup

Use `store/short-description.txt`, `store/long-description.txt` and `store/store-listing.json`. Category is **Game / Arcade**; the five tags are proposed labels to match the options available in Console. The listing describes 36 authored incidents, six districts, Daily Incident, Endless Watch, five upgrade branches, local progression and twenty achievements. The final prototype-services paragraph is deliberately candid and should change only after the corresponding production services are verified.

`store/privacy-draft.html`, `store/support.html` and `store/data-safety-draft.json` are release-preparation drafts. They do not claim no SDK data collection, a content rating, production service availability or a hosted privacy policy. The owner must confirm legal identity, contact, actual SDK data practices, target audience, content rating and final declarations. [Google preview guidance](https://support.google.com/googleplay/android-developer/answer/9866151) specifies the upload assets; [Google Mobile Ads disclosure guidance](https://developers.google.com/admob/android/privacy/play-data-disclosure) informs the SDK review.

## Audio and licenses

`assets/audio/manifest.json` maps seven original sixteen-bar instrumental cues and twelve sound effects. `tools/prepare_audio.py` renders original deterministic music and water/steam Foley and copies five supplied Kenney UI/coin effects without modifying their bytes. Kenney notices are retained under `assets/audio/LICENSES/`. The score includes distinct melodies, harmonic progressions and arrangements for the station and each district. The signal report records duration, sample rate, peaks, DC and loop boundary deltas; no human listening review is implied by signal tests. Native playback is part of runtime QA.

Original project compositions, generated artwork and tools are supplied under the project's Apache-2.0 license; Kenney assets retain CC0. The achievement-import archive is separately documented in `play-games-achievements/` and `docs/ACHIEVEMENT_IMPORT.md`.

## Review page

`tools/assemble_review.py` assembles `review/index.html` and the prepared `public/index.html`, with clearly labeled key art and only provenance-backed runtime images. It references the shared marketing assets directly and preserves the Web export. `tools/assemble_site.py` copies those shared files and the landing page into `build/site/` alongside `play/`; the source `review/index.html` also works locally. When opened from disk, both pages replace Web-play links with an HTTP-serving note: Godot's Web export should be served over HTTP, not opened as a file. These are local prepared files; GitHub repository publication does not authorize enabling Pages.
