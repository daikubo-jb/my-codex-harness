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

過去の経緯や設計判断を探すときは、まず該当プロジェクトの `index.md` を読み、そこから辿る。
