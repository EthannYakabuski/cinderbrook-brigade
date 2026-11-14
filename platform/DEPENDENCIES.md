# Plugin provenance and retained patches

The supplied local Poing AdMob source is version 5.1.0; Godot Play Games Services is version 3.4.0. The new project vendors their existing proven Prism Quarry integration, with original MIT licenses and included asset notices. `plugin-binaries.json` records all six AAR hashes and sizes. The two PGS libraries exactly match the owner-supplied bundle. The supplied AdMob source bundle contains no installed AARs; its four tested 5.1.0 binaries are reused unchanged from Prism Quarry, not represented as freshly downloaded or independently rebuilt.

Retained integration patches:

- AdMob's editor plugin registers existing vendored Android dependencies without invoking its optional iOS auto-installer. It preserves authored project settings during editor shutdown. Unused sample translation files are omitted, preventing imports from dirtying public source.
- The PGS exporter preserves an explicitly registered runtime autoload and removes only an autoload it created itself. Blank game IDs emit no metadata referencing a missing generated string; a configured numeric ID restores the normal resource/manifest route.
- Native binaries are not modified. Plugin source/assets are included selectively; editor documentation, samples, download caches and generated imports are not copied. Existing exporter scripts needed for plugin loading remain present.

No production service configuration, signing material, player saves, generated Android build tree, Git metadata or private evidence was copied. Original adapter work retains the repository Apache-2.0 license; third-party components retain their respective terms.
