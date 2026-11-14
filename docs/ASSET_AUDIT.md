# Asset selection and visual contract

The local Kenney library was freshly inventoried on 2026-11-14 before implementation: 44 packs, 24,675 files, 1,287 GLB models, 14,557 PNG images and 498 OGG sounds. All 44 supplied pack license files identify Creative Commons Zero. Original third-party notices accompany the selected assets in `LICENSES/`; original project work has its separate project license.

The review considered the previous driving, skating, harbor-towing, quarry, railway, shop, room-layout and irrigation concepts. Cinderbrook Brigade uses a continuous water-hose firefighting loop. Its miniature neighborhoods are composed from selected models, rather than substituting geometric placeholders for available Kenney art.

## Selected sources

| Project folder | Original Kenney pack | Purpose |
| --- | --- | --- |
| `assets/kenney/car` | Car Kit 3.1 | Fire engine, road cones, parked vehicles |
| `assets/kenney/suburban` | City Kit Suburban 2.0 | Bright houses, hedges, fences, planters and paths |
| `assets/kenney/industrial` | City Kit Industrial 2.0 | Warehouse models, containers, water tower and equipment |
| `assets/kenney/nature` | Nature Kit | Oak/pine/autumn trees, bushes, rocks and campsite scenery |
| `assets/kenney/survival` | Survival Kit 2.0 | Tents, crates, barrels, camp equipment and wooden scenery |
| `assets/kenney/market` | Mini Market | Fairground fruit and bread stalls |
| `assets/kenney/roads` | City Kit Roads | Street model options retained for environment iteration |
| `assets/kenney/particles` | Particle Pack | Actual flame, smoke, water-circle, spark and scorch textures |
| `assets/kenney/smoke` | Smoke Particles | White steam/puff sprites |
| `assets/kenney/ui` | UI Pack 2.0 | Buttons and directional controls |
| `assets/kenney/icons` | Game Icons | Actual pause, settings, back, home, trophy, sound and other action icons |

There are 69 selected GLBs. Imported model folders retain their original internal structure. In particular, Car, Suburban, Industrial, Survival and Market models reference their own relative `Textures/colormap.png`; these palettes must not be flattened into one common texture. The inspected Nature tree embeds its texture. `docs/asset-source-manifest.json` records copied source-relative paths and SHA256 identities; paths identify the supplied asset packs, not the owner's machine.

The renderer calculates a combined bounding box through every nested imported transform, normalizes horizontal footprint, centers the result and places its actual minimum height on the ground. Tall props have a visible-height cap. Model instances keep their original internal transformations and textures. Fire targets retain stable cell indices and never change the simulation's heat, water, wetness, integrity, reward or outcome state.

## UI sizes and copies

`assets/ui/button.png` and `button_pressed.png` are unchanged Kenney Grey/Double depth-flat and flat rectangle images, both 384 by 128 pixels. Neutral source textures let the application's gold/teal tint retain readable contrast; multiplying a blue source button by a gold tint was rejected during visual review. `star_full.png` is Kenney Yellow/Double/star.png; `star_empty.png` is Grey/Double/star_outline.png. Both stars are 128 by 120 pixels. Use filled/empty images for actual grading instead of a Unicode star or textual fraction.

The original raster action icons include `gear`, `pause`, `return`, `home`, `trophy`, `medal1`, `leaderboardsSimple`, `audioOn`, `audioOff`, `musicOn`, `musicOff`, `locked`, `unlocked`, `checkmark`, `cross`, `warning`, `wrench`, `plus`, `target`, `information` and `shoppingBasket`. A 128-pixel dollar icon from Board Game Icons is copied as `currency.png` with its own original license. These avoid font-dependent missing-glyph controls.

## Environment and input contract

Six themes have their own terrain/sky colors and landmarks: Maple Mews, Pine Camp, Warehouse Row, Orchard Bend, Lakeside Fair and Lantern Heights. A fixed oblique orthographic camera fits the diorama between the top HUD and lower touch controls; runtime resizing recalculates the fit. Playable cells use ground coordinates `Vector2(x,z)`. Fire/steam sprites sit above actual model roofs/canopies, with ground rings preserving spatial context. Roof hit testing resolves perspective parallax to that cell's ground center, then ordinary empty-ground aiming uses a camera ray-plane intersection. The run still owns the actual spray radius and damage rules.

**Initial-design amendment:** the initial offset-reticle idea was superseded during UI/touch testing by direct finger targeting. The invisible 38-pixel touch offset was removed: touching a visible fire now addresses that object consistently with mouse input. The large perimeter ring still shows the actual spray area. This is an intentional usability correction, not an omitted implementation requirement.

The world renderer uses one shadowed directional light, one unshadowed fill, cached imported scenes/textures and small bounded particle representations. Lantern Heights adds four short-range unshadowed lantern lights. Water has 16 lightweight arc segments and 24 moving droplets. Each cell has three flame billboards, smoke and steam, a wetness sprite, target/warning rings and a damage bar. This is a deliberately bounded representation for Android Compatibility rendering; native performance remains a measured acceptance item, not a claim established by source inspection.

Native desktop viewport review rejected the initial washed-out lighting and faint smoky flames. The revision uses actual Kenney flame silhouettes with renderer-only crop regions, explicit ambient sky contribution, a higher Filmic white reference, a navy surround and purposeful garden/fence/campsite detail. The untouched source PNG bytes are retained. The lighting configuration was checked against the [Godot 4.5 Environment API](https://docs.godotengine.org/en/4.5/classes/class_environment.html). `tests/test_world.gd` verifies all six themes across three viewport sizes, measured model heights, target projection, touch-to-cell mapping, water availability, upcoming ember warnings and visible heat on zero-integrity objects. Source-model checks and scripted desktop fixtures are distinct from ordinary Android touch gameplay or physical-device testing.

Kenney previews were inspected for Car Kit, Survival Kit, Suburban and Industrial scene composition, Nature, Furniture, UI Pack, UI Adventure and Particle Pack. Asset dimensions, relative texture references and nested mesh fitting were reviewed. Generated marketing illustration and new audio are separately documented by their owners; they are not represented as Kenney assets or runtime screenshots here.

## Recorded implementation verification

The final selected visual asset manifest has 127 entries: 69 models and 58 PNGs including the six external model palettes and four UI aliases. Every copied file matched both its original supplied asset and recorded SHA256 after the neutral-button correction. Twelve original Kenney pack licenses are retained separately from the new asset-notices summary.

`tests/test_world.gd` passed 699 checks under the actual Godot 4.5.1 headless runtime. A separate native desktop Compatibility renderer fixture passed 215 checks while capturing all six themes at 540 by 960 pixels; a whole-application fixture captured Home, gameplay and Pause. Those captures were visually inspected and iterated to correct clipping-prone lighting, faint flames, historical-ignition/destruction confusion and primary-button contrast. The zero-integrity/hot-object regression also verifies that gameplay never leaves an invisible remaining fire. The renderer only visualizes state and does not settle runs or change earned progress.

These are explicit headless checks and scripted desktop rendered fixtures. They do not establish Android performance, ordinary device touch, audio quality, physical phone/tablet testing, native ad behavior or Play backend configuration. Those belong to the separately recorded integration acceptance. The isolated Windows runs emitted the known certificate-store-read diagnostic; successful final runs had no script/parse/runtime errors and returned the expected pass markers with exit code zero.
