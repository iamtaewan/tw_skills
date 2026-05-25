#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
status=0

for skill_dir in "$REPO_ROOT"/skills/*; do
  [ -d "$skill_dir" ] || continue

  skill_name="$(basename "$skill_dir")"
  skill_file="$skill_dir/SKILL.md"

  if [ ! -f "$skill_file" ]; then
    echo "fail: $skill_name missing SKILL.md"
    status=1
    continue
  fi

  if ! grep -q '^---$' "$skill_file"; then
    echo "fail: $skill_name missing YAML frontmatter delimiter"
    status=1
  fi

  if ! grep -q '^name:' "$skill_file"; then
    echo "fail: $skill_name missing name"
    status=1
  fi

  if ! grep -q '^description:' "$skill_file"; then
    echo "fail: $skill_name missing description"
    status=1
  fi

  echo "checked: $skill_name"
done

exit "$status"

