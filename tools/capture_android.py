"""Capture unmodified Android emulator pixels with exact APK provenance.

This records ordinary runtime observations, not physical-device or human testing.
It never injects game state and never resizes or retouches screenshots.
"""
from __future__ import annotations
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = "com.ethannyakabuski.cinderbrookbrigade"

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("label")
    p.add_argument("--profile", choices=["phone", "tablet7", "tablet10"], required=True)
    p.add_argument("--description", required=True)
    p.add_argument("--apk", type=Path, default=ROOT / "build/android/cinderbrook-brigade-test.apk")
    p.add_argument("--adb", required=True)
    p.add_argument("--serial", default="emulator-5560")
    p.add_argument("--diagnostic", action="store_true", help="Keep an observation outside the store screenshot manifest.")
    args = p.parse_args()
    if not re.fullmatch(r"[a-z0-9-]+", args.label):
        p.error("Use a lowercase hyphenated label.")
    apk = args.apk.resolve()
    if not apk.is_relative_to(ROOT) or not apk.is_file():
        p.error("APK must be an existing artifact inside this project.")
    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *command], timeout=45)
    adb("shell", "pidof", PACKAGE)
    pixels = adb("exec-out", "screencap", "-p")
    if not pixels.startswith(b"\x89PNG\r\n\x1a\n"):
        raise SystemExit("Emulator returned no PNG; nothing recorded.")
    width, height = struct.unpack(">II", pixels[16:24])
    folder = ROOT / ("build/native/observations" if args.diagnostic else f"marketing/screenshots/android-{args.profile}")
    folder.mkdir(parents=True, exist_ok=True)
    target = folder / f"{args.label}.png"
    if target.exists():
        raise SystemExit("Choose a fresh label; previous raw observations are preserved.")
    apk_hash = hashlib.sha256(apk.read_bytes()).hexdigest()
    source_id = "android-" + apk_hash[:16]
    observation = {
        "path": target.relative_to(ROOT).as_posix(), "width": width, "height": height,
        "sha256": hashlib.sha256(pixels).hexdigest(), "profile": args.profile,
        "description": args.description,
        "method": "ADB exec-out screencap: unmodified full Android framebuffer after ordinary touchscreen UI input",
        "device_class": "Android API 30 x86 emulator with SwiftShader GLES 3; logical display profile",
        "physical_device": False, "capture_kind": "android_emulator", "source_id": source_id,
        "captured_at_utc": datetime.now(timezone.utc).isoformat(),
        "display_size": adb("shell", "wm", "size").decode().strip(),
        "display_density": adb("shell", "wm", "density").decode().strip(),
        "serial": args.serial,
    }
    target.write_bytes(pixels)
    target.with_suffix(".json").write_text(json.dumps(observation, indent=2) + "\n", encoding="utf-8")
    if not args.diagnostic:
        manifest = ROOT / "marketing/screenshots/provenance.json"
        data = json.loads(manifest.read_text(encoding="utf-8")) if manifest.exists() else {"game": "Cinderbrook Brigade", "schema_version": 1, "sources": {}, "captures": []}
        data["sources"][source_id] = {
            "kind": "android_apk", "apk_sha256": apk_hash, "package_name": PACKAGE,
            "build_evidence": "docs/build-evidence.json", "artifact_path": apk.relative_to(ROOT).as_posix(),
        }
        data["captures"].append(observation)
        manifest.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(observation, indent=2))

if __name__ == "__main__":
    main()
