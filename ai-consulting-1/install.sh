#!/usr/bin/env bash
# Installs the Imogen AI consulting skills into Claude Code.
#   curl -fsSL https://raw.githubusercontent.com/terddyy/imogen-skills/main/ai-consulting-1/install.sh | bash
# Re-run to update. Set CLAUDE_SKILLS_DIR to install somewhere else (e.g. ./.claude/skills for one project).
set -euo pipefail

REPO="terddyy/imogen-skills"
BRANCH="${IMOGEN_BRANCH:-main}"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
ARCHIVE_URL="${IMOGEN_ARCHIVE_URL:-https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH}"

command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
command -v tar >/dev/null || { echo "tar is required" >&2; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Downloading $REPO@$BRANCH..."
curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$tmp"

src="$(find "$tmp" -mindepth 2 -maxdepth 2 -type d -name ai-consulting-1 | head -n 1)"
[ -n "$src" ] || { echo "ai-consulting-1 not found in the download" >&2; exit 1; }

mkdir -p "$DEST"
count=0
for dir in "$src"/*/; do
  [ -f "$dir/SKILL.md" ] || continue
  name="$(basename "$dir")"
  rm -rf "${DEST:?}/$name"
  cp -R "$dir" "$DEST/$name"
  echo "  + $name"
  count=$((count + 1))
done

echo "Installed $count skills to $DEST"
echo "Start a new Claude Code session, then just describe what you're doing (or run /ask-imogen)."
