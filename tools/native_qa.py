# Ordinary Android SDK input for an explicitly authorized test emulator.
# Actual execution receipts, framebuffer observations and resulting saved state
# establish coverage; this helper's presence alone is not acceptance evidence.
"""Record ordinary Android input and read-only observations for this game.

No game-state injection, time acceleration, screenshot editing or fake rewards.
Each action list is an explicit JSON file; captures use capture_android.py.
"""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = "com.ethannyakabuski.cinderbrookbrigade"

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("actions", type=Path)
    parser.add_argument("--adb", required=True)
    parser.add_argument("--serial", default="emulator-5560")
    parser.add_argument("--profile", choices=["phone", "tablet7", "tablet10"], default="phone")
    parser.add_argument("--label", required=True)
    args = parser.parse_args()
    if not re.fullmatch(r"[a-z0-9-]+", args.label):
        parser.error("Use a lowercase hyphenated evidence label")
    output = ROOT / "build/native/actions" / (args.label + ".json")
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        parser.error("Evidence labels must be unique")
    actions = json.loads(args.actions.read_text(encoding="utf-8-sig"))
    receipt = {"kind": "ordinary_android_input", "physical_device": False,
               "package": PACKAGE, "serial": args.serial, "actions": []}
    def adb(*command):
        return subprocess.check_output([args.adb, "-s", args.serial, *command], timeout=55)
    def save():
        output.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    for action in actions:
        record = {"at_utc": datetime.now(timezone.utc).isoformat(), "request": action}
        receipt["actions"].append(record)
        save()
        kind = action["kind"]
        if kind == "tap":
            result = adb("shell", "input", "tap", str(action["x"]), str(action["y"]))
        elif kind == "swipe":
            duration = int(action.get("ms", 1000))
            if not 1 <= duration <= 30000:
                raise ValueError("Touch duration must be 1–30000 ms")
            result = adb("shell", "input", "swipe", *map(str, [action["x1"], action["y1"], action["x2"], action["y2"], duration]))
        elif kind == "key":
            if action["code"] not in [3, 4, 82]:
                raise ValueError("Only Home, Back and Menu keys are supported")
            result = adb("shell", "input", "keyevent", str(action["code"]))
        elif kind == "wait":
            seconds = float(action["seconds"])
            if not 0 <= seconds <= 30:
                raise ValueError("Wait must be 0–30 seconds")
            time.sleep(seconds)
            result = b""
        elif kind == "capture":
            command = [sys.executable, str(ROOT / "tools/capture_android.py"), action["label"],
                       "--adb", args.adb, "--serial", args.serial, "--profile", args.profile,
                       "--description", action["description"]]
            if action.get("diagnostic", False):
                command.append("--diagnostic")
            result = subprocess.check_output(command, cwd=ROOT, timeout=55)
        elif kind == "profile":
            result = adb("exec-out", "run-as", PACKAGE, "cat", "files/cinderbrook-v1.json")
            json.loads(result)
        elif kind == "stop":
            result = adb("shell", "am", "force-stop", PACKAGE)
        elif kind == "launch":
            result = adb("shell", "am", "start", "-W", "-n", PACKAGE + "/com.godot.game.GodotApp")
        else:
            raise ValueError("Unsupported action: " + str(kind))
        record["output"] = result.decode("utf-8", errors="replace")
        record["completed_utc"] = datetime.now(timezone.utc).isoformat()
        record["result"] = "executed"
        save()
    print(f"Recorded {len(actions)} ordinary Android actions: {output.relative_to(ROOT).as_posix()}")

if __name__ == "__main__":
    main()
