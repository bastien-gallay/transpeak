#!/usr/bin/env bash
# Generate surface files from prompt.md.
# Usage: ./build.sh           # write derived files
#        ./build.sh --check   # exit 1 if any derived file would change
set -euo pipefail

cd "$(dirname "$0")"

SOURCE="prompt.md"
START="<!-- transpeak:body:start -->"
END="<!-- transpeak:body:end -->"

TARGETS=(
  "claude-code/transpeak.md.tmpl:claude-code/transpeak.md"
  "claude-code/transpeak-style.md.tmpl:claude-code/transpeak-style.md"
  "claude-ai/transpeak-style.md.tmpl:claude-ai/transpeak-style.md"
)

body_file=$(mktemp "${TMPDIR:-/tmp}/transpeak.XXXXXX")
trap 'rm -f "$body_file"' EXIT
awk -v s="$START" -v e="$END" '
  $0 == s { inside=1; next }
  $0 == e { inside=0; next }
  inside { print }
' "$SOURCE" > "$body_file"

if [[ ! -s "$body_file" ]]; then
  echo "build.sh: no body found between $START and $END in $SOURCE" >&2
  exit 1
fi

mode="${1:-write}"
status=0

for pair in "${TARGETS[@]}"; do
  tmpl="${pair%%:*}"
  out="${pair##*:}"
  rendered=$(awk -v body_file="$body_file" '
    {
      if (index($0, "{{BODY}}")) {
        while ((getline line < body_file) > 0) print line
        close(body_file)
      } else {
        print
      }
    }
  ' "$tmpl")

  case "$mode" in
    --check)
      tmp_out=$(mktemp "${TMPDIR:-/tmp}/transpeak.XXXXXX")
      printf '%s\n' "$rendered" > "$tmp_out"
      if ! diff -u "$out" "$tmp_out" >/dev/null; then
        echo "build.sh: $out is out of sync with $tmpl + $SOURCE" >&2
        diff -u "$out" "$tmp_out" >&2 || true
        status=1
      fi
      rm -f "$tmp_out"
      ;;
    write)
      printf '%s\n' "$rendered" > "$out"
      echo "build.sh: wrote $out"
      ;;
    *)
      echo "build.sh: unknown mode '$mode' (use --check or no arg)" >&2
      exit 2
      ;;
  esac
done

if [[ "$mode" == "write" && $status -eq 0 ]] && command -v markdownlint >/dev/null 2>&1; then
  markdownlint "$SOURCE" "${TARGETS[@]##*:}" || status=$?
fi

exit $status
