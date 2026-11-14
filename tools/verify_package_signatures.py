"""Inspect existing APK/AAB signatures without signing or reading owner keys.

Development policy: APK must verify; AAB may be genuinely unsigned or verify.
Unsigned is an explicit status, never a signature pass or Play-ready claim.
Unknown, contradictory, partial-signature and strict-error results fail closed.

References:
https://developer.android.com/tools/apksigner
https://docs.oracle.com/en/java/javase/17/docs/specs/man/jarsigner.html
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def digest(path: Path) -> str:
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def label(path: Path) -> str:
    try:
        return path.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return path.name


def result(status: str, code: int, output: str, reason: str,
           verified: bool = False) -> dict:
    return {"status": status, "signature_verified": verified,
            "exit_code": code, "tool_output": output.strip(), "reason": reason}


def parse_apksigner(code: int, output: str) -> dict:
    lines = [line.strip() for line in output.splitlines()]
    if code != 0 or re.search(r"(?im)^\s*(DOES NOT VERIFY|ERROR:|Exception)", output):
        return result("invalid", code, output, "Official APK verifier failed.")
    if lines.count("Verifies") != 1:
        return result("unknown", code, output, "Missing unique APK verification marker.")
    counts = re.findall(r"(?m)^Number of signers: ([1-9][0-9]*)\s*$", output)
    certs = re.findall(r"(?m)^Signer #([1-9][0-9]*) certificate SHA-256 digest: ([0-9a-fA-F]{64})\s*$", output)
    schemes = re.findall(r"(?m)^Verified using (v[0-9]+(?:\.[0-9]+)?) scheme .*: (true|false)\s*$", output)
    if (len(counts) != 1 or len(certs) != int(counts[0])
            or {int(n) for n, _ in certs} != set(range(1, int(counts[0]) + 1))
            or not schemes or not any(value == "true" for _, value in schemes)
            or len({scheme for scheme, _ in schemes}) != len(schemes)):
        return result("unknown", code, output, "Incomplete or contradictory APK signer/scheme output.")
    answer = result("valid", code, output, "Official apksigner verified the APK signature.", True)
    answer["certificate_sha256"] = [value.lower() for _, value in sorted(certs, key=lambda row: int(row[0]))]
    answer["verified_schemes"] = [scheme for scheme, value in schemes if value == "true"]
    return answer


def aab_metadata(path: Path) -> dict:
    with zipfile.ZipFile(path) as archive:
        names = [item.filename.upper() for item in archive.infolist()]
    if len(names) != len(set(names)):
        raise ValueError("AAB contains ambiguous duplicate entry names")
    signature_files = [name for name in names if re.fullmatch(r"META-INF/[^/]+\.(SF|RSA|DSA|EC)", name)]
    return {"manifest_present": "META-INF/MANIFEST.MF" in names,
            "signature_files": signature_files,
            "signature_file_present": any(name.endswith(".SF") for name in signature_files),
            "signature_block_present": any(not name.endswith(".SF") for name in signature_files)}


def parse_jarsigner(code: int, output: str, metadata: dict) -> dict:
    lines = [line.strip().lower() for line in output.splitlines()]
    unsigned = lines.count("jar is unsigned.")
    verified = lines.count("jar verified.")
    signer_errors = lines.count("jar verified, with signer errors.")
    failure = re.search(r"(?im)^\s*(jarsigner error:|java\.[\w.]*Exception|Exception in thread)", output)
    if code != 0 or failure:
        return result("invalid", code, output, "Strict JAR verification returned errors; no signature pass is asserted.")
    if unsigned == 1 and not verified and not signer_errors and not metadata["signature_files"]:
        answer = result("unsigned", code, output, "Archive is unsigned. Exit 0 is not a signature pass.")
        answer["signer_certificate"] = None
        return answer
    if (verified == 1 and not unsigned and not signer_errors
            and metadata["manifest_present"] and metadata["signature_file_present"]
            and metadata["signature_block_present"]
            and not re.search(r"(?i)unsigned entries|treated as unsigned|disabled algorithm", output)):
        return result("valid", code, output, "Strict jarsigner verified the signed AAB.", True)
    return result("unknown", code, output, "Missing, contradictory or incomplete JAR signature evidence.")


def verify(apk: Path, aab: Path, apksigner_jar: Path, java: str, jarsigner: str,
           expected_apk: str | None = None, expected_aab: str | None = None) -> dict:
    paths = [apk.resolve(), aab.resolve()]
    if paths[0] == paths[1] or not apksigner_jar.is_file():
        raise ValueError("Distinct packages and the installed official apksigner JAR are required")
    hashes = [digest(path) for path in paths]
    for actual, expected in zip(hashes, (expected_apk, expected_aab)):
        if expected is not None and actual != expected.lower():
            raise ValueError("Artifact differs from its expected SHA256; no verifier was run")
    metadata = aab_metadata(paths[1])
    # An empty temporary Java user.home prevents access to an owner's default
    # .keystore. Neither command has a signing or private-key argument.
    with tempfile.TemporaryDirectory(prefix="cinderbrook-signature-verify-") as isolated_home:
        commands = [
            [java, "-Duser.language=en", "-Duser.country=US", "-Duser.home=" + isolated_home,
             "-jar", str(apksigner_jar.resolve()), "verify", "--verbose", "--print-certs", str(paths[0])],
            [jarsigner, "-J-Duser.language=en", "-J-Duser.country=US", "-J-Duser.home=" + isolated_home,
             "-verify", "-strict", "-verbose:summary", "-certs", str(paths[1])],
        ]
        answers = []
        for index, command in enumerate(commands):
            completed = subprocess.run(command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                       stderr=subprocess.STDOUT, text=True, encoding="utf-8",
                                       errors="replace", timeout=120, check=False)
            output = completed.stdout.replace(str(ROOT), "<project>").replace(isolated_home, "<isolated-home>")
            answers.append(parse_apksigner(completed.returncode, output) if index == 0
                           else parse_jarsigner(completed.returncode, output, metadata))
    unchanged = hashes == [digest(path) for path in paths]
    files = {}
    for path, sha, signature in zip(paths, hashes, answers):
        files[path.name] = {"path": label(path), "bytes": path.stat().st_size,
                            "sha256": sha, "signature": signature}
    passed = unchanged and answers[0]["status"] == "valid" and answers[1]["status"] in ("unsigned", "valid")
    return {"game": "Cinderbrook Brigade", "checked_utc": datetime.now(timezone.utc).isoformat(),
            "check": "Static development package signature classification", "passed": passed,
            "policy": "APK signature must verify; development AAB may be genuinely unsigned or strictly verified. Unsigned is not a signature pass.",
            "files": files, "aab_archive_metadata": metadata, "artifact_bytes_unchanged": unchanged,
            "private_keystore_read": False, "signing_performed": False, "native_runtime_tested": False,
            "play_submission_eligibility_verified": False}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apk", required=True, type=Path)
    parser.add_argument("--aab", required=True, type=Path)
    parser.add_argument("--apksigner-jar", required=True, type=Path)
    parser.add_argument("--java", default="java")
    parser.add_argument("--jarsigner", default="jarsigner")
    parser.add_argument("--expected-apk-sha256")
    parser.add_argument("--expected-aab-sha256")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.output.resolve() in (args.apk.resolve(), args.aab.resolve(), args.apksigner_jar.resolve()):
        parser.error("Receipt must not overwrite an input")
    try:
        receipt = verify(args.apk, args.aab, args.apksigner_jar, args.java, args.jarsigner,
                         args.expected_apk_sha256, args.expected_aab_sha256)
    except (OSError, ValueError, zipfile.BadZipFile, subprocess.TimeoutExpired) as error:
        print(f"PACKAGE_SIGNATURES FAIL: {error}")
        return 1
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8", newline="\n")
    statuses = ", ".join(f"{name}={row['signature']['status']}" for name, row in receipt["files"].items())
    print(f"PACKAGE_SIGNATURES {'PASS' if receipt['passed'] else 'FAIL'} development policy: {statuses}")
    return 0 if receipt["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
