#!/usr/bin/env bash
# Installs the Imogen AI consulting skills for Claude Code, Codex and Cursor.
#   curl -fsSL https://raw.githubusercontent.com/terddyy/imogen-skills/main/ai-consulting-1/install.sh | bash
# Re-run to update.
#   IMOGEN_TOOLS=claude,codex,cursor   pick tools instead of auto-detecting
#   IMOGEN_SKILLS_DIR=.agents/skills   install into one folder only (e.g. a single project)
set -euo pipefail

REPO="terddyy/imogen-skills"
BRANCH="${IMOGEN_BRANCH:-main}"
ARCHIVE_URL="${IMOGEN_ARCHIVE_URL:-https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH}"

command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
command -v tar >/dev/null || { echo "tar is required" >&2; exit 1; }

has_tool() {
  case "$1" in
    claude) [ -d "$HOME/.claude" ] || command -v claude >/dev/null ;;
    codex)  [ -d "$HOME/.codex" ]  || command -v codex  >/dev/null ;;
    cursor) [ -d "$HOME/.cursor" ] || command -v cursor >/dev/null ;;
  esac
}

# Claude Code reads ~/.claude/skills, Codex reads ~/.agents/skills, and Cursor reads both
# (plus ~/.cursor/skills). Pick the fewest folders that cover the tools in use, so Cursor
# doesn't list every skill twice unless Claude and Codex are both installed.
if [ -n "${IMOGEN_SKILLS_DIR:-}" ]; then
  targets=("$IMOGEN_SKILLS_DIR")
else
  tools="${IMOGEN_TOOLS:-}"
  if [ -z "$tools" ]; then
    for t in claude codex cursor; do has_tool "$t" && tools="$tools,$t"; done
    tools="${tools#,}"
  fi
  if [ -z "$tools" ]; then
    echo "No Claude Code, Codex or Cursor install found; installing for all three."
    tools="claude,codex,cursor"
  fi
  targets=()
  case ",$tools," in *,claude,*) targets+=("$HOME/.claude/skills") ;; esac
  case ",$tools," in *,codex,*)  targets+=("$HOME/.agents/skills") ;; esac
  case ",$tools," in *,cursor,*) [ ${#targets[@]} -gt 0 ] || targets+=("$HOME/.cursor/skills") ;; esac
  [ ${#targets[@]} -gt 0 ] || { echo "IMOGEN_TOOLS must list claude, codex and/or cursor" >&2; exit 1; }
  echo "Installing for: ${tools//,/, }"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Downloading $REPO@$BRANCH..."
curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$tmp"

src="$(find "$tmp" -mindepth 2 -maxdepth 2 -type d -name ai-consulting-1 | head -n 1)"
[ -n "$src" ] || { echo "ai-consulting-1 not found in the download" >&2; exit 1; }

for dest in "${targets[@]}"; do
  mkdir -p "$dest"
  count=0
  for dir in "$src"/*/; do
    [ -f "$dir/SKILL.md" ] || continue
    name="$(basename "$dir")"
    rm -rf "${dest:?}/$name"
    cp -R "$dir" "$dest/$name"
    count=$((count + 1))
  done
  echo "  $count skills -> $dest"
done

echo "Done. Start a new session, then describe what you're doing or call ask-imogen"
echo "(Claude Code / Cursor: /ask-imogen   Codex: \$ask-imogen)."
