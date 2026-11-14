# Cinderbrook Brigade store and release package

**Current status: development acceptance in progress.** The new public repository exists at [EthannYakabuski/cinderbrook-brigade](https://github.com/EthannYakabuski/cinderbrook-brigade). Pushing the completed source and verifying hosted CI on its exact final commit are upcoming. No Google Play upload, achievement import, publication, or website-hosting setting change has been performed. A repository and a locally assembled site do not establish public website deployment.

Android is the primary target. The Web build is a single-threaded companion export. There is no Windows distribution. The package identifier is `com.ethannyakabuski.cinderbrookbrigade`; the engine is Godot 4.5.1 using the Compatibility renderer. See [README](../README.md), [platform configuration](../platform/README.md), [acceptance](ACCEPTANCE.md), and the [native test plan](NATIVE_TEST_PLAN.md) for execution and outstanding checks.

## Store copy and artwork

The draft listing is English (United States). No translations have been invented. `marketing/store/store-listing.json` is the structured source of truth; `release_ready` remains `false`. It identifies the game as Game / Arcade with proposed Casual, Single player, Offline, Stylized and Arcade tags. The owner must select the closest tags actually offered by the Console.

| Deliverable | Source path | Prepared format |
| --- | --- | --- |
| Listing title | `marketing/store/store-listing.json` | Cinderbrook Brigade; 19 characters |
| Short description | `marketing/store/short-description.txt` | 69 characters |
| Full description | `marketing/store/long-description.txt` | 2,632 characters |
| Website copy and three selling cards | `marketing/store/website-copy.txt` and listing JSON | English draft |
| App icon | `marketing/app-icon-512.png` | 512×512 PNG |
| Feature graphic | `marketing/feature-graphic-1024x500.png` | 1024×500 PNG |
| Portrait splash illustration | `marketing/splash-1080x1920.png` | 1080×1920 PNG |
| Achievement icons | `assets/achievements/` and `marketing/achievements/` | 20 distinct 512×512 PNGs |
| Leaderboard icons | `assets/leaderboards/` and `marketing/leaderboards/` | Three distinct 512×512 PNGs |
| Runtime screenshot records | `marketing/screenshots/provenance.json` | Pending genuine captures |
| Styled review source | `review/index.html` | Local HTML with genuine captures when supplied |
| Prepared landing-page source | `public/index.html` | Assembled into the site's root |

The illustrations are promotional art, not gameplay screenshots. The review gallery uses only verified native runtime image records and explicitly identifies emulator captures. Empty galleries remain marked pending rather than being populated with mockups. Phone, 7-inch and 10-inch profiles are required for the finished package; logical emulator sizes do not establish physical-device dimensions or performance.

## Gameplay and monetization represented by this listing

The intended complete game has 36 authored incidents across six districts, Daily Incident and Endless Watch modes, five equipment upgrades, career XP/rank, daily gifts and quests, 20 local achievements and three local records. Progress works locally without service configuration. Current gameplay and defect results belong in `docs/ACCEPTANCE.md` and `docs/BUG_LOG.md`; listing prose alone is not test evidence.

Failure offers an explicit, optional emergency continuation. Only a genuine earned-ad callback can durably grant it; dismissal returns to paused gameplay and requires Resume. Recovery retains normal grading and competitive records. The initial proposal's two-star recovery cap was deliberately superseded so accepting a rewarded continuation does not impose an ad-related scoring penalty.

The banner occupies reserved Home/results space. An interstitial opportunity occurs at a natural Next/Retry transition after every third finalized played round; it does not interrupt active gameplay or appear merely because results opened. An unavailable ad does not stop an ordinary retry. Native fullscreen ads and consent forms must pause gameplay. Web has no native advertising or simulated ad rewards.

## Service configuration and owner release setup

This is a **test-configured prototype**, not a production AdMob or Play Games release. `platform/config.json` has `admob.test_mode: true`; production banner, interstitial and rewarded unit fields are blank. The runtime selects official Google sample unit IDs in debug or test mode. The operative Android AdMob App ID is the sample `ca-app-pub-3940256099942544~3347511713` in `project.godot`; the matching JSON value is reference metadata.

`play_games.enabled` is `false`. The game ID and all achievement/leaderboard mappings are blank. Local achievements and records work independently. Google sign-in, backend delivery, production achievements, leaderboards, account configuration and release signing have not been verified with real IDs. The owner supplies actual project IDs, linked-app/OAuth configuration, signing fingerprints and authorized testers when preparing that backend. Do not substitute another game's identity or credentials.

The application requests consent information before Mobile Ads initialization and provides privacy controls. The prepared `marketing/store/privacy-draft.html`, `support.html` and `data-safety-draft.json` remain drafts for the actual release configuration. Native SDK integration means local saves alone do not justify a “no data collected” assertion; that claim is explicitly false in the draft. Before release, the owner completes developer/support identity, a durable privacy-policy URL, final SDK disclosures, audience/content-rating declarations, consent messages and regional verification. No production audience or content rating is invented here.

Original project work uses Apache-2.0. Preserve `LICENSE`, `NOTICE`, `LICENSES/`, and all asset/plugin license notices. The Kenney assets retain their supplied CC0 notices. The repository excludes signing keys, credentials, generated Android projects, local configuration, logs and build artifacts.

## Achievement import and leaderboards

The prepared import ZIP is `marketing/play-games-achievements/cinderbrook-brigade-achievements-google-play.zip`: 20 standard, revealed achievements; **700 proposed total points**; default English; 22 flat files. It preserves the owner-confirmed Beacon format with headerless `AchievementsMetadata.csv`, plural `AchievementsIconsMappings.csv`, and actual mapped 512×512 icons. It does not contain a localization CSV or either ID worksheet.

The archive is 5,113,990 bytes with SHA256 `b9a04a0126aa8d9d8f38d286fa47750b6b4d08d9c41709e40f736803643232c4`. Catalog fields, point rules, CSV encoding, PNG data/dimensions, mappings, CRC and exact reproducibility passed local validation. These are file-integrity checks, not Console acceptance. The points and states are proposed catalog values; no production definitions have been silently changed.

`achievement-id-mapping-and-points.csv` and `leaderboard-id-mapping.csv` are outside the archive and start with blank Console IDs. The leaderboards are Brigade Career XP, Best Incident Score and Endless Watch Waves, all ranking larger scores first. Follow [ACHIEVEMENT_IMPORT.md](ACHIEVEMENT_IMPORT.md) for generation, manual import and mapping instructions. No Console action is performed by the tools.

## Outputs and reproducible checks

The planned local output paths below identify destinations; they do not assert that the final artifacts have been built, installed or played yet. Final artifact hashes and exact-source observations must be recorded in `docs/build-evidence.json` and the acceptance handoff when testing completes.

| Output | Path | Verification required |
| --- | --- | --- |
| Installable test APK | `build/android/cinderbrook-brigade-test.apk` | Export/package checks; install and ordinary touch play on the identified build |
| Development AAB | `build/android/cinderbrook-brigade-debug.aab` | Export/package/ABI checks; explicit signing status; no Play submission |
| Web export | `build/site/play/index.html` and companion files | PCK checksums plus a separately documented supported-browser runtime check |
| Assembled review | `build/site/review/index.html` | Actual image/links/layout inspection |
| Assembled landing page | `build/site/index.html` | Local review; hosting separately authorized |
| Source and Web identity receipt | `build/site/build.json` | Exact source commit; clean tree; Web hashes; assembly is not deployment |

Run the static package checks from the project root:

```sh
python tools/build_achievement_import.py --self-test
python tests/test_packaging.py
python tools/build_achievement_import.py --check
python tools/validate_store.py
```

The achievement validator has 33 archive self-tests; the packaging suite has 20 test methods, including malformed catalog/provenance cases, protected ID worksheets, canonical Git-blob portability and synthetic local-site assembly. Synthetic fixtures are not runtime images. During active development only, `python tools/validate_store.py --allow-pending` checks prepared assets while explicitly reporting missing runtime capture profiles; CI does not use that staging override.

After a real Web export and final source commit, assemble the site with:

```sh
python tools/verify_web_export.py build/site/play --output build/web-export-validation.json
python tools/assemble_site.py build/site --require-clean --expected-sha <exact-final-commit>
```

The assembler refuses source drift, filters private output, preserves the official engine JavaScript and records canonical committed runtime hashes separately from checkout-byte hashes. The prepared GitHub-hosted workflow performs validation/Web export and native builds on main pushes. Its existence is not a passing CI result. The final handoff must identify the exact commit, actual job results and retained artifacts. Website hosting remains distinct: no Pages activation is inferred from repository publication.

## Pending acceptance evidence

At this document's initial preparation, native screenshot collection, ordinary touch success/failure, progression/save-reload, real test-ad outcomes and final supported-browser checks are still in progress. No final gameplay pass is claimed here. Tests must separately identify model simulations, application-logic fixtures, desktop renders, Android emulator input and physical-device evidence.

The owner will still need physical-device play/audio/performance/accessibility checks, production backend configuration/testing, release signing review and Console submission. APK/AAB exports, ELF alignment checks, emulator observations and local static validation do not establish all of those outcomes. Record actual blockers and untested areas in the final acceptance document; do not silently convert pending evidence into a pass.
