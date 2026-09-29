#!/usr/bin/env bash
set -euo pipefail

snapshot="${COMAPS_BASE_SNAPSHOT:-260106}"
mkdir -p assets/maps

declare -A expected_sha1=(
  [World.mwm]="7a588f8c9d81ae26eb509b4b00ac8f790b2f5054"
  [WorldCoasts.mwm]="cfd2cce0526ca92cf03c1cc784e12d433bf590d9"
)

declare -A expected_size=(
  [World.mwm]="53029018"
  [WorldCoasts.mwm]="8505665"
)

mirrors=(
  "https://mapgen-fi-1.comaps.app/"
  "https://cdn-us-2.comaps.tech/"
  "https://comaps.firewall-gateway.de/"
)

download_one() {
  local file="$1"
  local dest="assets/maps/$file"
  local ok=0

  rm -f "$dest"

  for mirror in "${mirrors[@]}"; do
    local url="${mirror}maps/${snapshot}/${file}"
    echo "Downloading ${file} from ${url}"
    if curl --fail --silent --show-error --location       --retry 4 --retry-all-errors       --connect-timeout 20 --max-time 900       "${url}" -o "${dest}"; then

      local actual_size
      actual_size="$(wc -c < "${dest}" | tr -d '[:space:]')"
      if [[ "${actual_size}" != "${expected_size[$file]}" ]]; then
        echo "WARNING: size mismatch for ${file}: expected ${expected_size[$file]}, got ${actual_size}" >&2
        rm -f "${dest}"
        continue
      fi

      if command -v sha1sum >/dev/null 2>&1; then
        echo "${expected_sha1[$file]}  ${dest}" | sha1sum -c -
      else
        actual_sha1="$(shasum -a 1 "${dest}" | awk '{print $1}')"
        test "${actual_sha1}" = "${expected_sha1[$file]}"
      fi
      echo "verified=${dest}"
      ok=1
      break
    fi

    rm -f "${dest}"
  done

  if [[ "${ok}" != "1" ]]; then
    echo "ERROR: unable to obtain verified ${file} for CoMaps snapshot ${snapshot}" >&2
    exit 1
  fi
}

download_one "World.mwm"
download_one "WorldCoasts.mwm"

echo "CoMaps base maps prepared: snapshot=${snapshot}"
