#!/usr/bin/env bash
set -euo pipefail

apk_path="${1:?APK path required}"
package_name="$(aapt dump badging "${apk_path}" | sed -n "s/^package: name='\\([^']*\\)'.*/\\1/p" | head -n 1)"
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

echo "Waiting for map surface..."
sleep 15

adb shell dumpsys activity activities | grep -F "${package_name}" || true
adb shell pidof "${package_name}" >/tmp/espana-pid.txt || true

logcat_file="${RUNNER_TEMP:-/tmp}/espana-outdoor-map-logcat.txt"
adb logcat -d >"${logcat_file}"

if ! test -s /tmp/espana-pid.txt; then
  echo "FAIL: application process is not alive after map startup."
  grep -E "FATAL EXCEPTION|Fatal signal|SIGSEGV|SIGABRT|AgusMaps|AndroidRuntime|libagus|DEBUG" "${logcat_file}" | tail -n 300 || true
  exit 1
fi

if grep -Eiq "FATAL EXCEPTION|Fatal signal [0-9]+ \((SIGSEGV|SIGABRT)\)|Abort message:|backtrace:" "${logcat_file}"; then
  echo "FAIL: native/application crash detected during map startup."
  grep -Ein "FATAL EXCEPTION|Fatal signal|SIGSEGV|SIGABRT|Abort message:|backtrace:|AgusMaps|AndroidRuntime|libagus" "${logcat_file}" | tail -n 400 || true
  exit 1
fi

echo "PASS: application remained alive for map startup smoke test."
echo "PID: $(cat /tmp/espana-pid.txt)"
grep -E "AgusMaps|onSurfaceAvailable|createMapSurface|Map ready|comaps" "${logcat_file}" | tail -n 120 || true
