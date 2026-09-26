#!/usr/bin/env python3
"""Validate CI and production build configuration profiles.

The normal CI pipeline must build only a non-production artifact.
The release-candidate workflow must fail closed unless every required
production endpoint is present, HTTPS-only, and clearly non-placeholder.
"""

from __future__ import annotations

import argparse
import os
import sys
from urllib.parse import urlparse

PRODUCTION_ENDPOINTS = (
    "MAP_PMTILES_URL",
    "VALHALLA_BASE_URL",
    "SOURCE_GATEWAY_BASE_URL",
    "OFFLINE_CATALOG_URL",
    "RESCUE_LINK_BASE_URL",
)

PLACEHOLDER_HOSTS = {
    "example.com",
    "example.org",
    "example.net",
    "localhost",
    "127.0.0.1",
    "::1",
}

PRODUCTION_VARS = PRODUCTION_ENDPOINTS


def _fail(message: str) -> "NoReturn":
    print(f"BUILD PROFILE ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def _validate_https(name: str, raw: str) -> None:
    parsed = urlparse(raw)
    if parsed.scheme != "https" or not parsed.netloc:
        _fail(f"{name} must be a complete HTTPS URL.")

    host = parsed.hostname or ""
    lowered = host.lower().rstrip(".")
    if lowered in PLACEHOLDER_HOSTS or lowered.endswith(".local"):
        _fail(f"{name} points to a local/placeholder host: {host!r}.")

    if lowered.startswith("127.") or lowered.startswith("0."):
        _fail(f"{name} points to a local/private loopback-style host: {host!r}.")

    if parsed.username or parsed.password:
        _fail(f"{name} must not embed credentials in the URL.")


def check_ci() -> None:
    app_env = os.environ.get("APP_ENV", "")
    if app_env != "ci":
        _fail(f"CI profile requires APP_ENV=ci, got {app_env!r}.")

    for name in PRODUCTION_VARS:
        value = os.environ.get(name, "")
        if value:
            _fail(
                f"CI profile must not receive production variable {name}. "
                "Use the production release-candidate workflow instead."
            )

    print("profile=ci")
    print("production_endpoints=absent")


def check_production() -> None:
    app_env = os.environ.get("APP_ENV", "")
    if app_env != "production":
        _fail(
            "Production profile requires APP_ENV=production, "
            f"got {app_env!r}."
        )

    for name in PRODUCTION_ENDPOINTS:
        value = os.environ.get(name, "").strip()
        if not value:
            _fail(f"Missing required production endpoint: {name}.")
        _validate_https(name, value)

    attribution = os.environ.get("MAP_ATTRIBUTION", "").strip()
    if not attribution:
        _fail("Missing required production map attribution: MAP_ATTRIBUTION.")

    print("profile=production")
    for name in PRODUCTION_ENDPOINTS:
        print(f"{name}=configured")
    print("MAP_ATTRIBUTION=configured")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--profile", choices=("ci", "production"), required=True)
    args = parser.parse_args()

    if args.profile == "ci":
        check_ci()
    else:
        check_production()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
