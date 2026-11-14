# Defects found during creation

These are development findings, not a claim that Android acceptance has finished.
Final verification receipts identify the exact tested build and environment.

| Finding | Correction / acceptance requirement | Evidence status |
|---|---|---|
| Holding the hose with an empty tank could refill it between spray frames. | Only a released hose may refill; held-empty remains empty. | Found by independent model review; regression being verified. |
| Endless Watch could count earlier waves' prevented-ember bonuses again. | Score prevention once per wave before adding the banked total. | Found by independent model review; regression being verified. |
| Unknown JSON snapshot keys could overwrite regenerated model fields. | Reject unexpected keys and preserve validated derived rules. | Found by independent save review; malformed snapshot regression required. |
| Pause → Leave → Back could strand a saved incident behind Home. | Return to the paused incident, preserving an explicit Resume path. | Found by independent UI review; actual input regression required. |
| A failed save while advancing Endless Watch could mismatch UI and run. | Roll back the mutation or retain a coherent paused retryable state. | Found by independent transaction review; failed-write regression required. |
| A Daily/Endless three-star result could award a campaign-only achievement. | Increment the campaign-perfect metric only for campaign clears. | Found by independent catalog review; regression required. |
| Destroyed objects hid fire visuals while their heat still counted. | Keep visible smolder/hot-ring cues until required heat is extinguished. | Found by independent renderer review; rendering regression required. |
| First world captures were washed out and flames were too faint. | Revise environment lighting, visible flames, scenery and water feedback. | First actual desktop fixture images rejected; recapture required. |
| Several achievement atlas crops included the next row's badge tip. | Use measured row boundaries, preserve the complete badge, inspect final icons. | Revised and visually inspected by art owner; final root review pending. |
| Godot imported the achievement CSV as a translation resource. | Exclude non-runtime marketing/docs/review/public/tools from import. | Scoped `.gdignore` files added; next clean import must pass. |

An initially proposed reduced star grade for rewarded continuation was deliberately
removed before acceptance. Earned continuation receives normal grading based on
actual final performance. This is an intentional design correction, not a defect.
