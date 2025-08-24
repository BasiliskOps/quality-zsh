#!/bin/zsh
set -euo pipefail

usage() {
  cat <<'USAGE'
Sync minimal quality files into a target repo, making backups if needed.

Usage:
  ./scripts/sync_to_repo.zsh /abs/or/relative/path/to/target-repo

This copies:
  - .github/workflows/ci.yml
  - .github/PULL_REQUEST_TEMPLATE.md
  - .github/CODEOWNERS (only if not present)
  - scripts/run_checks.zsh
  - installs .git/hooks/pre-commit and .git/hooks/commit-msg using the zsh scripts

It does NOT copy sample_crate or workspace files.
USAGE
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_ROOT="$(cd "$1" && pwd)"

# Sanity checks
if [[ ! -d "$TARGET_ROOT/.git" ]]; then
  echo "✖ Target is not a git repo: $TARGET_ROOT"
  exit 1
fi

backup_if_exists() {
  local f="$1"
  if [[ -e "$f" ]]; then
    local ts="$(date +%Y%m%d-%H%M%S)"
    local bak="${f}.bak.${ts}"
    echo "↪ Backing up existing $(basename "$f") -> $(basename "$bak")"
    cp -p "$f" "$bak"
  fi
}

ensure_dir() {
  local d="$1"
  if [[ ! -d "$d" ]]; then
    mkdir -p "$d"
  fi
}

copy_file() {
  local src="$1"
  local dst="$2"
  ensure_dir "$(dirname "$dst")"
  backup_if_exists "$dst"
  cp -p "$src" "$dst"
  echo "✓ Copied $(realpath --relative-to="$TARGET_ROOT" "$dst" 2>/dev/null || echo "$dst")"
}

echo "== Quality sync =="
echo "Source: $SOURCE_ROOT"
echo "Target: $TARGET_ROOT"

# Copy workflow
copy_file "$SOURCE_ROOT/.github/workflows/ci.yml" "$TARGET_ROOT/.github/workflows/ci.yml"

# PR template
copy_file "$SOURCE_ROOT/.github/PULL_REQUEST_TEMPLATE.md" "$TARGET_ROOT/.github/PULL_REQUEST_TEMPLATE.md"

# CODEOWNERS only if not present
if [[ ! -f "$TARGET_ROOT/.github/CODEOWNERS" ]]; then
  copy_file "$SOURCE_ROOT/.github/CODEOWNERS" "$TARGET_ROOT/.github/CODEOWNERS"
else
  echo "• Skipped CODEOWNERS (already exists)"
fi

# scripts/run_checks.zsh
copy_file "$SOURCE_ROOT/scripts/run_checks.zsh" "$TARGET_ROOT/scripts/run_checks.zsh"
chmod +x "$TARGET_ROOT/scripts/run_checks.zsh"

# Install git hooks (copy, not symlink, for portability)
ensure_dir "$TARGET_ROOT/.git/hooks"
backup_if_exists "$TARGET_ROOT/.git/hooks/pre-commit"
backup_if_exists "$TARGET_ROOT/.git/hooks/commit-msg"
cp -p "$SOURCE_ROOT/scripts/pre-commit.zsh" "$TARGET_ROOT/.git/hooks/pre-commit"
cp -p "$SOURCE_ROOT/scripts/commit-msg.zsh" "$TARGET_ROOT/.git/hooks/commit-msg"
chmod +x "$TARGET_ROOT/.git/hooks/pre-commit" "$TARGET_ROOT/.git/hooks/commit-msg"
echo "✓ Installed git hooks"

echo "== Done =="
echo "Run local checks inside target repo:"
echo "  cd \"$TARGET_ROOT\" && ./scripts/run_checks.zsh"
