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
adb shell am force-stop "${package_name}"
adb shell monkey -p "${package_name}" 1 >/tmp/espana-monkey.log 2>&1 || {
  cat /tmp/espana-monkey.log
  exit 1
}

# Android emulators can surface transient system-level "application isn't
# responding" dialogs after boot (for example Launcher or Google setup).
# Such dialogs block the accessibility tree and can make a healthy app look
# invisible to UIAutomator. Dismiss only these system dialogs; never dismiss
# an ANR belonging to the application under test.
dismiss_system_anr() {
  local dialog_file="${RUNNER_TEMP:-/tmp}/espana-system-dialog.xml"
  local attempt
  for attempt in 1 2 3 4 5 6; do
    adb exec-out uiautomator dump /dev/tty 2>/dev/null >"${dialog_file}" || true
    if ! grep -Fq "isn't responding" "${dialog_file}" && ! grep -Fq "isn\u0027t responding" "${dialog_file}"; then
      return 0
    fi

    read -r wait_x wait_y < <(
      python3 - "${dialog_file}" <<'PY'
import re
import sys
import xml.etree.ElementTree as ET

path = sys.argv[1]
raw = open(path, "rb").read().decode("utf-8", errors="replace")
start = raw.find("<?xml")
if start < 0:
    start = raw.find("<hierarchy")
end = raw.find("</hierarchy>", start)
if start < 0 or end < 0:
    raise SystemExit(0)
root = ET.fromstring(raw[start:end + len("</hierarchy>")])
for node in root.iter("node"):
    if (node.attrib.get("text") or "").strip() != "Wait":
        continue
    match = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", node.attrib.get("bounds", ""))
    if not match:
        continue
    x1, y1, x2, y2 = map(int, match.groups())
    print((x1 + x2) // 2, (y1 + y2) // 2)
    raise SystemExit(0)
PY
    )

    if test -n "${wait_x:-}" && test -n "${wait_y:-}"; then
      echo "Dismissing system ANR with Wait at ${wait_x},${wait_y}"
      adb shell input tap "${wait_x}" "${wait_y}"
    else
      echo "Dismissing system ANR with BACK"
      adb shell input keyevent 4
    fi
    sleep 2
  done
}

dismiss_system_anr
sleep 5
# A second system component can surface its own delayed ANR after the first
# dialog is dismissed. Recheck immediately before inspecting the app UI.
dismiss_system_anr

after_launch_window="${RUNNER_TEMP:-/tmp}/espana-window-pre-map.xml"
adb exec-out uiautomator dump /dev/tty 2>/tmp/espana-uiautomator-pre.err >"${after_launch_window}" || true
if grep -Fq "isn't responding" "${after_launch_window}" || grep -Fq "isn\u0027t responding" "${after_launch_window}"; then
  echo "FAIL: a system ANR dialog is still blocking the app UI."
  cat "${after_launch_window}"
  exit 1
fi

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
