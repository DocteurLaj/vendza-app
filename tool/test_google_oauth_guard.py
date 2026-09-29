import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tool" / "guard_google_oauth.py"
EXPECTED = "992593495811-ogh34thu3rg606tjgnd7jdf8ir7n32ok.apps.googleusercontent.com"
LEGACY = "838466400797-old.apps.googleusercontent.com"


class GoogleOAuthGuardTest(unittest.TestCase):
    def run_guard(self, *args, **env_overrides):
        env = os.environ.copy()
        env.update(env_overrides)
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args],
            cwd=ROOT,
            text=True,
            capture_output=True,
            env=env,
            check=False,
        )

    def test_guard_rejects_legacy_runtime_google_client(self):
        result = self.run_guard("--check-env", GOOGLE_WEB_CLIENT_ID=LEGACY)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("legacy Google Web client", result.stderr)

    def test_guard_requires_runtime_google_client(self):
        result = self.run_guard("--check-env", GOOGLE_WEB_CLIENT_ID="")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("expected Google Web client", result.stderr)

    def test_guard_accepts_expected_runtime_google_client(self):
        result = self.run_guard("--check-env", GOOGLE_WEB_CLIENT_ID=EXPECTED)

        self.assertEqual(result.returncode, 0, result.stderr)

    def test_guard_scans_build_artifacts_for_legacy_google_client(self):
        with tempfile.TemporaryDirectory() as tmp:
            artifact = Path(tmp) / "main.dart.js"
            artifact.write_text(f"client = '{LEGACY}';", encoding="utf-8")

            result = self.run_guard("--scan", str(artifact), GOOGLE_WEB_CLIENT_ID=EXPECTED)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("legacy Google Web client", result.stderr)

    def test_guard_requires_expected_client_in_build_artifacts(self):
        with tempfile.TemporaryDirectory() as tmp:
            artifact = Path(tmp) / "vendza-config.js"
            artifact.write_text('window.vendzaGoogleWebClientId="";', encoding="utf-8")

            result = self.run_guard(
                "--scan",
                str(artifact),
                "--require-expected",
                GOOGLE_WEB_CLIENT_ID=EXPECTED,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("expected Google Web client", result.stderr)


if __name__ == "__main__":
    unittest.main()
