# Verification and remaining acceptance

This is an acceptance checkpoint for the 14 November project, updated during
15 November UTC. Ordinary Android play, save/restart and test-ad checks now have
recorded evidence, including real earned callbacks and durable recovery through
ad interruption. The final APK passed the recorded emulator prototype scope:
39 audited checks, zero failures, 46 action receipts and 53 independently
inspected action images. All 18 curated public captures passed their separate
artifact/provenance audit. The refreshed local Web smoke checks are also complete.
Exact-commit CI/deployment outcomes are tracked separately.

## Completed evidence

- Godot 4.5.1 model checks: 439 assertions. All 36 campaign incidents and 72 Daily
  dates clear with baseline equipment; eight Endless waves clear. These are
  deterministic model strategies, not human playtesting.
- Save/profile checks: 57 assertions, including corruption recovery, staged
  writes, exact settlement, purchases, calendar rollback and earned continuation.
- UI checks: 299 assertions through engine-injected events, including nine
  audio lifecycle regressions and 37 phone/tablet artwork geometry and resize
  regressions, plus 17 page drag/click checks. The isolated run exited 0 with no strict diagnostics. These are
  engine fixtures, not ordinary Android touchscreen input.
- World checks: 699 assertions. Six themed desktop renderer fixtures passed 215
  checks. Desktop fixture images are not Android gameplay screenshots.
- Platform callback/persistence fixtures: 50 assertions. These do not prove live
  SDK ad delivery, production Play services or backend configuration.
- Achievement archive: 20 Standard/Revealed achievements, 700 proposed points,
  22 flat entries; deterministic rebuild, PNG/CSV/mapping and ZIP CRC validation.
- Both Android packages were built with the installed engine/toolchain. The
  package and packed-art receipts identify exact artifact hashes. All 23 badge
  textures decoded from both packages matched the corrected source pixels.

## Actual Web observations

The single-threaded Web export was served locally and operated in the supported
isolated in-app browser. Ordinary pointer input cleared incident 1 with three
stars: 98% structure, 35 seconds remaining, 2,173 points, 75 supplies and 64 XP.
Reopening the same origin after the task interruption showed 110 supplies and
incident 2 unlocked. The initial gift and settlement were not paid twice.

Further focus/reload/navigation testing exposed a real Godot Web audio failure:
`BaseAudioContext.createBuffer(2, 2194285, 48000) failed`. Reassigning
`stream_paused=false` every frame made Godot 4.5.1's sample backend restart and
duplicate the full music buffer. The correction uses Web streaming music and
changes pause state only when needed. Native music and short effects retain
their intended playback modes. The rebuilt Web export passed ordinary garage
purchase, menu navigation, mute/unmute, track changes and active-run reload
testing without console warnings or errors. Incident 2 was cleared by pointer
holds with three stars, 95% structure, 33 seconds remaining, 2,217 points,
81 supplies and 73 XP. A 55-supply copper-pump purchase persisted; the following
Daily run reloaded into an explicit paused Resume screen. This is browser
runtime evidence, not native touch or subjective listening acceptance.

Further ordinary-pointer testing let a Daily incident expire: the unavailable
reward button granted nothing, and ending the untouched incident paid zero XP,
supplies or points. Endless Watch wave 1 cleared with two stars, 79% structure,
10 seconds remaining and 2,120 points. Banking paid 111 supplies and 125 XP.
Reload then showed rank 2, 247 supplies and incident 3 available, without a
duplicate settlement. The rebuilt browser tab recorded no warnings or errors
through these tests. Garage, Settings, About/licenses, Journal/online-unavailable
feedback, Neighborhoods, Daily, play/pause/recovery/results and Endless entry
were inspected. After final native acceptance, the HTML review was regenerated
and its assembled local site was inspected in the supported isolated browser.
The hero and splash were readable, the native PASS box matched the receipt,
and the phone, seven-inch and ten-inch selectors each displayed their six
curated images. The inspected console warning/error lists were empty. These
observations come from the coordinator's browser tool trace; no browser
screenshot file is claimed. Live Pages verification remains separate.

The subsequent isolated Web export now includes the Home artwork and touch-scroll
fixes. It passed single-threaded WebAssembly/PCK validation with all 712 entry
checksums correct and no unwanted payload. Its 875 copied source inputs remained
unchanged during export. The PCK is 19,230,432 bytes with SHA-256
`b233acb180d31b67d901bdce2fd171472df4222ad1de7a67a83d1d3a1398f78f`.
Those verified files were promoted to the local served folder after archiving
and hash-checking its previous files. The preceding browser observations apply
to the earlier export, not automatically to these new bytes.

The coordinator then opened the refreshed game in the supported isolated browser
at a 430 by 900 viewport. It retained rank 2, 292 supplies, incident 3 and a
rank-one pump; Garage showed 262 XP. Mouse-wheel scrolling exposed all five
upgrades. Ordinary mouse dragging did not scroll, which does not establish or
disprove native touch-drag behavior. Three held pointer clicks on visible roofs
cleared incident 3 with three stars, 95% structure, 40 seconds remaining,
2,402 points, 87 supplies and 82 XP. Home followed by reload retained rank 3,
379 supplies and incident 4, without a second settlement. Two inspected console
observations contained no warnings or errors.

Music Off persisted through reload and the Settings screen, then ordinary input
restored Music On. Incident 4 was started through Home, paused with its Pause
control and reloaded into an explicit Resume screen. After Resume, three held
target clicks cleared it with three stars, 96% structure, 44 seconds remaining,
2,460 points, 87 supplies and 82 XP. Final Home showed rank 3, 466 supplies and
incident 5 available. Console warning/error lists were empty after reload,
after this second win and at finish. These interactions exercised the music
lifecycle without the earlier audio-buffer failure; subjective listening and
sound quality were not assessed. The viewport was restored to 1280 by 720 after
the 430 by 900 test. Covered local smoke checks are complete; all authored
content was not played, and the eventual Pages origin still needs separate
verification.
These observations are recorded in [refreshed Web acceptance](web-refresh-acceptance.json)
from the coordinator's direct browser tool trace; no screenshot file is claimed.
The documentation worker's earlier unavailable-browser attempt is retained as
history and is not presented as a continuing coordinator access blocker.

## Android environment and evidence route

The test APK installed on a task-owned, read-only API 30 x86 emulator. Its first
launch failed before gameplay because the emulator exposed only OpenGL ES 2.
The installed emulator's feature configuration documented that disabled dynamic
version detection assumes ES 2. A temporary command-line GLES detection option
enabled successful cold startup; no persistent graphics or security settings
were edited. This environment repair is not game-play acceptance.

Two Windows Computer Use application-control requests expired unanswered while
the owner was away; neither sent native input. A later owner-present official
request succeeded. Windows capture nevertheless failed with
`FrameArrived timed out: timed out waiting on channel`, and a later foreground
retry failed with `window capture timed out: timed out waiting on channel`.
Those Windows capture attempts stopped. The owner subsequently authorized the
established Android SDK testing route after control approval was confirmed.
The native observations below use ordinary ADB touchscreen input and unmodified
Android framebuffer captures on the task-owned emulator. They do not use a
replacement Windows input driver, injected game state or model simulation.

A separately labeled, read-only Android framebuffer diagnostic showed a black
game area and a visible Google test banner. Fresh startup logs recorded the
SwiftShader shader-link failure `Fragment shader active uniforms exceed
GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`, matching Godot issue 109550. Relaunching
only the task-owned read-only emulator with the supported per-session `-gpu host`
option produced a clean Godot startup on NVIDIA RTX A400 and a fully rendered
home screen with the same unchanged APK. No game graphics limits, persistent
emulator settings or security settings were changed. See the sanitized
[render diagnostic receipt](android-render-diagnostic.json). These diagnostic
images are not gameplay captures and do not satisfy store acceptance.

## Baseline Android observations

The observations in this section used the installed APK with SHA-256
`bdf5190d962015ab72fbc0a7a4a9e415b747020f102d5e2154ee3d986c73a85d`.
They must not be reassigned to a later build. Local action receipts are retained
under `build/native/actions/`, with a separate independent audit in
`build/native/acceptance-audit.json`. Public image metadata is in
[the capture manifest](../marketing/screenshots/provenance.json); the sanitized
[native acceptance summary](native-acceptance.json) identifies its own cutoff.

- An untouched incident timed out and settled for zero supplies, XP, score and
  stars. It did not increment the played-round ad cadence.
- A paused run remained byte-equivalent as a saved profile across a recorded
  34.010169-second interval. Cold stopping and restarting the app restored the
  same active run and an explicit Resume screen. A legitimate next-day login
  gift changed supplies by 45; no settlement was duplicated.
- Incident 1 cleared with ordinary touchscreen holds: three stars, 99%
  structure, 40 seconds remaining, 2,228 points, 75 supplies and 64 XP.
- Holding the spray for 14 seconds used exactly 100 water with 7.7 seconds of
  actual spraying. Release snapshots rose from 32.9 to 100 water without more
  spray. Held-capacity behavior is inferred from those cumulative metrics;
  there is no framebuffer captured at exactly zero water. The later timeout
  remained a genuine failure.
- Incident 2 cleared on the logical seven-inch layout with three stars, 95%
  structure, 36 seconds remaining, 2,250 points, 81 supplies and 73 XP. The
  resulting profile held 236 supplies, 137 XP and two three-star campaign grades.
- Incident 3 was exercised with ordinary holds and cooled two hotspots before
  timing out. This is recorded as a failure, not a completion.

The native Google test banner rendered on menu/result screens. Two opt-in test
rewarded ads presented and dismissed without an earned callback. The saved
failed run, entitlement flags, supplies and XP stayed unchanged; no reward was
granted merely for dismissal or elapsed advertisement time.

A subsequent opt-in test rewarded ad delivered the actual SDK event order
`rewarded_presented`, `rewarded_earned`, then `rewarded_dismissed` with earned
context. While the ad remained visible, the saved failed run changed only by
recording the earned entitlement; simulation time did not advance. Dismissal
restored the same run with 30 seconds remaining, 80 water and repaired structure
(35 points per object, capped at 100). The interface explicitly required Resume.
`recovery_used` became true and the pending entitlement was consumed. Supplies
and XP remained 236 and 137. Cold restart preserved that recovery, the exact
elapsed time and limit, water, structure and flags without granting it again.
These tests used the original installed APK; the earlier unearned dismissals
are not evidence of an SDK defect or proof that a dependency update fixed one.
Ordinary play after Resume then cleared incident 3 with three stars, 99%
structure, 28 seconds remaining, 2,386 points, 87 supplies and 82 XP. Returning
Home retained the full settled profile at 323 supplies and 219 XP. A visible
55-supply Copper pump purchase changed the balance to 268 and pump rank from
0 to 1, with no change to XP or the last settlement. Later baseline checks
covered Daily success, an Endless wave and purchase/quest/settings retention;
their complete observations remain in the native receipt's `artifact_history`.

The real test interstitial presented at the next natural transition after three
settled played rounds. Saved state remained unchanged while it was visible.
Dismissal created the next incident paused at zero elapsed time, with full water.
The persisted `round_count` and `consumed_round` were both 3. Cold restart retained
that consumed cadence, the same paused run and the same supplies/XP; the ad was
not replayed. Native `interstitial_presented` and `interstitial_dismissed` events
were recorded separately from the profile observations.

Genuine phone gameplay, failure and result captures and seven-inch active
gameplay are recorded. The seven-inch profile is 1200 by 1920 at 320 dpi, a
logical emulator configuration, not a physical tablet. One early tablet frame
showed a failure result after a missed tap during display reconfiguration; its
caption was corrected rather than claiming active play. The separately captured
`tablet7-incident2-gameplay.png` shows the running second incident. Early loading
and missed-button observations with rejected captions remain local diagnostics
and are excluded from store provenance. Capture timestamps now bracket actual
framebuffer acquisition; the earliest phone failure receipt lacks the newer
start timestamp and retains that historical limitation.

The seven-inch inspection found a cropped Home title. Source now preserves the
original artwork's aspect ratio, aligns it to the top and centers it
horizontally; the 282-check UI run passed. The refreshed APK then showed the
complete title on both seven-inch and ten-inch layouts. Both refreshed Android
packages contain that correction,
the touch-scroll fix below and the AdMob SDK dependency update. Static package
inspection and all 23 packed badge checks passed on the replacement APK
`1488f7ec33d146ef869c91890c4f46c0634e300d0bd3d897d93c1d030a4190d4`
and AAB
`d49018c248dfc3de6af4df4ce77bd5f52477ad1a08b7e75d75ff21657cc830b6`.
The APK has a valid development signature; the AAB remains explicitly unsigned.
See [current package evidence](android-package-evidence.json) and
[packed artwork evidence](packed-art-evidence.json). Baseline observations retain
their earlier identity in [archived package evidence](android-package-evidence-baseline.json)
and the native summary's `artifact_history`. Earlier screenshots do not verify
the replacement packages' runtime behavior.

Native inspection also found that dragging inside Garage, Neighborhoods and
Journal content did not move the list, while dragging the scrollbar did.
The isolated engine regression reproduced three blocked card drags and a
campaign button activation after a drag. Godot's panel controls default to
stopping mouse-event propagation, whereas the native ScrollContainer gesture
needs those events to reach it ([panel source](https://github.com/godotengine/godot/blob/4.5-stable/scene/gui/panel_container.cpp),
[scroll gesture source](https://github.com/godotengine/godot/blob/4.5-stable/scene/gui/scroll_container.cpp)).
The correction makes scrolling-page descendants pass those events upward while
preserving decorative controls that ignore input. Other screens retain their
existing behavior. The full UI suite now passes 299 assertions, including
content dragging in all three pages, button-drag cancellation and an ordinary
campaign-button tap. Ordinary native input on the replacement APK subsequently
verified all three page drags, map-button drag cancellation and an intended
incident-button tap. Neither source fixtures nor mouse-wheel Web navigation
are substituted for that native retest.

## Current Android package observations

The current tests use APK SHA-256
`1488f7ec33d146ef869c91890c4f46c0634e300d0bd3d897d93c1d030a4190d4`.
Its installed bytes match the canonical export. Installing over the baseline
preserved the complete profile: paused run 8, 597 supplies, 603 XP, rank-one pump
and all four presentation settings enabled. Cold launch kept the active state
and explicitly required Resume; the paused profile remained identical across a
later interval of approximately 270 seconds.

- Ten-inch ordinary play cleared incident 4 with three stars, 95% structure,
  38 seconds and 2,390 points. Exactly 87 supplies and 82 XP produced totals of
  684 and 685. Home/Garage navigation retained the settled profile.
- Seven-inch Home and gameplay rendered correctly. Phone touch holds cooled
  targets, and a natural timeout exposed the optional recovery choices.
  Android Home paused an active incident; a 15-second wait and HOT return kept
  the complete profile unchanged and required Resume.
- An unearned rewarded dismissal kept the failed run and wallet unchanged.
  A subsequent actual test ad emitted presented, earned, then dismissed with
  earned context. While open, only the durable earned entitlement changed;
  simulation did not advance. Dismissal applied 30 additional seconds, 80 water
  and 35 structure repair capped at 100, exactly once, then required Resume.
  Cold restart after application retained that recovery without a second grant.
- Ordinary phone play after recovery won with two stars, 82% structure,
  12 seconds and 2,174 points. Exactly 91 supplies and 100 XP produced totals
  of 775 and 785. Cold restart retained the settlement without duplicate pay.
- An intentional map-button tap started incident 1; ordinary phone play won
  three stars, 99% structure, 38 seconds and 2,211 points. A later seven-inch
  result capture displays that same phone-played win; it is not claimed as a
  separately played tablet victory.
- A 135-supply pump purchase raised rank one to two and displayed 116% cooling.
  The complete profile survived cold restart and Daily equipped the new rank.
  Claiming the earned 20-hotspot quest separately paid 35 supplies and 50 XP.
- At the ninth played-round transition, Play Daily presented a genuine test
  interstitial. The complete profile froze and no next run existed while it
  showed. Dismissal created Daily at zero elapsed time with explicit Resume.
  Cold restart retained that state and consumed round-nine cadence.
- A raw framebuffer captured water at 0/100 and the lift-to-refill instruction
  during an actual 30-second stationary touch on the seven-inch Daily scene.
  Water use remained one tank and actual spray time 7.7 seconds. After release,
  saved water rose to 43.4 and later 100. The Daily then failed naturally at its
  72-second limit; its failure-choice frame does not establish a settlement.
- Force-stopping a presented rewarded ad before any earned callback retained
  the failed run, false entitlement flags and unchanged supplies/XP on restart.
  This is separate from closing a visible ad or restarting after recovery.
- Force-stopping a different ad after a genuine earned callback, while its
  credit was saved and unused and no dismissal was recorded, applied the
  continuation once on cold restart. A second restart retained the profile
  apart from save sequence, with no duplicate recovery or wallet change.
- Endless Watch continued from its first cleared wave into a second wave of
  the same run. Ordinary touches cleared 11 total targets for 4,824 points.
  Banking paid exactly 175 supplies and 204 XP, leaving 925 supplies and
  1,103 XP, clearing the active run and recording two waves. Cold restart kept
  the complete profile identical, including save sequence 623, without another
  payout.
- Settings, privacy response, unconfigured Play feedback and About/licenses
  were inspected. Privacy displayed the test-ad response; no regional consent
  form or production backend success is claimed.

The current manifest contains 18 selected replacement images, six each for the
phone, seven-inch and ten-inch logical emulator profiles. Six baseline images
remain separately identified and excluded from the review gallery. Captions
distinguish active gameplay, failure choices, results and menu frames. The
phone is 1080x1920 at 420 dpi, seven-inch 1200x1920 at 320 dpi, and ten-inch
1600x2560 at 300 dpi. These are emulator display profiles, not physical devices.

Final native acceptance passed for this recorded emulator prototype scope at
2026-11-15 02:44:43 UTC. The [native receipt](native-acceptance.json), SHA-256
`404c85c81b28746a12ee50a2ff05e02771f52aa2e4c9f53567c44eca09aea1f6`,
is the source of truth for the audit. Final installed APK identity remained
unchanged. The controller restored the original display configuration and
closed only the task-owned emulator, preserving the owner editor and shared
ADB server. No further emulator operation is needed for these recorded checks.

Review regeneration and local visual inspection are complete. Exact-commit
CI/live deployment remain separate delivery checks. There is no physical-device,
subjective listening, thermal or real Play backend acceptance. The APK's valid
development signature and the companion AAB's explicitly unsigned result were
checked separately; jarsigner exit zero for the unsigned AAB is not a signing
pass or a Play submission artifact.

Initial gifts, the Daily first-clear bonus and all four native settings toggles
were exercised on the baseline APK. The replacement preserved those saved values;
those earlier executions are not relabeled as fresh final-package tests.

## Design reconciliation

The original prompt and checklist are preserved. Ordinary play uses direct
roof targeting under the finger, replacing the proposed offset reticle. Earned
continuation retains normal grading rather than the initially proposed
two-star cap, so accepting it does not impose an ad-related score penalty.
Neither adjustment is disguised as meeting the literal superseded wording.
All campaign coverage beyond the manually exercised incidents is established
by the declared model strategies, not by a claim that every level was played.

## Repository and hosting

The source repository is public. A privacy audit found no detected credentials,
private paths or production service IDs among the outgoing files. Google test
ad identifiers and disabled blank Play mappings are deliberate.

Strict store validation requires genuine native screenshot provenance for all
three profiles. Captures for all three now exist with explicit APK identities;
that alone does not establish full runtime acceptance. CI must not be described
as passing merely because local code-level tests passed. The repository's
[Actions runs](https://github.com/EthannYakabuski/cinderbrook-brigade/actions)
and final handoff identify the exact source revision and actual job results.
No test or provenance rule has been relaxed to hide missing acceptance.

Pages was initially off. The owner subsequently explicitly authorized setup;
GitHub Actions is now the configured Pages source and `PAGES_DEPLOY_ENABLED` is
`true`, verified by API readback. The deployment workflow requires successful
`validate` and `android` jobs for the exact main commit. Configuration and local
site assembly do not establish deployment or live-origin gameplay; those
outcomes require their separate run and browser evidence. No Google Play
publication/import, purchases, personal-browser control or schedule changes
were performed.

## Model selection

Substantive creation and verification workers were explicitly requested as
`gpt-6-astra` with `ultra` reasoning, and those requests were accepted. The tools
do not independently expose the serving backend's actual model identity; no
stronger attestation is claimed.
