#!/usr/bin/env bash
# Watch flutter logs for STORE_SHOT markers and capture simctl screenshots.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE="${1:?device UDID required}"
OUT_DIR="${2:?output dir required (e.g. store_screenshots/raw/iphone)}"
LOG_FILE="${3:?flutter log file path}"

mkdir -p "$OUT_DIR"

echo "Watching $LOG_FILE for STORE_SHOT markers → $OUT_DIR (device $DEVICE)"

captured=()
mark_done=0

capture() {
  local id="$1"
  local dest="$OUT_DIR/${id}.png"
  # Avoid double-capture for the same id
  for c in "${captured[@]:-}"; do
    [[ "$c" == "$id" ]] && return 0
  done
  sleep 0.6
  xcrun simctl io "$DEVICE" screenshot "$dest"
  echo "captured $dest"
  captured+=("$id")
}

# Poll log file until DONE or timeout (~4 minutes)
deadline=$((SECONDS + 240))
cursor=0
while (( SECONDS < deadline )); do
  if [[ ! -f "$LOG_FILE" ]]; then
    sleep 0.5
    continue
  fi
  # Read new lines since cursor
  size=$(wc -c < "$LOG_FILE" | tr -d ' ')
  if (( size > cursor )); then
    new=$(dd if="$LOG_FILE" bs=1 skip="$cursor" count=$((size - cursor)) 2>/dev/null || true)
    cursor=$size
    while IFS= read -r line; do
      if [[ "$line" =~ STORE_SHOT:([A-Za-z0-9_-]+) ]]; then
        id="${BASH_REMATCH[1]}"
        case "$id" in
          DONE) mark_done=1; echo "tour complete"; break 2 ;;
          ERROR) echo "tour error: $line"; exit 1 ;;
          WARN*) echo "$line" ;;
          *) capture "$id" ;;
        esac
      fi
    done <<< "$new"
  fi
  sleep 0.25
done

if (( mark_done == 0 )); then
  echo "Timed out waiting for STORE_SHOT:DONE" >&2
  exit 1
fi

echo "Captured ${#captured[@]} screenshots into $OUT_DIR"
