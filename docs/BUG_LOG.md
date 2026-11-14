# Defects found during creation

These are development findings, not a claim that Android acceptance has finished.
Final verification receipts identify the exact tested build and environment.

| Finding | Correction / acceptance requirement | Evidence status |
|---|---|---|
| Holding the hose with an empty tank could refill it between spray frames. | Only a released hose may refill; held-empty remains empty. | Verified by the 439-assertion model suite. |
| Endless Watch could count earlier waves' prevented-ember bonuses again. | Score prevention once per wave before adding the banked total. | Verified by the 439-assertion model suite. |
| Unknown JSON snapshot keys could overwrite regenerated model fields. | Reject unexpected keys and preserve validated derived rules. | Verified by model/profile malformed-snapshot regressions. |
| Pause → Leave → Back could strand a saved incident behind Home. | Return to the paused incident, preserving an explicit Resume path. | Verified by engine UI regressions; native input remains gated. |
| A failed save while advancing Endless Watch could mismatch UI and run. | Roll back the mutation or retain a coherent paused retryable state. | Verified by profile and engine UI failed-write regressions. |
| A Daily/Endless three-star result could award a campaign-only achievement. | Increment the campaign-perfect metric only for campaign clears. | Verified by profile/achievement regressions. |
| Destroyed objects hid fire visuals while their heat still counted. | Keep visible smolder/hot-ring cues until required heat is extinguished. | Verified by world tests and desktop renderer fixtures. |
| First world captures were washed out and flames were too faint. | Revise environment lighting, visible flames, scenery and water feedback. | Revised desktop fixtures passed 215 checks and visual review; native capture pending. |
| Several achievement atlas crops included the next row's badge tip. | Use measured row boundaries, preserve the complete badge, inspect final icons. | Final icons visually reviewed; all 23 source pixels verified inside final APK and AAB. |
| Godot imported the achievement CSV as a translation resource. | Exclude non-runtime marketing/docs/review/public/tools from import. | Scoped `.gdignore` files added; subsequent imports and three exports passed. |

An initially proposed reduced star grade for rewarded continuation was deliberately
removed before acceptance. Earned continuation receives normal grading based on
actual final performance. This is an intentional design correction, not a defect.

The actual Web run exposed repeated full-buffer allocation when music pause state was reassigned each frame. Web music now streams, and pause is applied only on transitions. The 245-check UI suite and rebuilt browser gameplay/reloads passed without console warnings or errors. Native music acceptance remains pending.
