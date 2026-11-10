#!/usr/bin/env bash
# Update portfolio thesis-url.json from the UML pipeline's live tunnel URL,
# then optionally commit & push so https://dipak5501.github.io/ stays current.
#
# Usage:
#   ./update-thesis-url.sh                  # sync from GitHub Link.md / local files
#   ./update-thesis-url.sh --url URL        # set UI URL explicitly
#   ./update-thesis-url.sh --push           # sync + commit + push portfolio
#   ./update-thesis-url.sh --url URL --push
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
JSON="$ROOT/thesis-url.json"
UML_LOCAL_CANDIDATES=(
  "$HOME/Desktop/uml-generation-pipeline"
  "$HOME/Desktop/UML"
  "$HOME/Desktop/uml-generation-pipeline-complete"
)

UI_URL=""
API_URL=""
DO_PUSH=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) UI_URL="${2:-}"; shift 2 ;;
    --api) API_URL="${2:-}"; shift 2 ;;
    --push) DO_PUSH=1; shift ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

extract_ui() {
  local text="$1"
  printf '%s\n' "$text" | grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' | head -1 || true
}

extract_api() {
  local text="$1"
  # Prefer a second distinct trycloudflare host (API) if present
  printf '%s\n' "$text" | grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' | awk 'NR==1{u=$0; next} $0!=u{print; exit}'
}

if [[ -z "$UI_URL" ]]; then
  # 1) Local public_ui_url.txt / Link.md
  for dir in "${UML_LOCAL_CANDIDATES[@]}"; do
    if [[ -f "$dir/data/run/public_ui_url.txt" ]]; then
      UI_URL="$(tr -d '[:space:]' < "$dir/data/run/public_ui_url.txt")"
      [[ -f "$dir/data/run/public_api_url.txt" ]] && API_URL="$(tr -d '[:space:]' < "$dir/data/run/public_api_url.txt")"
      SOURCE="local $dir/data/run/public_ui_url.txt"
      break
    fi
    if [[ -f "$dir/Link.md" ]]; then
      UI_URL="$(extract_ui "$(cat "$dir/Link.md")")"
      API_URL="$(extract_api "$(cat "$dir/Link.md")")"
      SOURCE="local $dir/Link.md"
      [[ -n "$UI_URL" ]] && break
    fi
  done
fi

if [[ -z "$UI_URL" ]] && command -v gh >/dev/null 2>&1; then
  REMOTE="$(gh api repos/dipak5501/uml-generation-pipeline/contents/Link.md --jq .content 2>/dev/null | base64 -d 2>/dev/null || true)"
  if [[ -n "$REMOTE" ]]; then
    UI_URL="$(extract_ui "$REMOTE")"
    API_URL="$(extract_api "$REMOTE")"
    SOURCE="github dipak5501/uml-generation-pipeline Link.md"
  fi
fi

if [[ -z "$UI_URL" ]]; then
  echo "Could not find a trycloudflare UI URL." >&2
  echo "Pass one explicitly: ./update-thesis-url.sh --url https://xxx.trycloudflare.com --push" >&2
  exit 1
fi

UI_URL="${UI_URL%/}"
API_URL="${API_URL%/}"
UPDATED="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
SOURCE="${SOURCE:-manual --url}"

python3 - "$JSON" "$UI_URL" "$API_URL" "$UPDATED" "$SOURCE" <<'PY'
import json, sys
path, ui, api, updated, source = sys.argv[1:6]
data = {
    "ui": ui,
    "api": api or "",
    "updated": updated,
    "source": source,
    "note": "Quick-tunnel URLs rotate when cloudflared restarts. Update this file (or run ./update-thesis-url.sh) then commit & push.",
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"Wrote {path}")
print(f"  ui:  {ui}")
print(f"  api: {api or '(none)'}")
print(f"  updated: {updated}")
print(f"  source: {source}")
PY

if [[ "$DO_PUSH" -eq 1 ]]; then
  cd "$ROOT"
  git add thesis-url.json
  if git diff --cached --quiet; then
    echo "No change to push (URL already current)."
    exit 0
  fi
  git -c user.email="71300693+dipak5501@users.noreply.github.com" \
      -c user.name="dipak5501" \
      commit -m "Update thesis live tunnel URL"
  git push origin main
  echo "Pushed. Live site will pick up thesis-url.json after Pages rebuild."
fi
