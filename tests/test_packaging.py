"""Adversarial packaging tests; fixtures are synthetic and never runtime evidence."""
from __future__ import annotations
import binascii
import copy
import importlib.util
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace
import zlib

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import build_achievement_import as achievements
import validate_store as store
import assemble_site as site


def png(seed=1, width=512, height=512):
    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", binascii.crc32(kind + body) & 0xffffffff)
    pixels = (b"\0" + bytes((seed, 80, 120, 255)) * width) * height
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(pixels)) + chunk(b"IEND", b"")


def catalog():
    return {
        "achievements": [{"id": f"award_{n}", "name": f"Award {n}", "description": f"Extinguish {n + 1} hotspots.", "type": "standard", "steps": 0, "points": 10, "state": "revealed", "metric": "doused", "threshold": n + 1, "icon": f"res://assets/achievements/award_{n}.png"} for n in range(20)],
        "leaderboards": [{"id": f"board_{n}", "name": f"Board {n}", "description": f"Ranking {n}.", "metric": "xp", "sort_order": "larger_is_better", "icon": f"res://assets/leaderboards/board_{n}.png"} for n in range(3)],
    }


class CatalogTests(unittest.TestCase):
    def test_exact_standard_metadata(self):
        files = achievements.metadata_files(catalog())
        self.assertEqual(achievements.csv_rows(files[achievements.META], achievements.META, 7)[0], ["Award 0", "Extinguish 1 hotspots.", "False", "", "Revealed", "10", "1"])
        self.assertEqual(set(files), {"AchievementsMetadata.csv", "AchievementsIconsMappings.csv"})

    def test_incremental_target_preserved(self):
        data = catalog()
        data["achievements"][0].update(type="incremental", steps=10000, threshold=10000, state="hidden", points=200)
        files = achievements.metadata_files(data)
        self.assertEqual(achievements.csv_rows(files[achievements.META], achievements.META, 7)[0][2:6], ["True", "10000", "Hidden", "200"])

    def test_invalid_catalog_cases(self):
        mutations = {
            "standard steps": lambda c: c["achievements"][0].update(steps=1),
            "boolean steps": lambda c: c["achievements"][0].update(steps=False),
            "unmatched incremental target": lambda c: c["achievements"][0].update(type="incremental", steps=100, threshold=99),
            "out of range incremental": lambda c: c["achievements"][0].update(type="incremental", steps=10001, threshold=10001),
            "invalid state": lambda c: c["achievements"][0].update(state="unlocked"),
            "invalid type": lambda c: c["achievements"][0].update(type="counter"),
            "boolean points": lambda c: c["achievements"][0].update(points=True),
            "fraction points": lambda c: c["achievements"][0].update(points=10.5),
            "points remainder": lambda c: c["achievements"][0].update(points=12),
            "boolean threshold": lambda c: c["achievements"][0].update(threshold=True),
            "description comma": lambda c: c["achievements"][0].update(description="One, two."),
            "duplicate id": lambda c: c["achievements"][0].update(id="award_1"),
            "case duplicate name": lambda c: c["achievements"][0].update(name="AWARD 1"),
            "icon traversal": lambda c: c["achievements"][0].update(icon="res://../icon.png"),
            "wrong board order": lambda c: c["leaderboards"][0].update(sort_order="smaller_is_better"),
            "invented translation": lambda c: c.update(configured_locales=["en-US", "fr-FR"]),
            "too few achievements": lambda c: c["achievements"].pop(),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label):
                data = catalog()
                mutate(data)
                with self.assertRaises(achievements.ValidationError):
                    achievements.validate_catalog(data)

    def test_whole_game_budget(self):
        data = catalog()
        for entry in data["achievements"]:
            entry["points"] = 200
        with self.assertRaises(achievements.ValidationError):
            achievements.validate_catalog(data)

    def test_owner_id_worksheet_not_overwritten(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder)
            achievements.write_metadata(catalog(), path)
            worksheet = path / "achievement-id-mapping-and-points.csv"
            original = worksheet.read_bytes()
            edited = original.replace(b"award_0.png,\r\n", b"award_0.png,OWNER_CONFIGURED_ID\r\n")
            self.assertNotEqual(original, edited)
            worksheet.write_bytes(edited)
            with self.assertRaises(achievements.ValidationError):
                achievements.write_metadata(catalog(), path)
            self.assertEqual(worksheet.read_bytes(), edited)

    def test_deterministic_zip_is_order_independent(self):
        data = {"b.png": png(2), "a.png": png(1)}
        self.assertEqual(achievements.archive_bytes(data), achievements.archive_bytes(dict(reversed(list(data.items())))))

    def test_archive_adversarial_suite(self):
        self.assertGreaterEqual(achievements.self_test()["checks"], 31)


class StoreTests(unittest.TestCase):
    def test_path_traversal_rejected(self):
        for name in ("../escape.png", "C:/private/key", "/absolute.png", "a\\b.png", "./file.png"):
            with self.subTest(name=name), self.assertRaises(achievements.ValidationError):
                store.contained(ROOT, name)

    def test_png_scanlines_and_arbitrary_capture_dimensions(self):
        self.assertEqual(achievements.validate_png(png(1, 320, 640), "capture", (320, 640)), {"width": 320, "height": 640})
        with self.assertRaises(achievements.ValidationError):
            achievements.validate_png(png(1, 320, 640), "achievement")

    def fixture(self, root):
        folder = root / "marketing/screenshots"
        folder.mkdir(parents=True)
        (root / "docs").mkdir()
        artifact_hash = "a" * 64
        (root / "docs/build-evidence.json").write_text(json.dumps({"apk_sha256": artifact_hash}))
        result = {"schema_version": 1, "sources": {"native": {"kind": "android_apk", "apk_sha256": artifact_hash, "package_name": store.PACKAGE, "build_evidence": "docs/build-evidence.json"}}, "captures": []}
        for index, profile in enumerate(sorted(store.PROFILES)):
            name = f"{profile}.png"
            data = png(index + 1, 320, 640)
            (folder / name).write_bytes(data)
            result["captures"].append({"path": "marketing/screenshots/" + name, "width": 320, "height": 640, "sha256": store.sha256(data), "profile": profile, "description": "Synthetic validator fixture; never gameplay evidence.", "method": "fixture", "device_class": "test fixture emulator label", "captured_at_utc": "2026-11-14T00:00:00Z", "source_id": "native", "capture_kind": "android_emulator", "physical_device": False})
        return folder, result

    def test_missing_captures_strict_vs_staging(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(store, "ROOT", Path(folder)):
            with self.assertRaises(achievements.ValidationError):
                store.validate_captures(False)
            self.assertEqual(store.validate_captures(True)["status"], "PENDING")

    def test_complete_provenance_integrity(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            folder, manifest = self.fixture(root)
            (folder / "provenance.json").write_text(json.dumps(manifest))
            with patch.object(store, "ROOT", root):
                self.assertEqual(store.validate_captures(False)["status"], "PASS")

    def test_provenance_adversarial_cases(self):
        mutations = {
            "empty capture list": lambda m: m.update(captures=[]),
            "missing tablet": lambda m: m["captures"].pop(),
            "hash mismatch": lambda m: m["captures"][0].update(sha256="b" * 64),
            "false physical claim": lambda m: m["captures"][0].update(physical_device=True),
            "unidentified apk": lambda m: m["sources"]["native"].update(apk_sha256="c" * 64),
            "wrong package": lambda m: m["sources"]["native"].update(package_name="other.game"),
            "mockup": lambda m: m["captures"][0].update(capture_kind="static_mockup"),
            "unlabelled emulator": lambda m: m["captures"][0].update(device_class="physical phone"),
            "missing source": lambda m: m["captures"][0].update(source_id="missing"),
            "traversal": lambda m: m["captures"][0].update(path="../private.png"),
            "non-root-relative capture": lambda m: m["captures"][0].update(path="phone.png"),
            "capture outside screenshot root": lambda m: m["captures"][0].update(path="docs/private.png"),
        }
        for label, mutate in mutations.items():
            with self.subTest(label=label), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                folder, manifest = self.fixture(root)
                mutate(manifest)
                (folder / "provenance.json").write_text(json.dumps(manifest))
                with patch.object(store, "ROOT", root), self.assertRaises(achievements.ValidationError):
                    store.validate_captures(False)

    def test_desktop_requires_current_captured_sources(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "game").mkdir()
            names = ["project.godot", "game/catalog.json", "game/main.gd"]
            files = []
            for name in names:
                path = root / name
                path.write_bytes(b"source")
                files.append({"path": name, "sha256": store.sha256(b"source")})
            source = {"kind": "runtime_files", "files": files}
            with patch.object(store, "ROOT", root):
                self.assertEqual(store.validate_source(source, "fixture"), "runtime_files")
                (root / "game/main.gd").write_bytes(b"new runtime")
                with self.assertRaises(achievements.ValidationError):
                    store.validate_source(source, "fixture")


class AssemblyTests(unittest.TestCase):
    def test_git_blob_batch_preserves_binary_bytes(self):
        binary = b"\0\xff\n\r\nPNG-like fixture"
        output = b"0" * 40 + b" blob " + str(len(binary)).encode() + b"\n" + binary + b"\n"
        with patch.object(site.subprocess, "run", return_value=SimpleNamespace(stdout=output)):
            self.assertEqual(site.git_blob_hashes(["assets/brand/icon.png"]), {"assets/brand/icon.png": store.sha256(binary)})
        for bad_output in (output[:-1], b"HEAD:assets/brand/icon.png missing\n", output + b"unexpected"):
            with self.subTest(output=bad_output), patch.object(site.subprocess, "run", return_value=SimpleNamespace(stdout=bad_output)), self.assertRaises(SystemExit):
                site.git_blob_hashes(["assets/brand/icon.png"])

    def test_runtime_digest_is_portable_across_checkout_line_endings(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "game").mkdir()
            names = ["project.godot", "export_presets.cfg", "game/main.gd"]
            for name in names:
                (root / name).write_bytes(b"source\r\n")
            canonical = {name: store.sha256(b"source\n") for name in names}
            def fake_git(*args):
                if args == ("rev-parse", "--show-toplevel"):
                    return str(root)
                if args == ("rev-parse", "HEAD"):
                    return "a" * 40
                if args[0] == "ls-files":
                    return "game/main.gd\0"
                return ""
            with patch.object(site, "ROOT", root), patch.object(site, "git", fake_git), patch.object(site, "git_blob_hashes", return_value=canonical):
                windows = site.source_identity(True, "a" * 40)
                for name in names:
                    (root / name).write_bytes(b"source\n")
                linux = site.source_identity(True, "a" * 40)
            self.assertEqual(windows["runtime_tree_sha256"], linux["runtime_tree_sha256"])
            self.assertEqual(windows["runtime_files"], canonical)
            self.assertNotEqual(windows["runtime_worktree_tree_sha256"], linux["runtime_worktree_tree_sha256"])
            self.assertEqual(windows["runtime_hash_basis"], "canonical committed Git blob bytes")

    def test_complete_assembly_receipt_and_idempotent_guard(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            target = root / "build/site"
            for folder in ("review", "marketing", "docs", "LICENSES", "public", "assets/brand", "assets/achievements", "assets/leaderboards", "game", "build/site/play"):
                (root / folder).mkdir(parents=True, exist_ok=True)
            for name in ("LICENSE", "NOTICE", "INITIAL_VECTOR_PROMPT.txt", "review/index.html", "public/index.html", "docs/readme.md", "docs/owner.private.json", "marketing/key.jks", "assets/brand/icon.png", "game/catalog.json"):
                (root / name).write_bytes(b"fixture")
            (target / "play/index.html").write_text("const engine = new Engine(GODOT_CONFIG);")
            (target / "play/index.wasm").write_bytes(b"fixture wasm; not a game")
            fake_identity = {"source_identity": "fixture", "game": "Cinderbrook Brigade", "source_commit": "a" * 40, "uncommitted_changes": False}
            with patch.object(site, "ROOT", root), patch.object(site, "source_identity", return_value=fake_identity):
                receipt = site.assemble(target)
                first_html = (target / "play/index.html").read_bytes()
                self.assertEqual(receipt["web_export_sha256"]["play/index.html"], store.sha256(first_html))
                self.assertFalse((target / "docs/owner.private.json").exists())
                self.assertFalse((target / "marketing/key.jks").exists())
                self.assertTrue((target / "assets/brand/icon.png").is_file())
                (target / "docs/stale.txt").write_text("stale")
                site.assemble(target)
                self.assertEqual(first_html, (target / "play/index.html").read_bytes())
                self.assertFalse((target / "docs/stale.txt").exists())
                self.assertEqual((target / "play/index.html").read_text().count("CINDERBROOK_ENGINE_GUARD"), 1)

    def test_private_material_excluded(self):
        for name in ("capture.private.json", "logs/raw.log", "release.jks", ".env", "__pycache__/a.pyc", "output.apk", "config.local.json", "local.properties", "credentials.json"):
            with self.subTest(name=name):
                self.assertFalse(site.allowed_public(Path(name)))
        self.assertTrue(site.allowed_public(Path("play-games-achievements/cinderbrook-brigade-achievements-google-play.zip")))

    def test_output_scope_guard(self):
        with self.assertRaises(SystemExit):
            site.assemble(ROOT / "marketing")
        with self.assertRaises(SystemExit):
            site.assemble(ROOT / "build")

    def test_verified_identity_rejects_dirty_tree(self):
        def fake_git(*args):
            if args == ("rev-parse", "--show-toplevel"):
                return str(ROOT)
            if args == ("rev-parse", "HEAD"):
                return "a" * 40
            if args[0] == "status":
                return " M game/main.gd"
            return ""
        with patch.object(site, "git", fake_git), self.assertRaises(SystemExit):
            site.source_identity(True, "a" * 40)

    def test_verified_identity_rejects_wrong_commit(self):
        def fake_git(*args):
            if args == ("rev-parse", "--show-toplevel"):
                return str(ROOT)
            if args == ("rev-parse", "HEAD"):
                return "a" * 40
            return ""
        with patch.object(site, "git", fake_git), self.assertRaises(SystemExit):
            site.source_identity(True, "b" * 40)


if __name__ == "__main__":
    unittest.main(verbosity=2)
