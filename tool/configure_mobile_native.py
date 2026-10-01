from __future__ import annotations

import argparse
import plistlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def patch_android() -> None:
    manifest = ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    if not manifest.exists():
        raise SystemExit(f"Missing generated Android manifest: {manifest}")

    permissions = [
        "android.permission.ACCESS_COARSE_LOCATION",
        "android.permission.ACCESS_FINE_LOCATION",
        "android.permission.ACCESS_BACKGROUND_LOCATION",
        "android.permission.FOREGROUND_SERVICE",
        "android.permission.FOREGROUND_SERVICE_LOCATION",
        "android.permission.INTERNET",
    ]

    text = manifest.read_text(encoding="utf-8")
    marker_end = text.find(">")
    if marker_end < 0:
        raise SystemExit("Invalid Android manifest.")

    insertion = []
    for permission in permissions:
        declaration = f'    <uses-permission android:name="{permission}" />'
        if permission not in text:
            insertion.append(declaration)

    if insertion:
        text = (
            text[: marker_end + 1]
            + "\n"
            + "\n".join(insertion)
            + text[marker_end + 1 :]
        )

    network_security = ROOT / "android" / "app" / "src" / "main" / "res" / "xml" / "network_security_config.xml"
    network_security.parent.mkdir(parents=True, exist_ok=True)
    network_security.write_text(
        '''<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
  <!-- The offline PMTiles renderer may use an on-device loopback server.
       No remote cleartext traffic is permitted. -->
  <domain-config cleartextTrafficPermitted="true">
    <domain includeSubdomains="false">localhost</domain>
  </domain-config>
</network-security-config>
''',
        encoding="utf-8",
    )

    application_start = text.find("<application")
    if application_start < 0:
        raise SystemExit("Android manifest has no <application> element.")
    application_end = text.find(">", application_start)
    if application_end < 0:
        raise SystemExit("Invalid Android <application> element.")
    if "android:networkSecurityConfig=" not in text[application_start:application_end]:
        text = (
            text[:application_end]
            + ' android:networkSecurityConfig="@xml/network_security_config"'
            + text[application_end:]
        )

    callback = """    <activity
        android:name="io.concerti.openidconnect_android.OpenIdConnectCallbackReceiverActivity"
        android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
          android:scheme="com.espanaoutdoors"
          android:host="oauth2redirect" />
      </intent-filter>
    </activity>"""
    if "io.concerti.openidconnect_android.OpenIdConnectCallbackReceiverActivity" not in text:
        application_end = text.rfind("</application>")
        if application_end < 0:
            raise SystemExit("Android manifest has no </application> element.")
        text = text[:application_end] + callback + "\n" + text[application_end:]

    manifest.write_text(text, encoding="utf-8")

    gradle_candidates = [
        ROOT / "android" / "app" / "build.gradle.kts",
        ROOT / "android" / "app" / "build.gradle",
    ]
    gradle_path = next((path for path in gradle_candidates if path.exists()), None)
    if gradle_path is None:
        raise SystemExit("Missing generated Android app Gradle file.")

    gradle = gradle_path.read_text(encoding="utf-8")
    if gradle_path.suffix == ".kts":
        gradle = gradle.replace("minSdk = flutter.minSdkVersion", "minSdk = 24")
    else:
        gradle = gradle.replace(
            "minSdkVersion flutter.minSdkVersion",
            "minSdkVersion 24",
        )
    gradle_path.write_text(gradle, encoding="utf-8")


def patch_ios() -> None:
    plist_path = ROOT / "ios" / "Runner" / "Info.plist"
    if not plist_path.exists():
        raise SystemExit(f"Missing generated iOS Info.plist: {plist_path}")

    with plist_path.open("rb") as handle:
        plist = plistlib.load(handle)

    plist.setdefault(
        "NSLocationWhenInUseUsageDescription",
        "España Outdoor necesita tu ubicación para GPS, navegación, grabación de rutas y funciones de seguridad.",
    )
    plist.setdefault(
        "NSLocationAlwaysAndWhenInUseUsageDescription",
        "España Outdoor puede necesitar tu ubicación en segundo plano mientras grabas o navegas una ruta.",
    )

    modes = plist.setdefault("UIBackgroundModes", [])
    if "location" not in modes:
        modes.append("location")

    with plist_path.open("wb") as handle:
        plistlib.dump(plist, handle, fmt=plistlib.FMT_XML, sort_keys=False)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Apply platform-specific native configuration after flutter create."
    )
    parser.add_argument(
        "--platform",
        choices=("android", "ios", "all"),
        default="all",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    if args.platform in ("android", "all"):
        patch_android()
    if args.platform in ("ios", "all"):
        patch_ios()
    print(f"Mobile native configuration applied: {args.platform}.")
