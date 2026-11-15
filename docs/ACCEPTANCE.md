# Initial acceptance checklist

This checklist records intended acceptance before implementation. A checked automated item is not native gameplay evidence. Final test receipts and root handoff must state each actual environment and limitation.

## Recorded progress, 15 November 2026 UTC

This is the continuing 14 November project; no new Sunday production run is
implied. The original criteria below are the preserved preimplementation list,
not a current pass/fail tally. The table records actual outcomes. The final APK
passed the recorded emulator prototype acceptance: 39 audited checks, zero
failures, 46 action receipts and 53 independently inspected action images.
The 18 curated public captures passed their separate identity/provenance audit.
Local Web smoke checks also passed. Review/CI/deployment are separate delivery
checks; this acceptance does not establish physical-device or production release
readiness.

| Area | Observed evidence | Still required |
| --- | --- | --- |
| Source and content | 439 model, 57 profile, 299 UI and 699 world assertions; 50 platform fixtures. All campaign content and representative Daily/Endless content clear in model tests. Current APK/AAB source-input and packed-icon receipts match the corrected runtime. | Model solutions are not ordinary native play. All 36 incidents have not been played manually. |
| Ordinary native play | Replacement APK: campaign wins on phone and ten-inch layouts; natural campaign/Daily failures; a framebuffer captured water at zero during a held touch, followed by release refill; Android Home pause and cold-restored active state; settled payout and a rank-two pump purchase survive restart. Corrected Garage, Neighborhoods and Journal content drags work; dragging a map button cancels activation and an intentional tap starts its incident. Two Endless waves, 11 targets and 4,824 points banked exactly 175 supplies/204 XP; cold restart retained the whole settled profile. | Recorded emulator scope passed. Broader baseline Daily bonus/first-gift/settings-toggle observations retain their earlier artifact identity. |
| Native advertisements | Replacement APK: visible Google test banner; round-nine natural-break interstitial freezes the profile, dismisses to a zero-time paused Daily and retains consumed cadence through restart. Unearned dismissal grants nothing. Actual earned callback durably credits one paused continuation; applied recovery survives restart and the recovered run wins. Killing an open ad before earned grants nothing; killing after earned but before dismissal applies recovery once on restart and a second restart does not duplicate it. | Production services and regional consent remain unverified. |
| Runtime images | Eighteen unmodified, selected replacement-APK images, six per phone/seven-inch/ten-inch profile, passed final hash/source/provenance checks. Six baseline images remain separately identified and excluded from the review. Gameplay, menus and result/failure captions distinguish what each frame actually proves. | Regenerate and inspect the styled review. A seven-inch result displays a phone-played win and is labeled accordingly. |
| Web | Refreshed export: all 712 packed-entry checks; ordinary incident-3 and incident-4 three-star wins; Garage wheel navigation; settlement reload; explicit paused-run reload/Resume; persisted Music Off and restored On. Final Home: rank 3, 466 supplies, incident 5. All inspected console lists were clear. Earlier export also covered broader Daily/Endless areas. | Verify the live Pages deployment separately. Covered local smoke checks are complete; mouse-wheel navigation does not prove native touch dragging, and subjective audio was not assessed. |
| Delivery | Canonical APK/AAB and refreshed Web export are promoted and hash-verified; all 23 corrected packed badge textures match both Android packages. Store art and a validated Beacon-format achievement ZIP exist; the repository is public. | Reviewed native gallery, final source reconciliation, exact-commit passing CI and verified Pages deployment. |

See [the verification record](VERIFICATION.md) for exact outcomes and limits.
There is no physical-device, subjective listening or production Play backend
acceptance. The current AAB is explicitly unsigned.

Two design details changed during implementation: aiming is directly at the
visible roof under the finger rather than the proposed offset reticle, and an
earned continuation retains normal star grading rather than imposing the
initially proposed two-star cap. The recorded ordinary play tests use those
implemented rules. Music lifecycle and persisted settings were tested, but the
subjective quality of music, effects and haptics remains unassessed.

## Original acceptance criteria

- [ ] Godot 4.5.1 Compatibility, original identity/package, portrait responsive UI and graceful Web services fallback.
- [ ] Fresh brief/queue/reference/asset review; no active game overlap; original licenses retained.
- [ ] Complete initial vector written before game code.
- [ ] Obvious hold/drag water and release/refill loop, readable offset reticle, visible damage/heat/wetness.
- [ ] Thirty-six individually authored incidents across six rich Kenney districts; generous early teaching.
- [ ] Same-model baseline strategy clears all campaign and representative daily content; failure remains possible.
- [ ] Endless Watch, seeded Daily, campaign unlocks and real filled/empty star grading.
- [ ] XP/rank, five upgrades, seven-day login, three daily quests, 20 achievements and three boards.
- [ ] Atomic validated versioned saves, backup/corrupt preservation, active resume, idempotent settlements and purchases.
- [ ] No untouched abandonment payout, clock rollback duplicate, ad/background simulation or fake Web reward.
- [ ] Official test AdMob IDs and disabled/blank production Play placeholders; optional earned-only one-time emergency continuation.
- [ ] Banner safe space and every-third completed-round interstitial; consent/privacy path and unavailable-service messaging.
- [ ] All screens and controls exercised, including pause, failure, results, map, garage, daily, journal, settings, privacy and license text.
- [ ] Distinct district music, satisfying spray/extinguish/refill cues and persisted accessible settings.
- [ ] Native phone, 7-inch and 10-inch emulator gameplay evidence; ordinary touch, success/failure/save/reload; honest physical-device limits.
- [ ] Supported isolated-browser Web gameplay and fallback; no personal Edge or security-setting changes.
- [ ] APK/AAB and Web exports; store/feature/splash/icon assets and complete descriptions/tags.
- [ ] Proven-format achievement ZIP with deterministic generator/validator, CSV/icon/points/CRC checks and ID worksheet.
- [ ] Styled HTML review uses genuine labeled runtime images, plus clearly separate splash artwork.
- [ ] Outgoing secret/private-file inspection, public repository, exact-final-commit CI evidence; no inferred Pages-setting approval.
- [ ] Final defect/fix/retest evidence and remaining limitations recorded; schedules and unrelated files preserved.
