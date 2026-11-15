# Defects found during creation

Final verification receipts identify the exact tested build and environment.
The current APK is `1488f7ec33d146ef869c91890c4f46c0634e300d0bd3d897d93c1d030a4190d4`;
baseline observations remain separately identified in the native receipt.

| Finding | Correction | Verification |
| --- | --- | --- |
| Holding the hose with an empty tank could refill it between spray frames. | Only a released hose may refill; held-empty remains empty. | Model regression passed. On the current APK, a concurrent genuine frame showed water 0/100 during a 30-second held touch; water rose only after release and later reached 100. |
| Endless Watch could count earlier waves' prevented-ember bonuses again. | Score prevention once per wave before adding the banked total. | Model regression passed. Current native play cleared two waves/11 targets, banked 4,824 points for exactly 175 supplies/204 XP, and retained the complete profile through cold restart without duplicate payout. |
| Unknown JSON snapshot keys could overwrite regenerated model fields. | Reject unexpected keys and preserve validated derived rules. | Model/profile malformed-snapshot regressions passed. |
| Pause, Leave, then Back could strand a saved incident behind Home. | Return to the paused incident, preserving an explicit Resume path. | Engine UI regression passed. Current native background and cold-restored active runs also showed explicit Resume; they are broader lifecycle checks, not a replay of every navigation sequence. |
| A failed save while advancing Endless Watch could mismatch UI and run. | Roll back the mutation or retain a coherent paused retryable state. | Profile and engine UI failed-write regressions passed; no native storage failure is claimed. |
| A Daily/Endless three-star result could award a campaign-only achievement. | Increment the campaign-perfect metric only for campaign clears. | Profile/achievement regressions passed. |
| Destroyed objects hid fire visuals while their heat still counted. | Keep visible smolder/hot-ring cues until required heat is extinguished. | World tests and desktop renderer fixtures passed. Final native images are labeled separately from those fixtures. |
| Early world captures were washed out and flames were too faint. | Revise lighting, visible flames, scenery and water feedback. | Revised desktop fixtures passed 215 checks. Ordinary current-APK gameplay and genuine phone/tablet images were visually inspected; physical-device display/performance remains untested. |
| Several achievement atlas crops included the next row's badge tip. | Use measured row boundaries and preserve the complete badge. | Final icons visually reviewed; all 23 corrected source textures were decoded and pixel-verified inside both current APK and AAB. |
| Godot imported the achievement CSV as a translation resource. | Exclude non-runtime marketing/docs/review/public/tools from import. | Scoped `.gdignore` files added; subsequent isolated imports and Android/Web exports passed. |
| Web focus/reload/navigation repeatedly allocated the complete music buffer. | Stream Web music and update pause state only when it changes; retain intended native playback modes. | The UI suite now passes 299 checks, including nine audio lifecycle regressions. Refreshed isolated-browser wins, menu navigation, mute/reload/restore and active-run reload completed with no observed warning/error entries. No subjective listening claim. |
| Seven-inch Home cropped the title in the splash artwork. | Preserve aspect ratio, align the art to the top and center it horizontally. | Artwork geometry/resize fixtures passed; current-APK seven-inch and ten-inch Home frames show the complete title. |
| Dragging Garage, Neighborhoods or Journal card contents did not scroll; a dragged campaign button could activate. | Let scrolling-page descendants pass touch-emulated mouse events to ScrollContainer while retaining decorative input-ignore controls. | The isolated UI fixture reproduced the failures before the fix and passed 299 checks afterward. Current-APK ordinary touch verified all three content drags, map-button drag cancellation and intentional incident selection. |

Two design adjustments are explicit: direct roof targeting replaced the proposed
offset reticle, and rewarded continuation keeps normal grading rather than the
initially proposed two-star cap. Neither is concealed as meeting the superseded
wording.

The AdMob bridge dependency was refreshed to SDK 1.6.0 for a documented upstream
late earned-callback ordering risk. The earlier unearned ad dismissals did not
prove that defect: an actual earned callback also succeeded on the baseline APK.
Current-package native tests verify earned and unearned dismissal, pause/restart,
and process interruption both before and after earned credit without inventing
an attribution for the earlier ads.

The emulator's ES2/SwiftShader rendering failures and Windows capture timeouts
were environment findings. The supported task-local host-GPU emulator and
authorized Android SDK test route produced genuine runtime evidence without
changing game quality, persistent graphics/security settings or acceptance
gates. See [verification](VERIFICATION.md) for exact environment history and
[native acceptance](native-acceptance.json) for the current audit cutoff.
