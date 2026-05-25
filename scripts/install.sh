#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CODEX_SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"

mkdir -p "$CODEX_SKILLS_DIR"

for skill_dir in "$REPO_ROOT"/skills/*; do
  [ -d "$skill_dir" ] || continue
  [ -f "$skill_dir/SKILL.md" ] || continue

  skill_name="$(basename "$skill_dir")"
  target="$CODEX_SKILLS_DIR/$skill_name"

  if [ -L "$target" ]; then
    current_target="$(readlink "$target")"
    if [ "$current_target" = "$skill_dir" ]; then
      echo "ok: $skill_name already linked"
    else
      echo "skip: $skill_name already linked to $current_target"
    fi
  elif [ -e "$target" ]; then
    echo "skip: $skill_name already exists at $target"
  else
    ln -s "$skill_dir" "$target"
    echo "installed: $skill_name"
  fi
done

echo "Restart Codex to pick up new skills."

