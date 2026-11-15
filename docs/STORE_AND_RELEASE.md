# Cinderbrook Brigade store and release package

**Current status: recorded emulator prototype acceptance and local Web smoke passed.** Source is published at [EthannYakabuski/cinderbrook-brigade](https://github.com/EthannYakabuski/cinderbrook-brigade). The native receipt records 39 passing audited checks against the identified final APK; final delivery additionally requires reviewed output and successful CI for the exact source commit. The owner explicitly approved Pages, and its configuration was verified as GitHub Actions with `PAGES_DEPLOY_ENABLED=true`. That configuration is distinct from a successful deployment: actual revision-specific CI and deployment outcomes belong in the final handoff and repository Actions runs. No Google Play upload, achievement import or publication has been performed.

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
| Runtime screenshot records | `marketing/screenshots/provenance.json` | Genuine framebuffer PNGs with artifact identity, hashes and logical display profiles |
| Styled review source | `review/index.html` | Generated HTML with the selected genuine captures and current native receipt status |
| Prepared landing-page source | `public/index.html` | Assembled into the site's root |

The illustrations are promotional art, not gameplay screenshots. The review gallery verifies native image records and explicitly identifies emulator captures. Its counts come from provenance, and its acceptance status comes from `docs/native-acceptance.json`; neither image counts nor a successful integrity check imply completed gameplay acceptance. Setting a capture's optional `review_visible` field to `false` omits it from the gallery without altering or deleting its pixels, sidecar or receipt. Descriptions must match the actual frame, including failure/results frames. Phone, 7-inch and 10-inch profiles are required for the finished package; logical emulator sizes do not establish physical-device dimensions or performance.

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

The refreshed exports are verified and promoted to the canonical paths below. The APK SHA-256 is `1488f7ec33d146ef869c91890c4f46c0634e300d0bd3d897d93c1d030a4190d4`; the AAB is `d49018c248dfc3de6af4df4ce77bd5f52477ad1a08b7e75d75ff21657cc830b6`. The APK has a valid development signature; the AAB is explicitly unsigned. `docs/android-package-evidence.json` and `docs/packed-art-evidence.json` identify package bytes, source inputs and all 23 corrected packed icon checks. `docs/native-acceptance.json` identifies the APK covered by its runtime observations. Final source/CI/deployment receipts and the acceptance handoff must state their exact revision and outcomes separately.

| Output | Path | Verification required |
| --- | --- | --- |
| Installable test APK | `build/android/cinderbrook-brigade-test.apk` | Signature/package checks passed; installed identity and ordinary touch play recorded in native receipt |
| Development AAB | `build/android/cinderbrook-brigade-debug.aab` | Static package/ABI/16KB alignment checks passed; unsigned, not ready for Play submission |
| Web export | `build/site/play/index.html` and companion files | All 712 PCK checksums passed; refreshed isolated-browser smoke passed, with scope in `docs/web-refresh-acceptance.json` |
| Assembled review | `build/site/review/index.html` | Actual image/links/layout inspection |
| Assembled landing page | `build/site/index.html` | Local review; Pages configuration authorized, deployment still requires exact-commit gates |
| Source and Web identity receipt | `build/site/build.json` | Exact source commit; clean tree; Web hashes; assembly is not deployment |

Run the static package checks from the project root:

```sh
python tools/build_achievement_import.py --self-test
python tests/test_packaging.py
python tools/build_achievement_import.py --check
python tools/validate_store.py
```

The achievement validator has 33 archive self-tests; the packaging suite has 20 test methods, including malformed catalog/provenance cases, protected ID worksheets, canonical Git-blob portability and synthetic local-site assembly. Synthetic fixtures are not runtime images. During active development only, `python tools/validate_store.py --allow-pending` checks prepared assets while explicitly reporting missing runtime capture profiles; CI does not use that staging override.

After capture curation and the native receipt are current, validate the review without changing files, then generate it before the final source commit:

```sh
python tools/assemble_review.py --check
python tools/assemble_review.py
```

The review's read-only check can describe an incomplete native run honestly; it does not replace strict store validation or relax CI. It does not configure or deploy hosting. Inspect the generated page, then commit the audited changes. After a real Web export and final source commit, assemble the site with:

```sh
python tools/verify_web_export.py build/site/play --output build/web-export-validation.json
python tools/assemble_site.py build/site --require-clean --expected-sha <exact-final-commit>
```

The site assembler refuses source drift, filters private output, preserves the official engine JavaScript and records canonical committed runtime hashes separately from checkout-byte hashes. The GitHub-hosted workflow performs validation/Web export and native builds on main pushes. Its existence is not a passing CI result. The final handoff must identify the exact commit, actual job results and retained artifacts. Pages configuration is already owner-authorized and enabled; the Pages workflow must still verify successful `validate` and `android` jobs for its exact source revision before deployment. A live URL and runtime verification must be recorded only after that deployment actually succeeds.

## Acceptance scope and remaining release work

Actual Android emulator input on the replacement APK passed campaign success, natural failure, held-empty/refill behavior, purchases, pause/cold restart, native test-ad dismissal and earned-callback continuation. Both open-ad process-interruption cases passed, and two Endless waves banked once with exact profile retention through restart. All three scrolling-page repairs and intentional map taps were retested. Eighteen selected replacement framebuffer images passed source/hash/provenance checks across phone and both logical tablet profiles; six baseline images retain their distinct identity outside the review gallery. The installed artifact was rechecked and the task-owned emulator closed after restoring its original display configuration. Baseline coverage is not silently attributed to the replacement package. Tests separately identify model simulations, application-logic fixtures, desktop renders, Android emulator input and physical-device evidence.

The owner will still need physical-device play/audio/performance/accessibility checks, production backend configuration/testing, release signing review and Console submission. APK/AAB exports, ELF alignment checks, emulator observations and local static validation do not establish all of those outcomes. Record actual blockers and untested areas in the final acceptance document; do not silently convert pending evidence into a pass.
