"""Adversarial verifier-output tests; these do not create signed artifacts."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("package_signatures", ROOT / "tools/verify_package_signatures.py")
signatures = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(signatures)

APK_VALID = "\n".join(["Verifies", "Verified using v1 scheme (JAR signing): false",
                       "Verified using v2 scheme (APK Signature Scheme v2): true",
                       "Number of signers: 1", "Signer #1 certificate SHA-256 digest: " + "ab" * 32])
UNSIGNED = {"manifest_present": False, "signature_files": [],
            "signature_file_present": False, "signature_block_present": False}
SIGNED = {"manifest_present": True, "signature_files": ["META-INF/DEBUG.SF", "META-INF/DEBUG.RSA"],
          "signature_file_present": True, "signature_block_present": True}


class SignatureTests(unittest.TestCase):
    def test_valid_apk_requires_positive_signature_evidence(self):
        result = signatures.parse_apksigner(0, APK_VALID)
        self.assertEqual(result["status"], "valid")
        self.assertTrue(result["signature_verified"])
        self.assertEqual(result["certificate_sha256"], ["ab" * 32])

    def test_invalid_apk_cannot_pass_from_exit_or_success_text_alone(self):
        for code, output in [(1, APK_VALID), (0, "DOES NOT VERIFY"), (0, ""),
                             (0, "Verifies"), (0, APK_VALID + "\nERROR: corrupted")]:
            with self.subTest(code=code, output=output):
                self.assertFalse(signatures.parse_apksigner(code, output)["signature_verified"])

    def test_apk_malformed_signer_data_and_no_valid_scheme_fail(self):
        for output in [APK_VALID.replace("ab" * 32, "not-a-digest"),
                       APK_VALID.replace("signers: 1", "signers: 2"),
                       APK_VALID.replace("#1 certificate", "#2 certificate"),
                       APK_VALID.replace(": true", ": false"),
                       APK_VALID + "\nVerifies"]:
            with self.subTest(output=output):
                self.assertEqual(signatures.parse_apksigner(0, output)["status"], "unknown")

    def test_unsigned_exit_zero_is_never_a_signature_pass(self):
        result = signatures.parse_jarsigner(0, "no manifest.\r\n\r\njar is unsigned.\r\n", UNSIGNED)
        self.assertEqual(result["status"], "unsigned")
        self.assertFalse(result["signature_verified"])
        self.assertIsNone(result["signer_certificate"])

    def test_unsigned_marker_with_signature_metadata_is_not_clean_unsigned(self):
        self.assertEqual(signatures.parse_jarsigner(0, "jar is unsigned.", SIGNED)["status"], "unknown")

    def test_verified_aab_requires_matching_metadata_and_strict_success(self):
        self.assertTrue(signatures.parse_jarsigner(0, "jar verified.", SIGNED)["signature_verified"])
        for code, output, metadata in [(0, "jar verified.", UNSIGNED),
                                       (4, "jar verified, with signer errors.", SIGNED),
                                       (16, "jar verified, with signer errors.\nunsigned entries", SIGNED),
                                       (0, "jar verified.\nunsigned entries", SIGNED),
                                       (0, "jar verified.\njar is unsigned.", SIGNED)]:
            with self.subTest(code=code, output=output):
                self.assertFalse(signatures.parse_jarsigner(code, output, metadata)["signature_verified"])

    def test_unknown_and_malformed_jarsigner_output_fail_closed(self):
        for output in ("", "no manifest.", "jar verified", "success", "jar verified.\njar verified.",
                       "jarsigner error: java.lang.SecurityException: bad digest\njar verified."):
            with self.subTest(output=output):
                self.assertNotIn(signatures.parse_jarsigner(0, output, SIGNED)["status"], ("valid", "unsigned"))

    def test_expected_hash_mismatch_stops_before_verifier_execution(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            apk, aab, tool = (folder / name for name in ("test.apk", "test.aab", "apksigner.jar"))
            for path in (apk, aab, tool):
                path.write_bytes(b"existing-file")
            with patch.object(signatures.subprocess, "run") as run:
                with self.assertRaisesRegex(ValueError, "expected SHA256"):
                    signatures.verify(apk, aab, tool, "java", "jarsigner", "0" * 64)
                run.assert_not_called()

    def test_partial_or_duplicate_signature_metadata_is_not_accepted(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "test.aab"
            with zipfile.ZipFile(path, "w") as archive:
                archive.writestr("META-INF/MANIFEST.MF", "fixture")
                archive.writestr("META-INF/DEBUG.SF", "fixture")
            self.assertEqual(signatures.parse_jarsigner(0, "jar verified.", signatures.aab_metadata(path))["status"], "unknown")
            with zipfile.ZipFile(path, "a") as archive:
                archive.writestr("meta-inf/manifest.mf", "ambiguous-case-duplicate")
            with self.assertRaisesRegex(ValueError, "duplicate"):
                signatures.aab_metadata(path)


if __name__ == "__main__":
    unittest.main(verbosity=2)
