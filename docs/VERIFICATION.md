# Verification and remaining acceptance

This is an implementation and acceptance checkpoint, not a completed native
acceptance claim. The application, authored content, exports and store assets
exist. Required ordinary Android gameplay, test-ad interaction and native
phone/tablet screenshot acceptance remain unfinished.

## Completed evidence

- Godot 4.5.1 model checks: 439 assertions. All 36 campaign incidents and 72 Daily
  dates clear with baseline equipment; eight Endless waves clear. These are
  deterministic model strategies, not human playtesting.
- Save/profile checks: 57 assertions, including corruption recovery, staged
  writes, exact settlement, purchases, calendar rollback and earned continuation.
- UI checks: 245 assertions through engine-injected events, including nine
  audio focus, mute and backend lifecycle regressions. The isolated run exited 0.
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
were inspected. The HTML review was visually checked in the isolated browser;
it explicitly reports zero native captures.

## Android execution and control limit

The test APK installed on a task-owned, read-only API 30 x86 emulator. Its first
launch failed before gameplay because the emulator exposed only OpenGL ES 2.
The installed emulator's feature configuration documented that disabled dynamic
version detection assumes ES 2. A temporary command-line GLES detection option
enabled successful cold startup; no persistent graphics or security settings
were edited. This environment repair is not game-play acceptance.

The Windows Computer Use application-control request timed out without an
approved response. One separately authorized fresh request also timed out. No
native touch input was sent, no alternate input driver bypassed that gate, and
no Android gameplay/results/tablet image is being represented as captured.
The owner was away. Native input, ad dismissal/earned callbacks in the real SDK,
cold save/reload after play and phone/7-inch/10-inch runtime screenshots remain
required. There is no physical-device, subjective listening, thermal or real
Play backend acceptance.

## Repository and hosting

The source repository is public. A privacy audit found no detected credentials,
private paths or production service IDs among the outgoing files. Google test
ad identifiers and disabled blank Play mappings are deliberate.

Strict store validation requires genuine native screenshot provenance. It
correctly fails while that evidence is absent, and the required CI workflow
must not be described as passing merely because code-level tests passed.
No test or provenance rule has been relaxed to hide the missing acceptance.

Pages was inspected: hosting was off, the account had repository administration
and push permission, and the deployment variable was absent. The prepared
manual workflow has not been activated. No hosting mutation, Google Play
publication/import, purchases, personal-browser control or schedule changes
were performed.

## Model selection

Substantive creation and verification workers were explicitly requested as
`gpt-6-astra` with `ultra` reasoning, and those requests were accepted. The tools
do not independently expose the serving backend's actual model identity; no
stronger attestation is claimed.
