from __future__ import annotations

import argparse
import os
import plistlib
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]



def prepare_agus_maps_assets() -> None:
    sdk_home_value = os.environ.get("AGUS_MAPS_HOME", "").strip()
    if not sdk_home_value:
        print("Agus Maps SDK asset preparation skipped: AGUS_MAPS_HOME is not set.")
        return

    sdk_home = Path(sdk_home_value).expanduser()
    sdk_asset_candidates = (sdk_home / "assets", sdk_home / "example" / "assets")
    sdk_assets = next((path for path in sdk_asset_candidates if path.exists()), None)
    if sdk_assets is None:
        raise SystemExit(
            "Agus Maps SDK has no assets directory (checked assets and example/assets)."
        )

    data_source = sdk_assets / "comaps_data"
    maps_source = sdk_assets / "maps"
    if not data_source.exists():
        raise SystemExit(f"Agus Maps SDK is missing comaps_data: {data_source}")
    if not maps_source.exists():
        raise SystemExit(f"Agus Maps SDK is missing maps: {maps_source}")

    maps_target = ROOT / "assets" / "maps"
    data_target = ROOT / "assets" / "comaps_data"
    maps_target.mkdir(parents=True, exist_ok=True)

    icu = maps_source / "icudt75l.dat"
    if not icu.exists():
        raise SystemExit(f"Agus Maps SDK is missing ICU data: {icu}")
    shutil.copy2(icu, maps_target / "icudt75l.dat")
    shutil.copytree(data_source, data_target, dirs_exist_ok=True)

    required = (
        ROOT / "assets" / "maps" / "icudt75l.dat",
        ROOT / "assets" / "comaps_data" / "countries.txt",
    )
    missing = [str(path) for path in required if not path.exists()]
    if missing:
        raise SystemExit("Agus Maps SDK assets incomplete: " + ", ".join(missing))

    print("agus_maps_sdk_assets=verified")

def patch_android() -> None:
    manifest = ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    if not manifest.exists():
        raise SystemExit(f"Missing generated Android manifest: {manifest}")

    text = manifest.read_text(encoding="utf-8")
    permissions = [
        "android.permission.ACCESS_COARSE_LOCATION",
        "android.permission.ACCESS_FINE_LOCATION",
        "android.permission.ACCESS_BACKGROUND_LOCATION",
        "android.permission.FOREGROUND_SERVICE",
        "android.permission.FOREGROUND_SERVICE_LOCATION",
        "android.permission.INTERNET",
    ]

    marker_end = text.find(">")
    if marker_end < 0:
        raise SystemExit("Invalid Android manifest.")

    insertion = []
    for permission in permissions:
        declaration = f'    <uses-permission android:name="{permission}" />'
        if permission not in text:
            insertion.append(declaration)

    if insertion:
        text = text[: marker_end + 1] + "\n" + "\n".join(insertion) + text[marker_end + 1 :]

    if "io.concerti.openidconnect_android.OpenIdConnectCallbackReceiverActivity" not in text:
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
        gradle = gradle.replace(
            "minSdk = flutter.minSdkVersion",
            "minSdk = 24",
        )
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
        help="Platform to configure; defaults to all for local use.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    prepare_agus_maps_assets()
    if args.platform in ("android", "all"):
        patch_android()
    if args.platform in ("ios", "all"):
        patch_ios()
    print(f"Mobile native configuration applied: {args.platform}.")
