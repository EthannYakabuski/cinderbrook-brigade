"""Validate Cinderbrook Brigade store assets and recorded runtime capture provenance.

Default mode requires genuine Android emulator/device captures in phone, 7-inch
and 10-inch profiles. --allow-pending is an explicit local staging check and may
not be used as a completed runtime or CI acceptance result.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re

from build_achievement_import import ValidationError, require, validate_catalog, validate_png

ROOT = Path(__file__).resolve().parents[1]
HASH = re.compile(r"[a-f0-9]{64}\Z")
PACKAGE = "com.ethannyakabuski.cinderbrookbrigade"
PROFILES = {"phone", "tablet7", "tablet10"}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_json(path: Path) -> dict:
    require(path.is_file(), f"Missing JSON: {path.relative_to(ROOT)}")
    value = json.loads(path.read_text(encoding="utf-8-sig"))
    require(isinstance(value, dict), f"JSON object required: {path.relative_to(ROOT)}")
    return value


def contained(base: Path, name: str) -> Path:
    require(isinstance(name, str) and bool(name), "Empty/non-text relative path")
    relative = PurePosixPath(name)
    require(not relative.is_absolute() and ".." not in relative.parts and "\\" not in name and ":" not in name and relative.as_posix() == name, f"Noncanonical relative path: {name}")
    path = (base / name).resolve()
    require(path.is_relative_to(base.resolve()) and not (base / name).is_symlink(), f"Path leaves allowed root: {name}")
    return path


def verify_file_hash(path: Path, expected: str, label: str) -> None:
    require(isinstance(expected, str) and bool(HASH.fullmatch(expected)), f"Invalid SHA256: {label}")
    require(path.is_file(), f"Missing file: {label}")
    require(sha256(path.read_bytes()) == expected, f"File differs from captured bytes: {label}")


def validate_source(source: dict, label: str) -> str:
    require(isinstance(source, dict), f"Invalid capture source: {label}")
    kind = source.get("kind")
    require(kind in ("runtime_files", "android_apk"), f"Unknown source kind: {label}")
    if kind == "android_apk":
        require(source.get("package_name") == PACKAGE, f"Wrong APK package: {label}")
        require(bool(HASH.fullmatch(str(source.get("apk_sha256", "")))), f"Missing APK hash: {label}")
        # The binary stays out of source control. If available locally, verify it.
        if source.get("artifact_path"):
            path = contained(ROOT, source["artifact_path"])
            require(source["artifact_path"].startswith("build/"), f"APK must be a build artifact: {label}")
            if path.exists():
                verify_file_hash(path, source["apk_sha256"], label)
        require(bool(source.get("build_evidence")), f"APK source needs public build evidence reference: {label}")
        receipt = read_json(contained(ROOT, source["build_evidence"]))
        # Receipt structure may contain several artifact versions. The exact hash
        # must be present; this does not manufacture a source-to-binary proof.
        require(source["apk_sha256"] in json.dumps(receipt), f"APK hash absent from build evidence: {label}")
    files = source.get("files", [])
    if kind == "runtime_files":
        require(isinstance(files, list) and bool(files), f"No capture runtime source files: {label}")
    require(isinstance(files, list), f"Invalid captured file list: {label}")
    names = set()
    for entry in files:
        require(isinstance(entry, dict), f"Malformed captured file record: {label}")
        name = entry.get("path")
        require(name not in names, f"Duplicate captured input: {name}")
        names.add(name)
        verify_file_hash(contained(ROOT, name), entry.get("sha256"), name)
    if kind == "runtime_files":
        require("project.godot" in names and "game/catalog.json" in names, f"Incomplete runtime source snapshot: {label}")
        require(any(name.startswith("game/") and name.endswith(".gd") for name in names), f"No captured game source: {label}")
    return kind


def validate_captures(allow_pending: bool) -> dict:
    capture_root = ROOT / "marketing/screenshots"
    manifest_path = capture_root / "provenance.json"
    if not manifest_path.is_file():
        require(allow_pending, "Runtime capture provenance is missing; final store acceptance is pending")
        return {"status": "PENDING", "reason": "No runtime captures recorded", "captures": 0}
    manifest = read_json(manifest_path)
    require(manifest.get("schema_version") == 1, "Unsupported screenshot provenance schema")
    sources = manifest.get("sources", {})
    captures = manifest.get("captures", [])
    require(isinstance(sources, dict) and isinstance(captures, list), "Invalid capture manifest sources/records")
    require(allow_pending or bool(captures), "Empty screenshot evidence cannot pass final validation")
    validated_sources = {}
    seen_paths, seen_hashes, native_profiles, runtime_profiles = set(), set(), set(), set()
    for capture in captures:
        require(isinstance(capture, dict), "Capture record must be an object")
        name = capture.get("path")
        # Capture tools and review pages share repository-relative paths. Never
        # interpret a root-relative marketing/screenshots path a second time.
        path = contained(ROOT, name)
        require(path.is_relative_to(capture_root.resolve()), f"Capture path leaves screenshot directory: {name}")
        require(name not in seen_paths, f"Duplicate screenshot path: {name}")
        seen_paths.add(name)
        verify_file_hash(path, capture.get("sha256"), name)
        require(capture["sha256"] not in seen_hashes, f"Duplicate screenshot bytes across records: {name}")
        seen_hashes.add(capture["sha256"])
        width, height = capture.get("width"), capture.get("height")
        require(type(width) is int and type(height) is int, f"Capture dimensions must be integers: {name}")
        validate_png(path.read_bytes(), name, (width, height))
        require(320 <= min(width, height) and max(width, height) <= 3840 and max(width, height) <= 2 * min(width, height), f"Screenshot dimensions outside store range: {name}")
        for key in ("profile", "description", "method", "device_class", "captured_at_utc"):
            require(isinstance(capture.get(key), str) and bool(capture[key].strip()), f"Capture lacks {key}: {name}")
        require(capture["profile"] in PROFILES, f"Unknown device profile: {name}")
        source_id = capture.get("source_id")
        require(source_id in sources, f"Capture refers to unknown source: {name}")
        if source_id not in validated_sources:
            validated_sources[source_id] = validate_source(sources[source_id], source_id)
        source_kind = validated_sources[source_id]
        capture_kind = capture.get("capture_kind")
        require(capture_kind in ("desktop_runtime", "android_emulator", "physical_android"), f"Not a declared runtime capture: {name}")
        if capture_kind == "desktop_runtime":
            require(capture.get("physical_device") is False and source_kind == "runtime_files", f"Desktop fixture provenance mismatch: {name}")
            require("desktop" in capture["device_class"].lower(), f"Desktop capture must be labelled as such: {name}")
        else:
            require(source_kind == "android_apk", f"Native capture missing APK identity: {name}")
            require(capture.get("physical_device") is (capture_kind == "physical_android"), f"Physical-device claim differs: {name}")
            if capture_kind == "android_emulator":
                require("emulator" in capture["device_class"].lower(), f"Emulator capture must be labelled: {name}")
            native_profiles.add(capture["profile"])
        runtime_profiles.add(capture["profile"])
    require(set(sources) == set(validated_sources) or allow_pending, "Unreferenced capture source in final evidence")
    missing = sorted(PROFILES - native_profiles)
    require(allow_pending or not missing, "Missing actual Android runtime capture profiles: " + ", ".join(missing))
    return {"status": "PENDING" if missing else "PASS", "captures": len(captures), "runtime_profiles": sorted(runtime_profiles), "android_profiles": sorted(native_profiles), "missing_android_profiles": missing, "source_identities": len(validated_sources), "claim": "Recorded image/provenance integrity only; does not itself prove playability or physical-device testing."}


def validate(allow_pending: bool = False) -> dict:
    listing = read_json(ROOT / "marketing/store/store-listing.json")
    for key, limit in (("title", 30), ("short_description", 80), ("full_description", 4000)):
        require(isinstance(listing.get(key), str) and 0 < len(listing[key]) <= limit, f"Invalid store {key} length")
    require(listing["title"] == "Cinderbrook Brigade", "Wrong store game identity")
    require(listing.get("package_name") == PACKAGE, "Wrong store package name")
    require(listing.get("release_ready") is False, "Draft must not claim production release readiness")
    require(bool(listing.get("category")) and bool(listing.get("tags")), "Missing store category or tags")
    for filename, expected in (("app-icon-512.png", (512, 512)), ("feature-graphic-1024x500.png", (1024, 500)), ("splash-1080x1920.png", (1080, 1920))):
        path = ROOT / "marketing" / filename
        require(path.is_file(), f"Missing artwork: {filename}")
        validate_png(path.read_bytes(), filename, expected)
    catalog = read_json(ROOT / "game/catalog.json")
    validate_catalog(catalog)
    image_hashes = set()
    for item in catalog["achievements"] + catalog["leaderboards"]:
        path = contained(ROOT, item["icon"].removeprefix("res://"))
        require(path.is_file(), f"Missing catalog icon: {item['id']}")
        data = path.read_bytes()
        validate_png(data, item["id"])
        require(sha256(data) not in image_hashes, f"Repeated catalog icon bytes: {item['id']}")
        image_hashes.add(sha256(data))
    for name in ("privacy-draft.html", "support.html", "data-safety-draft.json"):
        require((ROOT / "marketing/store" / name).is_file(), f"Missing store draft: {name}")
    safety = read_json(ROOT / "marketing/store/data-safety-draft.json")
    require(safety.get("no_data_collected_claim") is False, "Cannot infer no SDK collection from local save storage")
    for name in ("LICENSE", "NOTICE", "review/index.html", "public/index.html", "docs/STORE_AND_RELEASE.md", "docs/ACHIEVEMENT_IMPORT.md"):
        require((ROOT / name).is_file(), f"Missing review/release file: {name}")
    captures = validate_captures(allow_pending)
    return {"result": "PASS - static store/capture integrity" if captures["status"] == "PASS" else "PENDING - staged assets only; no final acceptance", "game": listing["title"], "store_text_lengths": {key: len(listing[key]) for key in ("title", "short_description", "full_description")}, "achievement_icons": len(catalog["achievements"]), "leaderboard_icons": len(catalog["leaderboards"]), "screenshots": captures, "console_upload_or_publication_performed": False}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--allow-pending", action="store_true", help="Local staging only; disclose missing runtime capture profiles")
    args = parser.parse_args()
    try:
        print(json.dumps(validate(args.allow_pending), indent=2))
        return 0
    except (ValidationError, OSError, ValueError, KeyError, TypeError) as exc:
        print(f"FAIL: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
