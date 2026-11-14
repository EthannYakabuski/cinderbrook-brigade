"""Run the required source checks with fresh game profiles and strict diagnostics.

This validates source/application logic. It does not claim native ad delivery,
Android gameplay, physical-device performance, or browser acceptance.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import uuid

ROOT = Path(__file__).resolve().parents[1]
GAME_SUITES = (
    ("tests/test_model.gd", "MODEL", 600),
    ("tests/test_profile.gd", "PROFILE", 300),
    ("tests/test_ui.gd", "UI", 300),
    ("tests/test_world.gd", "WORLD", 300),
)
SOURCE_CHECKS = (
    ("tests/test_packaging.py", ()),
    ("tools/validate_store.py", ()),
    ("tools/build_achievement_import.py", ("--self-test",)),
    ("tools/build_achievement_import.py", ("--check",)),
    ("platform/tests/validate_platform.py", ()),
    ("platform/tests/test_prepare_android.py", ()),
)
KNOWN_HOST_DIAGNOSTIC = "ERROR: Failed to read the root certificate store."
FAILURE = re.compile(
    r"SCRIPT ERROR|Parse Error|Assertion failed|^ERROR:|"
    r"ObjectDB instances leaked|resources still in use at exit|Pages in use exist at exit",
    re.IGNORECASE,
)


def diagnostics(stdout: str, stderr: str) -> list[str]:
    return [line for line in (stdout + "\n" + stderr).splitlines()
            if line.strip() != KNOWN_HOST_DIAGNOSTIC and FAILURE.search(line.strip())]


def marker_count(stdout: str, marker: str) -> int:
    receipts = [line.strip() for line in stdout.splitlines()
                if line.strip().startswith(marker + " PASS")]
    if len(receipts) != 1:
        raise ValueError(f"Expected exactly one positive {marker} completion receipt")
    match = re.fullmatch(rf"{re.escape(marker)} PASS checks=([1-9][0-9]*)(?: failures=0)?", receipts[0])
    if not match:
        raise ValueError(f"Invalid or failing {marker} completion receipt: {receipts[0]}")
    return int(match.group(1))


def isolated_environment(directory: Path) -> dict[str, str]:
    env = os.environ.copy()
    profile = directory / "profile"
    profile.mkdir(parents=True)
    for variable in ("APPDATA", "LOCALAPPDATA", "XDG_DATA_HOME", "CINDERBROOK_TEST_ROOT", "CINDER_TEST_ROOT"):
        env[variable] = str(profile)
    env["XDG_CONFIG_HOME"] = str(directory / "config")
    env["XDG_CACHE_HOME"] = str(directory / "cache")
    return env


def self_test() -> None:
    assert not diagnostics("all clear", "")
    assert not diagnostics("", KNOWN_HOST_DIAGNOSTIC)
    for bad in ("SCRIPT ERROR: bad type", "ERROR: parser failed", "Parse Error: invalid",
                "Assertion failed", "WARNING: ObjectDB instances leaked at exit"):
        assert diagnostics(bad, ""), bad
    assert marker_count("MODEL PASS checks=42\n", "MODEL") == 42
    assert marker_count("WORLD PASS checks=9 failures=0\n", "WORLD") == 9
    for bad in ("", "MODEL PASS checks=0", "MODEL PASS checks=1\nMODEL PASS checks=2", "MODEL FAIL checks=12",
                "MODEL PASS checks=3 failures=1", "MODEL PASS checks=2\nMODEL PASS checks=3 failures=1"):
        try:
            marker_count(bad, "MODEL")
        except ValueError:
            pass
        else:
            raise AssertionError("Invalid completion receipt accepted: " + repr(bad))
    print("CHECK_RUNNER_SELF_TEST PASS checks=15")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", type=Path)
    parser.add_argument("--expected-sha")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--check-log", action="append", type=Path,
                        help="Read-only strict diagnostic check of an existing engine log")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if args.check_log:
        for path in args.check_log:
            contents = path.read_text(encoding="utf-8", errors="replace")
            if not contents.strip():
                raise SystemExit(f"Empty engine log: {path}")
            problems = diagnostics(contents, "")
            if problems:
                raise SystemExit("Strict engine-log failure: " + " | ".join(problems))
        print(f"ENGINE_LOG_CHECK PASS logs={len(args.check_log)}")
        return 0
    if not args.godot or not args.godot.is_file():
        parser.error("--godot must name the installed Godot 4.5.1 executable")
    godot = str(args.godot.resolve())
    required = [path for path, _ in SOURCE_CHECKS] + [path for path, _, _ in GAME_SUITES]
    required += ["platform/tests/run_tests.py", "project.godot"]
    missing = [path for path in required if not (ROOT / path).is_file()]
    if missing:
        raise SystemExit("Required checks are missing; refusing a partial pass: " + ", ".join(missing))
    commit = None
    if args.expected_sha:
        commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
        if commit != args.expected_sha:
            raise SystemExit("Source commit differs from --expected-sha")
        if subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=all"], cwd=ROOT, text=True).strip():
            raise SystemExit("Verified CI checks require an initially clean source checkout")
    build = ROOT / "build"
    build.mkdir(exist_ok=True)
    (build / ".gdignore").touch()
    work = build / "checks" / uuid.uuid4().hex[:12]
    work.mkdir(parents=True)
    receipt = {
        "game": "Cinderbrook Brigade", "source_commit": commit,
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "result": "RUNNING", "native_runtime_tested": False, "browser_gameplay_tested": False,
        "steps": [],
    }

    def save() -> None:
        (work / "summary.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")

    def run(label: str, command: list[str], timeout: int, marker: str | None = None) -> None:
        env = isolated_environment(work / label)
        print(f"Running {label}", flush=True)
        result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True,
                                text=True, encoding="utf-8", errors="replace", timeout=timeout)
        (work / f"{label}.stdout.log").write_text(result.stdout, encoding="utf-8")
        (work / f"{label}.stderr.log").write_text(result.stderr, encoding="utf-8")
        step = {"name": label, "returncode": result.returncode,
                "stdout_log": f"{label}.stdout.log", "stderr_log": f"{label}.stderr.log",
                "known_host_certificate_warning": KNOWN_HOST_DIAGNOSTIC in result.stdout + result.stderr}
        receipt["steps"].append(step)
        problems = diagnostics(result.stdout, result.stderr)
        if result.returncode or problems:
            step["result"] = "FAIL"
            step["error_lines"] = problems
            save()
            print(result.stdout[-5000:])
            print(result.stderr[-5000:], file=sys.stderr)
            raise RuntimeError(f"{label}: exit={result.returncode}; strict errors={len(problems)}")
        if marker:
            step["checks"] = marker_count(result.stdout, marker)
        step["result"] = "PASS"
        save()
        print(result.stdout[-2000:], flush=True)

    try:
        save()
        self_test()
        run("import", [godot, "--headless", "--editor", "--path", str(ROOT), "--import", "--quit"], 240)
        for index, (path, flags) in enumerate(SOURCE_CHECKS):
            run(f"source-{index + 1}-{Path(path).stem}", [sys.executable, path, *flags], 180)
        run("platform-fixtures", [sys.executable, "platform/tests/run_tests.py", "--godot", godot], 420)
        for path, marker, timeout in GAME_SUITES:
            label = Path(path).stem
            run(label, [godot, "--headless", "--path", str(ROOT), "--script", path,
                        "--", f"--qa-profile=user://qa-{label}-{work.name}.json"], timeout, marker)
        receipt["result"] = "PASS"
    except (OSError, RuntimeError, ValueError, subprocess.TimeoutExpired) as error:
        receipt["result"] = "FAIL"
        receipt["failure"] = str(error)
        print(str(error), file=sys.stderr)
    finally:
        receipt["finished_utc"] = datetime.now(timezone.utc).isoformat()
        save()
    print(f"Source-check receipt: {work.relative_to(ROOT).as_posix()}/summary.json")
    return 0 if receipt["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
