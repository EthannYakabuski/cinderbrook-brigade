"""Compare all catalog icon pixels and imported bytes inside finished APK/AAB files.

Read-only for source art, Godot import caches and packages. Pillow must already
be available; this helper never installs dependencies or invokes Godot.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import io
import json
from pathlib import Path
import re
import struct
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SIDE = (512, 512)


class EvidenceError(ValueError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise EvidenceError(message)


def relative(path: Path) -> str:
    resolved = path.resolve()
    require(resolved.is_relative_to(ROOT), "Evidence inputs/outputs must stay inside the project")
    return resolved.relative_to(ROOT).as_posix()


def read(path: Path) -> bytes:
    label = relative(path)
    try:
        return path.read_bytes()
    except OSError as error:
        raise EvidenceError(f"Cannot read {label}: {error.strerror}") from error


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def text(data: bytes, label: str) -> str:
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError as error:
        raise EvidenceError(f"{label}: invalid UTF-8") from error


def import_paths(data: bytes, source: str, label: str, require_source: bool = True) -> str:
    value = text(data, label)
    sources = re.findall(r'^source_file="([^"]+)"\s*$', value, re.MULTILINE)
    remaps = re.findall(r'^path="(res://\.godot/imported/[^"\r\n]+\.ctex)"\s*$', value, re.MULTILINE)
    # Android exports intentionally retain only the remap section (with a
    # trailing NUL), stripping editor-only deps/params. The archive entry path
    # binds that remap to its source resource; local import deps remain strict.
    require(sources == ["res://" + source] or (not require_source and not sources),
            f"{label}: source_file does not match its catalog icon")
    require(len(remaps) == 1, f"{label}: expected one imported CTEX remap")
    remap = remaps[0].removeprefix("res://")
    require(relative(ROOT / remap) == remap, f"{label}: unsafe imported path")
    return remap


def decode_png(data: bytes, label: str, Image) -> bytes:
    require(data.startswith(b"\x89PNG\r\n\x1a\n"), f"{label}: source is not PNG")
    try:
        with Image.open(io.BytesIO(data)) as image:
            require(image.format == "PNG" and image.size == SIDE and image.mode in ("RGB", "RGBA"),
                    f"{label}: expected 512x512 RGB/RGBA PNG")
            image.load()
            # Opaque RGB source icons normalize to alpha=255; every RGBA
            # channel still participates in the exact decoded comparison.
            return image.convert("RGBA").tobytes()
    except EvidenceError:
        raise
    except Exception as error:
        raise EvidenceError(f"{label}: PNG decode failed ({type(error).__name__})") from error


def decode_ctex(data: bytes, label: str, Image) -> tuple[bytes, dict]:
    require(len(data) >= 68 and data[:4] == b"GST2", f"{label}: invalid GST2 texture header")
    width, height = struct.unpack_from("<II", data, 8)
    require((width, height) == SIDE, f"{label}: CTEX header must be 512x512")
    payload_length = struct.unpack_from("<I", data, 52)[0]
    require(payload_length > 12 and len(data) == 56 + payload_length,
            f"{label}: CTEX payload length mismatch")
    payload = data[56:]
    require(payload[:4] == b"RIFF" and payload[8:12] == b"WEBP", f"{label}: expected WebP at CTEX offset 56")
    riff_length = struct.unpack_from("<I", payload, 4)[0]
    require(riff_length + 8 == len(payload), f"{label}: WebP RIFF declared length mismatch")
    try:
        with Image.open(io.BytesIO(payload)) as image:
            require(image.format == "WEBP" and image.size == SIDE, f"{label}: decoded WebP dimensions/format mismatch")
            image.load()
            rgba = image.convert("RGBA").tobytes()
    except EvidenceError:
        raise
    except Exception as error:
        raise EvidenceError(f"{label}: CTEX WebP decode failed ({type(error).__name__})") from error
    return rgba, {"width": width, "height": height, "webp_offset": 56,
                  "payload_bytes": payload_length, "riff_length_field": riff_length}


def artifact(path: Path, expected: str | None) -> dict:
    name = relative(path)
    if expected:
        require(bool(re.fullmatch(r"[0-9a-fA-F]{64}", expected)), "Expected artifact SHA256 must contain 64 hex digits")
    try:
        with path.open("rb") as stream:
            digest = hashlib.file_digest(stream, "sha256").hexdigest()
        size = path.stat().st_size
    except OSError as error:
        raise EvidenceError(f"Cannot hash {name}: {error.strerror}") from error
    require(expected is None or digest == expected.lower(), f"{name}: artifact SHA256 differs from expected")
    return {"path": name, "bytes": size, "sha256": digest,
            "expected_sha256_matched": digest == expected.lower() if expected else None}


def verify(apk: Path, aab: Path, expected_apk: str | None, expected_aab: str | None, Image) -> dict:
    catalog_data = read(ROOT / "game/catalog.json")
    try:
        catalog = json.loads(catalog_data)
    except (ValueError, TypeError) as error:
        raise EvidenceError("game/catalog.json: invalid JSON") from error
    require(isinstance(catalog, dict), "Catalog must be an object")
    entries = []
    keys, sources = set(), set()
    for kind, count in (("achievements", 20), ("leaderboards", 3)):
        group = catalog.get(kind)
        require(isinstance(group, list) and len(group) == count, f"Catalog requires exactly {count} {kind}")
        for item in group:
            require(isinstance(item, dict) and isinstance(item.get("id"), str), f"{kind}: invalid definition")
            key = item["id"]
            source_uri = item.get("icon", "")
            require(isinstance(source_uri, str) and source_uri.startswith(f"res://assets/{kind}/") and source_uri.endswith(".png"),
                    f"{kind}/{key}: unexpected source icon path")
            source = source_uri.removeprefix("res://")
            require(key not in keys and source not in sources, "Catalog icon IDs and paths must be unique across all 23 icons")
            require(relative(ROOT / source) == source, f"{kind}/{key}: unsafe source path")
            keys.add(key)
            sources.add(source)
            entries.append((kind, key, source))
    result = {
        "game": "Cinderbrook Brigade", "checked_utc": datetime.now(timezone.utc).isoformat(),
        "result": "PASS", "method": "Actual packaged CTEX bytes and all decoded RGBA channels equal source PNG pixels",
        "catalog_sha256": sha256(catalog_data), "icon_count": len(entries),
        "artifacts": {"apk": artifact(apk, expected_apk), "aab": artifact(aab, expected_aab)},
        "icons": [], "runtime_rendering_tested": False, "physical_device_tested": False,
        "source_or_packages_modified": False,
    }
    with zipfile.ZipFile(apk) as apk_zip, zipfile.ZipFile(aab) as aab_zip:
        archives = (("apk", apk_zip, "assets/"), ("aab", aab_zip, "assetPackInstallTime/assets/"))
        for kind, archive, _ in archives:
            require(archive.testzip() is None, f"{kind}: archive CRC check failed")
            names = archive.namelist()
            require(len(names) == len(set(names)), f"{kind}: duplicate ZIP entries")
            result["artifacts"][kind]["zip_crc_passed"] = True
        for kind, key, source in entries:
            source_bytes = read(ROOT / source)
            source_pixels = decode_png(source_bytes, source, Image)
            source_md5 = hashlib.md5(source_bytes).hexdigest()
            import_name = source + ".import"
            import_bytes = read(ROOT / import_name)
            ctex_name = import_paths(import_bytes, source, import_name)
            md5_name = str(Path(ctex_name).with_suffix(".md5")).replace("\\", "/")
            md5_text = text(read(ROOT / md5_name), md5_name)
            md5_fields = re.findall(r'^source_md5="([0-9a-fA-F]{32})"\s*$', md5_text, re.MULTILINE)
            require(len(md5_fields) == 1 and md5_fields[0].lower() == source_md5,
                    f"{md5_name}: source MD5 does not match current PNG bytes")
            ctex_bytes = read(ROOT / ctex_name)
            dest_md5 = hashlib.md5(ctex_bytes).hexdigest()
            dest_fields = re.findall(r'^dest_md5="([0-9a-fA-F]{32})"\s*$', md5_text, re.MULTILINE)
            require(len(dest_fields) == 1 and dest_fields[0].lower() == dest_md5,
                    f"{md5_name}: destination MD5 does not match current CTEX bytes")
            local_pixels, header = decode_ctex(ctex_bytes, ctex_name, Image)
            require(local_pixels == source_pixels, f"{ctex_name}: imported RGBA pixels differ from source PNG")
            row = {"kind": kind, "id": key, "source_path": source,
                   "source_sha256": sha256(source_bytes), "source_md5": source_md5,
                   "source_dimensions": {"width": 512, "height": 512}, "decoded_pixel_format": "RGBA",
                   "source_rgba_sha256": sha256(source_pixels), "source_import_path": import_name,
                   "import_md5_path": md5_name, "import_source_md5_matched": True,
                   "import_destination_md5": dest_md5, "import_destination_md5_matched": True,
                   "local_ctex_path": ctex_name, "local_ctex_sha256": sha256(ctex_bytes),
                   "local_decoded_rgba_sha256": sha256(local_pixels), "local_source_pixels_exact": True,
                   "ctex_header": header}
            for target, archive, prefix in archives:
                packed_ctex = prefix + ctex_name
                packed_import = prefix + import_name
                try:
                    packaged_bytes = archive.read(packed_ctex)
                    packaged_import = archive.read(packed_import)
                except KeyError as error:
                    raise EvidenceError(f"{target}/{key}: required icon/import entry is absent") from error
                require(packaged_bytes == ctex_bytes, f"{target}/{packed_ctex}: imported bytes differ from current local CTEX")
                require(import_paths(packaged_import, source, f"{target}/{packed_import}", require_source=False) == ctex_name,
                        f"{target}/{packed_import}: packaged import points to another CTEX")
                packaged_pixels, _ = decode_ctex(packaged_bytes, f"{target}/{packed_ctex}", Image)
                require(packaged_pixels == source_pixels, f"{target}/{key}: packaged RGBA pixels differ from source")
                row[target] = {"entry": packed_ctex, "ctex_sha256": sha256(packaged_bytes),
                               "decoded_rgba_sha256": sha256(packaged_pixels), "source_pixels_exact": True,
                               "import_entry": packed_import, "import_remap_matches": True,
                               "import_bytes_equal_local": packaged_import == import_bytes,
                               "editor_only_import_deps_stripped": b"source_file=" not in packaged_import}
            result["icons"].append(row)
    require(len(result["icons"]) == 23, "Incomplete icon inspection")
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apk", required=True, type=Path)
    parser.add_argument("--aab", required=True, type=Path)
    parser.add_argument("--output", type=Path, default=ROOT / "docs/packed-art-evidence.json")
    parser.add_argument("--expected-apk-sha256")
    parser.add_argument("--expected-aab-sha256")
    args = parser.parse_args()
    try:
        from PIL import Image
    except ImportError:
        print("Pillow is required to compare decoded RGBA pixels. Use an already configured interpreter; no dependency was installed.", file=sys.stderr)
        return 2
    try:
        output = args.output.resolve()
        relative(output)
        report = verify(args.apk.resolve(), args.aab.resolve(), args.expected_apk_sha256, args.expected_aab_sha256, Image)
    except (EvidenceError, zipfile.BadZipFile, OSError) as error:
        print(f"PACKED_ART FAIL: {error}", file=sys.stderr)
        return 1
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"PACKED_ART PASS icons={report['icon_count']} artifacts=2 pixel_channels=RGBA receipt={relative(output)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
