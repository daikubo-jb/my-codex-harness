---
name: doc-storage
description: プロジェクトドキュメントの配置規約と保管場所。ドキュメントを作成・更新・検索するとき、doc-writer を使うとき、過去の設計判断や調査結果を探すときに読む。
---

# doc-storage 配置規約

プロジェクトドキュメントはリポジトリ内で管理する慣習がない場合、1箇所に集約する。READMEやAPIドキュメントなど、リポジトリに同梱すべきものは対象外とする。

## 配置ルート

導入時にこの1行だけ自分の環境に合わせて変更する。

```text
DOC_STORAGE_ROOT=~/dev/doc-storage
```

以降この値を `<root>` と書く。他のファイルはパスを直接書かず、`$doc-storage` を参照する。

## 構成

```text
<root>/<プロジェクト名>/
├── index.md
├── codex-doc/
│   ├── plans/
│   ├── reviews/
│   ├── research/
│   ├── worklog/
│   └── decisions/
└── human-doc/
```

`<プロジェクト名>` は作業ディレクトリのbasenameとする。

リポジトリ内でドキュメントを管理する慣習のプロジェクトでは枠を作らず、そのプロジェクトの `AGENTS.md` や既存の慣習に従う。

`codex-doc/` 以下は作成・更新してよい。`human-doc/` は読むだけで、明示的に指示された時だけ書き込む。

ファイル名は `plans/`, `reviews/`, `research/` では `YYYY-MM-DD-<slug>.md`、`decisions/` では `NNNN-<slug>.md` とする。各ファイルにはfrontmatter、タイトル、1〜2文の要約を置く。新規作成時は `index.md` に `[[ファイル名]]` を追加する。

長時間・高リスク・引き継ぎが必要な作業では、対象リポジトリ、ブランチ/コミット、未コミット変更、目的、完了条件、スコープ外、決定事項と根拠、実施済み作業、検証コマンドと結果、未解決事項、次の具体的な操作を記録する。検証結果は成功・失敗・未実行・対象外を区別する。小変更の記録は必須にしない。

worklogには末尾に次の固定欄を置く。該当する事象が無い場合も各欄に「なし」と書き、欄自体は省略しない。内容は観測事実に限定し、ハーネスの変更案は`$harness-review`で判断する。

```markdown
## ハーネスへの示唆

### 効かなかった指示
- rule:
- event:
- outcome:
- resolution:

### hook / rules の拒否・摩擦
- rule:
- event:
- outcome: blocked | friction | escaped
- resolution:

### advisor / reviewer の判断
- role:
- finding:
- decision: accepted | rejected | deferred
- reason:

### 運用指標
- review_findings:
- repeated_incidents:
- retry_count:
- gate_friction:
- duration_or_usage:
```

繰り返し回数だけでrulesやhookへ自動昇格させない。正確な操作を機械的に防げるか、不変条件として検査できるか、手順の抜けか、判断・意図の問題かを分けて記録する。重大な事故は1件でも記録し、影響と再発条件を明記する。

作業を再開するときは、まず現在のブランチと差分を確認して記録と照合する。記録が参照できない、または現在の状態と矛盾する場合は推測で補わず、その状態を報告する。

過去の経緯や設計判断を探すときは、まず該当プロジェクトの `index.md` を読み、そこから辿る。
