#!/usr/bin/env bash
set -euo pipefail

# このリポジトリをCodexの個人設定としてリンクする。
# マスターはこのリポジトリ。移動した場合は再実行する。

HARNESS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME_DIR="${CODEX_HOME:-${HOME}/.codex}"
SKILL_HOME="${HOME}/.agents/skills"

backup_or_unlink() {
  local dst="$1" backup
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    echo "既存の $dst を $backup に退避します"
    mv "$dst" "$backup"
  fi
}

mkdir -p "$CODEX_HOME_DIR/agents" "$SKILL_HOME"

backup_or_unlink "$CODEX_HOME_DIR/AGENTS.md"
ln -s "$HARNESS/AGENTS.md" "$CODEX_HOME_DIR/AGENTS.md"
echo "linked: $CODEX_HOME_DIR/AGENTS.md -> $HARNESS/AGENTS.md"

for entry in "$HARNESS/agents"/*.toml; do
  [[ -e "$entry" ]] || continue
  dst="$CODEX_HOME_DIR/agents/$(basename "$entry")"
  backup_or_unlink "$dst"
  ln -s "$entry" "$dst"
  echo "linked: $dst -> $entry"
done

for entry in "$HARNESS/skills"/*; do
  [[ -d "$entry" ]] || continue
  dst="$SKILL_HOME/$(basename "$entry")"
  backup_or_unlink "$dst"
  ln -s "$entry" "$dst"
  echo "linked: $dst -> $entry"
done

DOC_ROOT_RAW="$(sed -n 's/^DOC_STORAGE_ROOT=//p' "$HARNESS/skills/doc-storage/SKILL.md" | head -1)"
DOC_ROOT="${DOC_ROOT_RAW/#\~/$HOME}"

cat <<MSG

Codex用ハーネスをリンクしました。

  共通指示: $CODEX_HOME_DIR/AGENTS.md
  サブエージェント: $CODEX_HOME_DIR/agents/
  Skills: $SKILL_HOME/
  doc-storage: $DOC_ROOT

Codexを新しいセッションで起動し、/skills でSkillsを確認してください。
MSG
