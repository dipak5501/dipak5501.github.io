#!/usr/bin/env bash
# Update portfolio thesis-url.json from the UML pipeline's live tunnel URL,
# then optionally commit & push so https://dipak5501.github.io/ stays current.
#
# Auto-sync (preferred): GitHub Actions keep this in sync without running locally.
#   - Portfolio: .github/workflows/sync-thesis-url.yml (cron every 15m + dispatch)
#   - Pipeline:  uml-generation-pipeline sync-portfolio-thesis-url.yml (on Link.md push)
# Manual:
#   ./update-thesis-url.sh                  # sync (GitHub Link.md preferred)
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
SOURCE=""
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
  printf '%s\n' "$text" | grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' | awk 'NR==1{u=$0; next} $0!=u{print; exit}'
}

url_alive() {
  local u="$1"
  local code
  code="$(curl -sI -o /dev/null -w '%{http_code}' --max-time 8 "$u" 2>/dev/null || true)"
  [[ "$code" =~ ^(200|301|302|303|307|308)$ ]]
}

if [[ -z "$UI_URL" ]]; then
  # 1) Prefer GitHub Link.md (canonical / auto-updated by tunnel_notify)
  if command -v gh >/dev/null 2>&1; then
    REMOTE="$(gh api repos/dipak5501/uml-generation-pipeline/contents/Link.md --jq .content 2>/dev/null | base64 -d 2>/dev/null || true)"
    if [[ -n "$REMOTE" ]]; then
      CAND_UI="$(extract_ui "$REMOTE")"
      CAND_API="$(extract_api "$REMOTE")"
      if [[ -n "$CAND_UI" ]] && url_alive "$CAND_UI"; then
        UI_URL="$CAND_UI"
        API_URL="$CAND_API"
        SOURCE="github dipak5501/uml-generation-pipeline Link.md"
      elif [[ -n "$CAND_UI" ]]; then
        echo "GitHub Link.md UI not reachable yet: $CAND_UI (will try local)" >&2
        GH_UI="$CAND_UI"
        GH_API="$CAND_API"
      fi
    fi
  fi
fi

if [[ -z "$UI_URL" ]]; then
  # 2) Local public_ui_url.txt (fresh run state) before stale Link.md
  for dir in "${UML_LOCAL_CANDIDATES[@]}"; do
    if [[ -f "$dir/data/run/public_ui_url.txt" ]]; then
      CAND_UI="$(tr -d '[:space:]' < "$dir/data/run/public_ui_url.txt")"
      CAND_API=""
      [[ -f "$dir/data/run/public_api_url.txt" ]] && CAND_API="$(tr -d '[:space:]' < "$dir/data/run/public_api_url.txt")"
      if [[ -n "$CAND_UI" ]] && url_alive "$CAND_UI"; then
        UI_URL="$CAND_UI"
        API_URL="$CAND_API"
        SOURCE="local $dir/data/run/public_ui_url.txt"
        break
      fi
    fi
  done
fi

if [[ -z "$UI_URL" ]]; then
  # 3) Local Link.md only if alive
  for dir in "${UML_LOCAL_CANDIDATES[@]}"; do
    if [[ -f "$dir/Link.md" ]]; then
      CAND_UI="$(extract_ui "$(cat "$dir/Link.md")")"
      CAND_API="$(extract_api "$(cat "$dir/Link.md")")"
      if [[ -n "$CAND_UI" ]] && url_alive "$CAND_UI"; then
        UI_URL="$CAND_UI"
        API_URL="$CAND_API"
        SOURCE="local $dir/Link.md"
        break
      fi
    fi
  done
fi

# 4) Fall back to GitHub URL even if probe failed (Pages can still point at published Link)
if [[ -z "$UI_URL" && -n "${GH_UI:-}" ]]; then
  UI_URL="$GH_UI"
  API_URL="${GH_API:-}"
  SOURCE="github dipak5501/uml-generation-pipeline Link.md (unreachable at sync time)"
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

# Keep HTML fallbacks in sync for no-JS / first paint
python3 - "$ROOT" "$UI_URL" <<'PY'
import pathlib, re, sys
root, ui = pathlib.Path(sys.argv[1]), sys.argv[2]
pat = re.compile(r'(data-thesis-live[\s\S]*?href=")https://[a-z0-9-]+\.trycloudflare\.com/?(")')
for name in ("about.html", "thesis.html"):
    path = root / name
    text = path.read_text(encoding="utf-8")
    new, n = pat.subn(rf'\1{ui}\2', text)
    if n:
        path.write_text(new, encoding="utf-8")
        print(f"Patched {n} href fallback(s) in {name}")
PY

if [[ "$DO_PUSH" -eq 1 ]]; then
  cd "$ROOT"
  git add thesis-url.json about.html thesis.html update-thesis-url.sh
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
