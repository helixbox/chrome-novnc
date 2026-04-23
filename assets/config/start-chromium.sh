#!/usr/bin/env bash
set -euo pipefail

profile_dir="${CHROME_PROFILE_DIR:-/root/.config/chromium}"
default_dir="${profile_dir}/Default"
preferences_path="${default_dir}/Preferences"

mkdir -p "$default_dir"

if [ -n "${CHROME_ACCEPT_LANGUAGES:-}" ]; then
  python3 - "$preferences_path" "$CHROME_ACCEPT_LANGUAGES" <<'PY'
import json
import os
import sys

path, accept_languages = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError:
        data = {}

intl = data.setdefault("intl", {})
intl["accept_languages"] = accept_languages

tmp_path = path + ".tmp"
with open(tmp_path, "w", encoding="utf-8") as f:
    json.dump(data, f, separators=(",", ":"))
os.replace(tmp_path, path)
PY
fi

args=(
  --no-sandbox
  --disable-sync
  --disable-popup-blocking
  --disable-dev-shm-usage
  --disable-gpu
  --start-maximized
  --force-device-scale-factor=1
  --remote-debugging-port=9223
  --remote-debugging-address=127.0.0.1
  "--user-data-dir=${profile_dir}"
)

if [ -n "${CHROME_LANG:-}" ]; then
  args+=("--lang=${CHROME_LANG}")
fi

if [ -n "${CHROME_ACCEPT_LANGUAGES:-}" ]; then
  args+=("--accept-lang=${CHROME_ACCEPT_LANGUAGES}")
fi

if [ -n "${CHROME_EXTRA_ARGS:-}" ]; then
  read -r -a extra_args <<< "$CHROME_EXTRA_ARGS"
  args+=("${extra_args[@]}")
fi

exec chromium "${args[@]}"
