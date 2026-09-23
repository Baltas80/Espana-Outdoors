from __future__ import annotations

import plistlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


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
    ]

    marker_end = text.find(">")
    if marker_end < 0:
        raise SystemExit("Invalid Android manifest.")

    insertion = []
    for permission in permissions:
        declaration = (
            f'    <uses-permission android:name="{permission}" />'
        )
        if permission not in text:
            insertion.append(declaration)

    if insertion:
        text = text[: marker_end + 1] + "\n" + "\n".join(insertion) + text[marker_end + 1 :]
        manifest.write_text(text, encoding="utf-8")


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


if __name__ == "__main__":
    patch_android()
    patch_ios()
    print("Mobile native configuration applied.")
