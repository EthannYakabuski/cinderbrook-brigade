# Cinderbrook Brigade achievement import

The package is `marketing/play-games-achievements/cinderbrook-brigade-achievements-google-play.zip`. It is prepared for owner review and manual Google Play Console import. No import, publication, production backend verification, or Google acceptance is claimed.

Validated package: **5,113,990 bytes**, SHA256 `b9a04a0126aa8d9d8f38d286fa47750b6b4d08d9c41709e40f736803643232c4`. Its finished-file readback, reproducible rebuild and all 33 archive validation self-tests passed. The separate packaging suite passes 20 test methods, including catalog/provenance rejection cases, portable Git-blob identity and a synthetic local-site assembly. Synthetic test fixtures are never offered as gameplay images.

The source of truth is `game/catalog.json`. Its 20 achievements are **standard** and initially **revealed**. Cumulative goals are locally tracked milestones that unlock once the threshold is met; they are not falsely labelled incremental Play Games achievements. Their **700 total points are proposed design values**, preserved exactly from the catalog, leaving 1,300 of the 2,000-point budget available. The owner should review points, types and initial states before publication. No existing production definitions have been changed.

The three leaderboard definitions and icons are separate from the achievement ZIP. Career XP, best incident score and Endless Watch waves all rank larger scores first. Both service-ID worksheets remain outside the import archive and initially contain blank IDs.

## Proven archive convention

The archive contains exactly 22 flat files: `AchievementsMetadata.csv`, **`AchievementsIconsMappings.csv`** (plural **Icons**), and 20 mapped 512×512 PNG icons. Neither CSV has a header. UTF-8 encoding has no BOM; CSV rows use CRLF. Each metadata row contains seven fields in this order:

`Name,Description,IncrementalValue,StepsNeeded,InitialState,Points,ListOrder`

Standard rows use `False` and an empty steps field. Mapping rows contain the exact achievement name followed by its icon filename. Default English is in the metadata. There is no localization CSV and no invented translation.

This follows the owner-confirmed Beacon Breakwater archive inspected on November 14, 2026: SHA256 `856729c69788cb15340513ee3e911697d1485b66681646e4e5ce860ad3a9db5f`, 28 entries, 26 icons, passing archive CRC readback. It preserves the successful plural filename despite a discrepancy in Google's help prose. Current [Android achievement integration documentation](https://developer.android.com/games/pgs/integrate-achievements#zip-file-guidelines) also names the plural file. [Play Console Help](https://support.google.com/googleplay/android-developer/answer/2990418?hl=en) still uses the singular form.

## Generate and validate

Use Python 3.10 or newer; only its standard library is needed. Run from the project root:

```sh
python tools/build_achievement_import.py --self-test
python tests/test_packaging.py
python tools/build_achievement_import.py
python tools/build_achievement_import.py --check
python tools/build_achievement_import.py --verify marketing/play-games-achievements/cinderbrook-brigade-achievements-google-play.zip
```

The builder validates before writing, reads the completed archive back, and emits `validation-report.json` with per-file hashes and the final ZIP SHA256. `--check` is read-only and requires byte-identical deterministic regeneration from current catalog and icon files. ZIP entry ordering, timestamps, platform flags and permissions are fixed. Entries use stored ZIP compression, retaining the original PNG compression and making archive reconstruction independent of the runner's zlib version. Changing the catalog or icons requires regeneration. `--metadata-only` prepares CSV previews and worksheets while explicitly withholding a ZIP-validation claim.

Validation covers encoding, field count, catalog IDs and unique names/descriptions, exact mappings, types and targets, state and points, missing/unreferenced files, flat paths, PNG signature/chunk CRC/scanline data/dimensions, unique icon bytes, ZIP CRC, source-byte equality, archive limits and reproducibility. Proposed points must be multiples of five from 5 to 200; the game total must not exceed 2,000. Future incremental definitions must specify 1–10,000 steps matching the runtime threshold. [Google's achievement point rules](https://developer.android.com/games/pgs/achievements#points_and_experience_points) informed these checks.

The two official import pages currently disagree about archive capacities. The generator uses their conservative intersection: every file below 1,000,000 bytes, no more than 202 entries, and the whole ZIP below 200,000,000 bytes. This package is well below those caps. It does not rely on the newer page's larger allowances.

## Owner import and ID worksheet

1. Review the catalog's names, descriptions, proposed points, standard types and revealed states. The CSV previews are under `marketing/play-games-achievements/import-files/`.
2. In the correct unpublished Cinderbrook Brigade Play Games project, import the ZIP and review the resulting draft. Default language is English (United States). This document does not perform that action.
3. Record the Console-generated achievement IDs in `achievement-id-mapping-and-points.csv`. Record the three leaderboard IDs in `leaderboard-id-mapping.csv`, using each exact catalog ID to avoid mismatches.
4. Copy the real game, achievement and leaderboard IDs to the corresponding `play_games` fields in `platform/config.json` only when the owner is ready to configure and test the backend. Keep production signing credentials out of the repository. Set `play_games.enabled` only for the configured test/release environment.
5. Test sign-in, offline progress synchronization, each achievement and leaderboard with an authorized backend and correctly signed Android build. Local validation and blank-ID fallback tests do not replace this step.

The generator refuses to overwrite a worksheet containing owner-entered IDs. `--check` allows those final ID cells to be filled while verifying that the catalog definitions in all other cells still match. No worksheet belongs inside the import ZIP.

## Store evidence and local site assembly

`python tools/validate_store.py` checks final artwork, store text, catalog icons and runtime screenshot provenance. It requires genuine Android runtime records for phone, 7-inch and 10-inch virtual/physical profiles. A desktop fixture cannot stand in for an Android capture; emulator screenshots cannot be labelled physical devices. `--allow-pending` is for explicitly incomplete local staging only and is not used by CI.

Every screenshot record's `path` is canonical and relative to the project root, for example `marketing/screenshots/android-phone/home.png`. Capture tools, the review gallery and validation use this same contract; paths remain constrained to the screenshot directory.

`python tools/assemble_site.py build/site --require-clean --expected-sha <commit>` assembles the prepared Web export and styled review with source identity and file hashes. Export Web to `build/site/play/index.html` first. The command does not enable Pages, publish a website, or claim browser gameplay. A verified assembly refuses dirty source or a different commit. Public output filters exclude keys, local logs, private-named files, APK/AAB artifacts and import caches.

For a clean source revision, `runtime_tree_sha256` and its `runtime_files` map hash canonical Git blob contents, making them independent of Windows/Linux checkout newline conversion. `runtime_worktree_tree_sha256` separately records the bytes present in that checkout. Imported caches and ignored SDK installation files are outside the stated source scope. A dirty local assembly is explicitly marked uncommitted and uses working-tree bytes instead of claiming the committed revision's identity.
