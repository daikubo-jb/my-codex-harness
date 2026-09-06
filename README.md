# my-codex-harness

Codexで日常の開発作業を進めるための個人用設定一式。リポジトリをマスターとして管理し、`install.sh` でグローバルなCodex設定とSkillsへシンボリックリンクを張る。

## 方針

- 探索 → 計画 → レビュー → 実装 → 検証 → 記録の順に進める
- 恒久的な共通ルールは `AGENTS.md` に置く
- 実装はメインエージェントが担当する
- テスト、プランレビュー、ドキュメント記録は専門エージェントに委譲する
- 変更の少ない依頼にはワークフローを強制しない
- 既存のプロジェクト慣習と検証手順を優先する

## 構成

```text
AGENTS.md     Codexのグローバル共通ルール
agents/       カスタムサブエージェントのTOML定義
skills/       Codex Skills
install.sh    個人環境へシンボリックリンクを張る
```

このディレクトリがマスターで、インストール先はリンクです。ここを編集すれば、次のCodexセッションから反映されます。

## 導入

まず `skills/doc-storage/SKILL.md` の `DOC_STORAGE_ROOT` を自分の環境に合わせて変更し、doc-storageのディレクトリを作る。その後、次を実行する。

```sh
cd ~/p-dev/my-codex-harness
./install.sh
```

インストール先は次のとおり。

- 共通指示: `${CODEX_HOME:-~/.codex}/AGENTS.md`
- カスタムエージェント: `${CODEX_HOME:-~/.codex}/agents/`
- ユーザーSkills: `~/.agents/skills/`

既存の同名ファイルは削除せず、`.bak.<日時>` に退避してからリンクする。ハーネスを移動した場合は `./install.sh` を再実行する。

## 使い方

Codexで次のようにSkillsを呼び出す。

```text
$spec 通知機能を作りたい
$feature Google OAuthのログインを追加する
$plan-review
$doc 今回の設計判断
$doc-init
```

小さな変更はSkillを使わず、ファイルと完了条件を直接依頼する。複数ファイルにまたがる変更は `$feature`、仕様が固まっていない大きな依頼は `$spec` から始める。

プロジェクトごとのビルド・テスト手順は、そのプロジェクトの `AGENTS.md`、`CLAUDE.md`、または `.agents/skills/run-*` に従う。

## ドキュメント

デフォルトでは `<DOC_STORAGE_ROOT>/<project>/codex-doc/` に保存する。リポジトリ内でドキュメントを管理するプロジェクトでは、この仕組みを使わず既存の慣習に従う。
