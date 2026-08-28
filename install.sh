#!/usr/bin/env bash
# Transpeak — install the Claude Code surfaces into ~/.claude/
#
# Usage:
#   ./install.sh           # symlink (recommended — edits propagate)
#   ./install.sh --copy    # copy instead of symlink
#
# Installs two surfaces:
#   • slash command → /transpeak            (one-shot, session-scoped)
#   • output style  → Transpeak in /config  (persistent — survives compaction)
#
# For Claude.ai: see claude-ai/transpeak-style.md

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODE="link"
[[ "${1:-}" == "--copy" ]] && MODE="copy"

install_one() {
  local source="$1" target_dir="$2" target="$2/$3"
  mkdir -p "$target_dir"
  if [[ "$MODE" == "copy" ]]; then
    cp "$source" "$target"
    echo "✅ copied: $target"
  else
    ln -sf "$source" "$target"
    echo "✅ linked: $target → $source"
  fi
}

install_one "$REPO_DIR/claude-code/transpeak.md" \
            "$HOME/.claude/commands" "transpeak.md"
install_one "$REPO_DIR/claude-code/transpeak-style.md" \
            "$HOME/.claude/output-styles" "transpeak.md"

echo
echo "Next steps:"
echo "  • Claude Code → /config → Output style → Transpeak   (persistent)"
echo "  • Claude Code → /transpeak                           (one-shot)"
echo "  • Claude.ai   → see claude-ai/transpeak-style.md"
echo
echo "Note: only one output style is active at a time. If you already run"
echo "Glance as your output style, use /transpeak or the CLAUDE.md pointer"
echo "(see README) instead of switching styles."
