#!/usr/bin/env python3
"""Guard Vendza Web OAuth configuration against stale Google client IDs."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

EXPECTED_GOOGLE_WEB_CLIENT_ID = (
    "992593495811-ogh34thu3rg606tjgnd7jdf8ir7n32ok.apps.googleusercontent.com"
)
LEGACY_GOOGLE_WEB_CLIENT_PREFIX = "838466400797"


def _read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except OSError as exc:
        raise RuntimeError(f"cannot read {path}: {exc}") from exc


def _looks_like_google_web_client(value: str) -> bool:
    value = value.strip()
    return value.endswith(".apps.googleusercontent.com") and len(value) > len(
        ".apps.googleusercontent.com"
    )


def _is_legacy_client(value: str) -> bool:
    return value.strip().startswith(LEGACY_GOOGLE_WEB_CLIENT_PREFIX)


def validate_runtime_env() -> list[str]:
    value = os.environ.get("GOOGLE_WEB_CLIENT_ID", "").strip()
    errors: list[str] = []
    if not value:
        errors.append("GOOGLE_WEB_CLIENT_ID must contain the expected Google Web client ID.")
    elif value != EXPECTED_GOOGLE_WEB_CLIENT_ID:
        errors.append("GOOGLE_WEB_CLIENT_ID must match the expected Google Web client ID.")
    if _is_legacy_client(value):
        errors.append(
            "GOOGLE_WEB_CLIENT_ID uses the legacy Google Web client "
            f"prefix {LEGACY_GOOGLE_WEB_CLIENT_PREFIX}."
        )
    if value and not _looks_like_google_web_client(value):
        errors.append("GOOGLE_WEB_CLIENT_ID is not a Google OAuth web client ID.")
    return errors


def scan_artifacts(paths: list[Path], *, require_expected: bool) -> list[str]:
    errors: list[str] = []
    scanned_text = ""
    for path in paths:
        text = _read_text(path)
        scanned_text += text
        if LEGACY_GOOGLE_WEB_CLIENT_PREFIX in text:
            errors.append(f"{path} contains the legacy Google Web client prefix.")

    expected = os.environ.get("GOOGLE_WEB_CLIENT_ID", "").strip() or EXPECTED_GOOGLE_WEB_CLIENT_ID
    if require_expected and expected not in scanned_text:
        errors.append("No scanned artifact contains the expected Google Web client ID.")
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check-env", action="store_true")
    parser.add_argument("--scan", nargs="*", default=[])
    parser.add_argument("--require-expected", action="store_true")
    args = parser.parse_args(argv)

    errors: list[str] = []
    if args.check_env:
        errors.extend(validate_runtime_env())
    if args.scan:
        errors.extend(
            scan_artifacts([Path(path) for path in args.scan], require_expected=args.require_expected)
        )

    if errors:
        for error in errors:
            print(f"legacy Google Web client guard failed: {error}", file=sys.stderr)
        return 1
    print("Google OAuth guard passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
