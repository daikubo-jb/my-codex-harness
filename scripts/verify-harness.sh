#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
shopt -s nullglob

fail() {
  printf '検証失敗: %s\n' "$*" >&2
  exit 1
}

require_symlink() {
  local path="$1"
  [[ -L "$path" ]] || fail "シンボリックリンクがありません: $path"
}

printf '%s\n' '[1/4] shell syntax'
if ! bash -n "$ROOT/install.sh"; then
  fail "bash構文: $ROOT/install.sh"
fi
for script in "$ROOT"/scripts/*.sh; do
  [[ "$script" == "$ROOT/scripts/verify-harness.sh" ]] && continue
  if ! bash -n "$script"; then
    fail "bash構文: $script"
  fi
done

printf '%s\n' '[2/4] TOML, frontmatter, and references'
command -v python3 >/dev/null 2>&1 || { echo 'python3 が必要です（TOML検証を省略して成功扱いしません）' >&2; exit 1; }
python3 - "$ROOT" <<'PY'
import pathlib
import re
import sys
import tomllib

root = pathlib.Path(sys.argv[1])
agent_files = sorted((root / "agents").glob("*.toml"))
if not agent_files:
    raise SystemExit("agents/*.toml がありません")

names = []
for path in agent_files:
    with path.open("rb") as fh:
        data = tomllib.load(fh)
    for key in ("name", "description", "model", "model_reasoning_effort", "sandbox_mode", "developer_instructions"):
        if not isinstance(data.get(key), str) or not data[key].strip():
            raise SystemExit(f"{path}: {key} がありません")
    names.append(data["name"])
    if path.name == "code-reviewer.toml" and data["sandbox_mode"] != "read-only":
        raise SystemExit("code-reviewer.toml は read-only である必要があります")

if len(names) != len(set(names)):
    raise SystemExit(f"エージェント名が重複しています: {names}")

skill_names = []
for path in sorted((root / "skills").glob("*/SKILL.md")):
    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not match:
        raise SystemExit(f"{path}: frontmatter がありません")
    frontmatter = match.group(1)
    fields = dict(re.findall(r"^(name|description):\s*(.+)$", frontmatter, re.M))
    if not fields.get("name") or not fields.get("description"):
        raise SystemExit(f"{path}: name/description がありません")
    skill_names.append(fields["name"])

if len(skill_names) != len(set(skill_names)):
    raise SystemExit(f"Skill名が重複しています: {skill_names}")

harness_review = root / "skills/harness-review"
if "harness-review" not in skill_names:
    raise SystemExit("harness-review Skill がありません")
openai_yaml = harness_review / "agents/openai.yaml"
if not openai_yaml.is_file():
    raise SystemExit("harness-review/agents/openai.yaml がありません")
openai_yaml_text = openai_yaml.read_text(encoding="utf-8")
for required in (
    "display_name:",
    "short_description:",
    "default_prompt:",
    "allow_implicit_invocation: false",
    "$harness-review",
):
    if required not in openai_yaml_text:
        raise SystemExit(f"harness-review/agents/openai.yaml に {required} がありません")

doc_storage = (root / "skills/doc-storage/SKILL.md").read_text(encoding="utf-8")
for required in (
    "## ハーネスへの示唆",
    "### 効かなかった指示",
    "### hook / rules の拒否・摩擦",
    "### advisor / reviewer の判断",
    "### 運用指標",
):
    if required not in doc_storage:
        raise SystemExit(f"doc-storage Skill に {required} がありません")

agent_catalog = (root / "agents/README.md").read_text(encoding="utf-8")
catalog_rows = re.findall(r"^\| `([^`]+)` \| `([^`]+)` \| `([^`]+)` \| `([^`]+)` \|", agent_catalog, re.M)
if len(catalog_rows) != len(set(row[0] for row in catalog_rows)):
    raise SystemExit("agents/README.mdのAgent名が重複しています")
expected_rows = {}
for path in agent_files:
    with path.open("rb") as fh:
        data = tomllib.load(fh)
    expected_rows[data["name"]] = (data["model"], data["model_reasoning_effort"], data["sandbox_mode"])
actual_rows = {name: (model, effort, sandbox) for name, model, effort, sandbox in catalog_rows}
if actual_rows != expected_rows:
    missing = sorted(set(expected_rows) - set(actual_rows))
    stale = sorted(set(actual_rows) - set(expected_rows))
    mismatched = sorted(name for name in set(expected_rows) & set(actual_rows) if expected_rows[name] != actual_rows[name])
    raise SystemExit(f"agents/README.mdの設定一覧がTOMLと一致しません: missing={missing} stale={stale} mismatched={mismatched}")

readme = (root / "README.md").read_text(encoding="utf-8")
if "[agents/README.md](agents/README.md)" not in readme:
    raise SystemExit("README.mdからagents/README.mdへのリンクがありません")
scenario_requirements = {
    "局所的な変更": ("局所的・可逆な変更", "必須にしない"),
    "通常の複数箇所変更": ("通常の複数箇所機能", "完成物レビュー"),
    "高リスク変更": ("DB移行・API互換性・認証変更", "rollback"),
    "検証不能": ("検証環境が不足", "完了扱いにしない"),
    "レビュー後再検証": ("レビュー後に修正", "再実行"),
    "再開": ("別モデル・別セッションで再開", "残作業"),
}
for label, required_phrases in scenario_requirements.items():
    for phrase in required_phrases:
        if phrase not in readme:
            raise SystemExit(f"README.mdのシナリオ {label} に {phrase} がありません")

feature = (root / "skills/feature/SKILL.md").read_text(encoding="utf-8")
for required in ("code-reviewer", "advisor", "senior-advisor", "修正後に影響する検証を再実行"):
    if required not in feature:
        raise SystemExit(f"feature Skill に {required} の契約がありません")
agents_text = (root / "AGENTS.md").read_text(encoding="utf-8")
for required in ("成功", "失敗", "未実行", "対象外", "$feature", "$spec"):
    if required not in agents_text:
        raise SystemExit(f"AGENTS.md に {required} の契約がありません")

references = {
    "AGENTS.md": [
        root / "skills/feature/SKILL.md",
        root / "skills/spec/SKILL.md",
        root / "skills/plan-review/SKILL.md",
        root / "skills/doc/SKILL.md",
        root / "skills/doc-storage/SKILL.md",
        root / "skills/harness-review/SKILL.md",
        root / "agents/code-reviewer.toml",
        root / "agents/advisor.toml",
        root / "agents/senior-advisor.toml",
        root / "agents/README.md",
    ],
    "skills/feature/SKILL.md": [
        root / "skills/spec/SKILL.md",
        root / "skills/doc/SKILL.md",
        root / "agents/plan-reviewer.toml",
        root / "agents/code-reviewer.toml",
        root / "agents/advisor.toml",
        root / "agents/senior-advisor.toml",
    ],
    "skills/spec/SKILL.md": [root / "skills/feature/SKILL.md", root / "skills/doc-storage/SKILL.md"],
    "skills/doc/SKILL.md": [root / "skills/doc-storage/SKILL.md"],
    "agents/doc-writer.toml": [root / "skills/doc-storage/SKILL.md"],
    "skills/harness-review/SKILL.md": [
        root / "skills/doc-storage/SKILL.md",
        root / "scripts/verify-harness.sh",
    ],
}
for source, targets in references.items():
    for target in targets:
        if not target.exists():
            raise SystemExit(f"{source} が参照する {target.relative_to(root)} がありません")
print(f"agents={len(agent_files)} skills={len(skill_names)}")
PY

printf '%s\n' '[3/4] isolated install'
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/my-codex-harness.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT
mkdir -p "$TMP_ROOT/home/.codex" "$TMP_ROOT/home/.agents/skills"
printf '%s\n' 'existing settings' > "$TMP_ROOT/home/.codex/AGENTS.md"
printf '%s\n' 'existing agent' > "$TMP_ROOT/home/.codex/agents-placeholder"
HOME="$TMP_ROOT/home" CODEX_HOME="$TMP_ROOT/home/.codex" bash "$ROOT/install.sh" >/dev/null

require_symlink "$TMP_ROOT/home/.codex/AGENTS.md"
for agent in "$ROOT"/agents/*.toml; do
  require_symlink "$TMP_ROOT/home/.codex/agents/$(basename "$agent")"
done
for skill in "$ROOT"/skills/*; do
  [[ -d "$skill" ]] || continue
  require_symlink "$TMP_ROOT/home/.agents/skills/$(basename "$skill")"
done
backup_files=("$TMP_ROOT/home/.codex"/AGENTS.md.bak.*)
[[ ${#backup_files[@]} -gt 0 ]] || fail "既存AGENTS.mdの退避ファイルがありません: $TMP_ROOT/home/.codex"
[[ -f "${backup_files[0]}" ]] || fail "AGENTS.mdの退避先が通常ファイルではありません: ${backup_files[0]}"
[[ "$(<"${backup_files[0]}")" == 'existing settings' ]] || fail "既存AGENTS.mdの内容が退避されていません"
[[ "$(readlink "$TMP_ROOT/home/.codex/AGENTS.md")" == "$ROOT/AGENTS.md" ]] || fail "AGENTS.mdのリンク先が不正です"

HOME="$TMP_ROOT/home" CODEX_HOME="$TMP_ROOT/home/.codex" bash "$ROOT/install.sh" >/dev/null
require_symlink "$TMP_ROOT/home/.codex/AGENTS.md"
for agent in "$ROOT"/agents/*.toml; do
  link="$TMP_ROOT/home/.codex/agents/$(basename "$agent")"
  require_symlink "$link"
  [[ "$(readlink "$link")" == "$agent" ]] || fail "Agentのリンク先が不正です: $link"
done
for skill in "$ROOT"/skills/*; do
  [[ -d "$skill" ]] || continue
  link="$TMP_ROOT/home/.agents/skills/$(basename "$skill")"
  require_symlink "$link"
  [[ "$(readlink "$link")" == "$skill" ]] || fail "Skillのリンク先が不正です: $link"
done

printf '%s\n' '[4/4] diff hygiene'
git -C "$ROOT" diff --check
printf '%s\n' 'ハーネス検証に成功しました。'
