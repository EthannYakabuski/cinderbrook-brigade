# Cinderbrook Brigade audio

`manifest.json` is the runtime mapping for seven original music loops and twelve effects. Music uses 32 kHz, 16-bit stereo WAV. The seven scores contain sixteen authored bars each, lasting 33–46 seconds, with separate A/B melodies, eight-chord arcs, bass, chord comping, percussion and a quieter answering melody. The rendering code uses no downloaded music or sampled instruments.

| Runtime key | Original title | Tempo |
| --- | --- | --- |
| menu | A Light in the Station | 84 BPM |
| district_01 | Maple Mews Morning | 108 BPM |
| district_02 | Pines and Camp Lanterns | 94 BPM |
| district_03 | Copperworks Shuffle | 116 BPM |
| district_04 | Apple Blossom Relay | 102 BPM |
| district_05 | Little Lights by the Lake | 112 BPM |
| district_06 | The Last Lantern Home | 98 BPM |

`water`, `splash` and `extinguish` are original filtered-noise Foley. `win`, `lose`, `refill` and `upgrade` are original short composed cues. `tap`, `confirm`, `back` and `error` copy Kenney Interface Sounds; `coins` copies `handleCoins2.ogg` from Kenney RPG Audio. The five copied OGGs are byte-identical to their supplied sources. Exact source names and SHA256 hashes are in the manifest; both original CC0 notices are preserved in `LICENSES/`.

Rebuild with Python and NumPy: `python tools/prepare_audio.py`. The existing Blender Python is suitable; no application installation or live API is needed. The script only writes inside this game's audio tree. Original compositions/Foley are project work under Apache-2.0; supplied Kenney effects retain CC0.

Music and `water` must loop in Godot; enable `AudioStreamWAV.LOOP_FORWARD` and set the loop end to the stream frame count. Short effects must not loop. The manifest proposes music at −12 dB and effects at −6 dB before user controls. App pause/ad/background handling should suspend or fade audio consistently with gameplay; settings persist music and effects independently.

`validation.json` records signal metrics. Rendered samples have no clipping. The seam metric records the difference between neighboring samples across the loop boundary; a nonzero value is normal for an audible waveform. These checks establish valid signals and files, not a human listening evaluation. Native decoding/playback is checked separately during runtime testing.
