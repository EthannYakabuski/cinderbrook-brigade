# Game implementation verification

The following is development evidence, not a claim of physical-device or Play backend verification. Parent handoff evidence records exported Android/Web play separately.

On 2026-11-14, Godot 4.5.1 ran these suites in dedicated temporary user-data directories. No owner save was used. The current markers before Android handoff are `MODEL PASS checks=439`, `PROFILE PASS checks=57` and `UI PASS checks=245`.

The model suite plays all 36 authored campaign incidents and 72 consecutive seeded Daily dates with a simple baseline strategy using the actual heat/water/moisture/spread rules. All clear with three stars. It also completes eight escalating Endless waves. The slowest campaign strategy clear took 38.62 seconds; minimum campaign structure was 82.46%. These are model strategies, not human or Android gameplay. It verifies empty-tank holding cannot refill, release refills, no-input failure, earned-only recovery, duplicate grants, exact continued simulation after snapshot restoration, malformed snapshot rejection and actual upgrade effects.

The profile suite verifies first/seven-day/rollback login behavior, exact affordable purchases, active-run saves and reload, completed reward settlement once, no untouched abandonment or idle-failure payout, separate-date Daily bonuses, campaign-specific achievement metrics, quest claims once, settings persistence, earned-entitlement restart and once-only continuation, invalid-save rejection, preserved corrupt primary bytes, newest staged-write recovery and failed-storage transaction rollback.

The UI suite instantiates the normal game scene and dispatches `InputEventScreenTouch` and `InputEventScreenDrag` through Godot's input system. It tests GUI buttons, direct scene aiming, actual cooling/tank spending/refill, secondary-finger isolation, pause/leave/Resume, focus and ad freezes, all menu areas, music persistence, unavailable-ad denial, pending-earned/dismissed continuation, duplicate callback protection, and phone/tablet button dimensions and viewport bounds. These are engine-injected touch regressions, not emulator touches or physical-device evidence.

Defects found and fixed during implementation:

- Empty-held tanks previously alternated refill and spray, bypassing the lift-to-refill loop. Only release can refill now.
- Endless scoring previously counted earlier-wave prevented embers again. Each stage now pays its own prevention bonus once.
- Save restoration accepted arbitrary extra properties that could overwrite regenerated model parameters. Snapshot fields are now explicitly whitelisted.
- Header labels initially wrapped within horizontal rows and forced the home card below the screen. Single-line row labels and viewport bounds regressions fixed this.
- Godot's emulated GUI mouse could claim the hose before its original touch. Hose handling ignores emulated mouse events and retains the original pointer ID.
- A hidden touch offset could miss the visible target. Direct roof/ground targeting now matches the player's finger.
- Leaving an incident and tapping Back could strand the active run on Home. Back now returns to its paused Resume screen.
- A failed next-wave write could leave the run advanced behind completed-wave controls. The previous snapshot is restored on failure.
- Daily three-star clears could unlock a campaign-specific achievement. That metric now counts campaign clears only.
- Home/Map/Daily starts could bypass a due interstitial transition. All explicit starts now use the same natural transition function.
- Menu buttons could still run during the pre-show ad interval. Shared button dispatch now blocks while a fullscreen ad is pending or visible.

Godot's restricted Windows runtime emitted `Failed to read the root certificate store` in the isolated sandbox; the suites reached their pass markers. This environment warning is distinct from gameplay assertions and must not be presented as a production-services test. One initial invocation omitted temporary user-data isolation, failed creating `user://logs`, and crashed before executing its test script. No save operation ran in that invocation. Subsequent invocations used scoped temporary directories. No helper-error-1223 retry or security-setting change was used.

Run suites from a prepared imported project using `godot --headless --path . --script res://tests/test_model.gd`, the analogous profile script, and `--script res://tests/test_ui.gd -- --qa-profile=user://qa-unique-name.json`. Prefer the repository's isolated validation runner, which supplies fresh per-suite data directories. The world and platform owners maintain their own additional regression suites and counts.

The final Web audio regression passed all 245 UI checks. Nine added assertions cover pause transitions, muted track changes, focus return during ads, repeated frames and the streaming backend. Actual isolated-browser navigation, two campaign clears, upgrade persistence and active-run reload are recorded in VERIFICATION.md. No subjective listening or native input acceptance is implied.
