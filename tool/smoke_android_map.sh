#!/usr/bin/env bash
set -euo pipefail

apk_path="${1:?APK path required}"
aapt_path="$(find "${ANDROID_HOME}/build-tools" -maxdepth 2 -type f -name aapt -print | sort -V | tail -n 1)"
test -x "${aapt_path}"
package_name="$("${aapt_path}" dump badging "${apk_path}" | sed -n "s/^package: name='\\([^']*\\)'.*/\\1/p" | head -n 1)"
test -n "${package_name}"

echo "Installing ${package_name}"
adb wait-for-device
adb install -r "${apk_path}"

adb logcat -c
adb shell am force-stop "${package_name}"
adb shell monkey -p "${package_name}" 1 >/tmp/espana-monkey.log 2>&1 || {
  cat /tmp/espana-monkey.log
  exit 1
}

echo "Waiting for normal home screen..."
sleep 5

adb shell uiautomator dump /sdcard/espana-window.xml >/dev/null 2>&1 || true
adb exec-out cat /sdcard/espana-window.xml >"${RUNNER_TEMP:-/tmp}/espana-window.xml"

read -r tap_x tap_y < <(
  python3 - "${RUNNER_TEMP:-/tmp}/espana-window.xml" <<'PY'
import re
import sys
import xml.etree.ElementTree as ET

path = sys.argv[1]
root = ET.parse(path).getroot()
candidates = []

for node in root.iter("node"):
    text = (node.attrib.get("text") or "").strip()
    desc = (node.attrib.get("content-desc") or "").strip()
    if text != "Mapa" and desc != "Mapa":
        continue

    bounds = node.attrib.get("bounds", "")
    match = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds)
    if not match:
        continue

    x1, y1, x2, y2 = map(int, match.groups())
    candidates.append(((y1 + y2) // 2, (x1 + x2) // 2))

if not candidates:
    raise SystemExit("Could not find visible Mapa navigation destination")

cy, cx = max(candidates)
print(cx, cy)
PY
)

echo "Tapping Mapa at ${tap_x},${tap_y}"
adb shell input tap "${tap_x}" "${tap_y}"

echo "Waiting for native map startup..."
sleep 15

logcat_file="${RUNNER_TEMP:-/tmp}/espana-outdoor-map-logcat.txt"
adb logcat -d >"${logcat_file}"

pid="$(adb shell pidof "${package_name}" 2>/dev/null | tr -d '\r' | tr -d '\n' || true)"
if test -z "${pid}"; then
  echo "FAIL: application process is not alive after tapping Mapa."
  grep -Ein "FATAL EXCEPTION|Fatal signal|SIGSEGV|SIGABRT|Abort message:|backtrace:|AgusMaps|AgusMapsFlutterNative|AndroidRuntime" "${logcat_file}" | tail -n 400 || true
  exit 1
fi

if grep -Eiq "FATAL EXCEPTION|Fatal signal [0-9]+ \((SIGSEGV|SIGABRT)\)|Abort message:|backtrace:" "${logcat_file}"; then
  echo "FAIL: native/application crash detected after tapping Mapa."
  grep -Ein "FATAL EXCEPTION|Fatal signal|SIGSEGV|SIGABRT|Abort message:|backtrace:|AgusMaps|AgusMapsFlutterNative|AndroidRuntime" "${logcat_file}" | tail -n 500 || true
  exit 1
fi

echo "PASS: application remained alive after tapping Mapa."
grep -E "AgusMaps|AgusMapsFlutterNative|nativeSetSurface|createDrapeEngine|Map ready|Surface" "${logcat_file}" | tail -n 200 || true
