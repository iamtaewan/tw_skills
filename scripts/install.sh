#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/install.sh [--copy|--link]

Installs every skill under ./skills into ${CODEX_HOME:-$HOME/.codex}/skills.

Default:
  --copy  Remove the existing installed skill target, then copy a fresh physical
          snapshot from this repository. This avoids symlink confusion and keeps
          the installed skill fixed until the next install.

Development:
  --link  Remove the existing installed skill target, then symlink it to this
          repository for live editing.
USAGE
}

mode="copy"
case "${1:-}" in
  ""|--copy)
    mode="copy"
    ;;
  --link)
    mode="link"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CODEX_SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"

mkdir -p "$CODEX_SKILLS_DIR"

for skill_dir in "$REPO_ROOT"/skills/*; do
  [ -d "$skill_dir" ] || continue
  [ -f "$skill_dir/SKILL.md" ] || continue

  skill_name="$(basename "$skill_dir")"
  target="$CODEX_SKILLS_DIR/$skill_name"

  if [ -e "$target" ] || [ -L "$target" ]; then
    rm -rf "$target"
    echo "removed: $skill_name"
  fi

  if [ "$mode" = "link" ]; then
    ln -s "$skill_dir" "$target"
    echo "installed(link): $skill_name"
  else
    mkdir -p "$target"
    cp -R "$skill_dir"/. "$target"/
    find "$target" -name '.DS_Store' -delete
    echo "installed(copy): $skill_name"
  fi
done

echo "Restart Codex to pick up new skills."
