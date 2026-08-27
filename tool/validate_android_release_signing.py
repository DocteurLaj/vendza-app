#!/usr/bin/env python3
"""Static Android release-signing check (no Flutter/Gradle artifact download).

Exit codes:
  0 — signing configured and keystore file present
  2 — signing not configured (expected in CI without secrets)
  1 — unexpected error
"""

from __future__ import annotations

import sys
from pathlib import Path

ANDROID_DIR = Path(__file__).resolve().parents[1] / "android"
KEY_PROPERTIES = ANDROID_DIR / "key.properties"
REQUIRED = ("keyAlias", "keyPassword", "storeFile", "storePassword")
BLOCKED_MSG = "Release build blocked: Android signing is not configured."


def main() -> int:
    if not KEY_PROPERTIES.is_file():
        print(BLOCKED_MSG)
        print(f"Missing: {KEY_PROPERTIES}")
        return 2

    values: dict[str, str] = {}
    for line in KEY_PROPERTIES.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        values[key.strip()] = value.strip()

    for key in REQUIRED:
        if not values.get(key):
            print(BLOCKED_MSG)
            print(f"Missing property '{key}' in key.properties")
            return 2

    store = Path(values["storeFile"])
    if not store.is_file():
        # Relative paths are resolved from android/
        candidate = (ANDROID_DIR / store).resolve()
        if not candidate.is_file():
            print(BLOCKED_MSG)
            print(f"Keystore file not found: {values['storeFile']}")
            return 2

    print("Android release signing looks configured.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except SystemExit:
        raise
    except Exception as exc:  # noqa: BLE001
        print(f"Unexpected signing validation error: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
