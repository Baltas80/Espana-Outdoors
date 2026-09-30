#!/usr/bin/env bash
set -euo pipefail

apk_path="${1:?APK path required}"
aapt_path="$(find "${ANDROID_HOME}/build-tools" -maxdepth 2 -type f -name aapt -print | sort -V | tail -n 1)"
test -x "${aapt_path}"
package_name="$("${aapt_path}" dump badging "${apk_path}" | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -n 1)"
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

sleep 5
window_file="${RUNNER_TEMP:-/tmp}/espana-window.xml"
adb exec-out uiautomator dump /dev/tty 2>/tmp/espana-uiautomator.err >"${window_file}" || true

if ! grep -q '<hierarchy' "${window_file}"; then
  echo "FAIL: UIAutomator did not return a hierarchy."
  cat /tmp/espana-uiautomator.err || true
  head -c 2000 "${window_file}" || true
  exit 1
fi

read -r tap_x tap_y < <(
  python3 - "${window_file}" <<'PY'
import re
import sys
import xml.etree.ElementTree as ET

path = sys.argv[1]
raw = open(path, "rb").read().decode("utf-8", errors="replace")
start = raw.find("<?xml")
if start < 0:
    start = raw.find("<hierarchy")
if start < 0:
    raise SystemExit("Could not locate UIAutomator XML hierarchy")
end = raw.find("</hierarchy>", start)
if end < 0:
    raise SystemExit("UIAutomator hierarchy is incomplete")
root = ET.fromstring(raw[start:end + len("</hierarchy>")])
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

echo "Waiting for PMTiles map startup..."
sleep 15

logcat_file="${RUNNER_TEMP:-/tmp}/espana-outdoor-map-logcat.txt"
screenshot_file="${RUNNER_TEMP:-/tmp}/espana-outdoor-map.png"
adb logcat -d >"${logcat_file}"
adb exec-out screencap -p >"${screenshot_file}"

test -s "${screenshot_file}"
pid="$(adb shell pidof "${package_name}" 2>/dev/null | tr -d '\r' | tr -d '\n' || true)"
if test -z "${pid}"; then
  echo "FAIL: application process is not alive after tapping Mapa."
  grep -Ein "FATAL EXCEPTION|Fatal signal|SIGSEGV|SIGABRT|Abort message:|backtrace:|AndroidRuntime|flutter_map|PMTiles|VectorTile" "${logcat_file}" | tail -n 400 || true
  exit 1
fi

if grep -Eiq "FATAL EXCEPTION|Fatal signal [0-9]+ \((SIGSEGV|SIGABRT)\)|Abort message:|backtrace:" "${logcat_file}"; then
  echo "FAIL: native/application crash detected after tapping Mapa."
  grep -Ein "FATAL EXCEPTION|Fatal signal|SIGSEGV|SIGABRT|Abort message:|backtrace:|AndroidRuntime|flutter_map|PMTiles|VectorTile" "${logcat_file}" | tail -n 500 || true
  exit 1
fi

# The map must not merely keep the Flutter process alive: the PMTiles screen
# itself must be visible and must not expose the loader error/retry state.
post_window="${RUNNER_TEMP:-/tmp}/espana-window-post-map.xml"
adb exec-out uiautomator dump /dev/tty 2>/tmp/espana-uiautomator-post.err >"${post_window}" || true
if grep -Fq 'No se pudo cargar el mapa' "${post_window}" || grep -Fq 'Reintentar' "${post_window}"; then
  echo "FAIL: PMTiles map is showing the map loader error state."
  cat "${post_window}"
  grep -Ein "StyleReaderException|PmTilesException|HTTP [0-9]{3}|Range|flutter_map|PMTiles|VectorTile" "${logcat_file}" | tail -n 500 || true
  exit 1
fi

if grep -Eiq "StyleReaderException|PmTilesException" "${logcat_file}"; then
  echo "FAIL: PMTiles/style exception detected."
  grep -Ein "StyleReaderException|PmTilesException|HTTP [0-9]{3}|Range|flutter_map|PMTiles|VectorTile" "${logcat_file}" | tail -n 500 || true
  exit 1
fi

echo "PASS: PMTiles map remained alive and the visible UI is not in the loader error state."
grep -Ei "flutter_map|PMTiles|VectorTile|tile|Range" "${logcat_file}" | tail -n 200 || true
