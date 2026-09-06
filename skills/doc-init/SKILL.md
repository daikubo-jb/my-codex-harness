---
name: doc-init
description: 現在のプロジェクト用のドキュメント枠をdoc-storageに作成する。対象外のプロジェクトでは作成しない。
---

現在の作業ディレクトリのbasenameをプロジェクト名として、`$doc-storage` の規約どおりに次の構造を作る。

```text
index.md
codex-doc/{plans,reviews,research,worklog,decisions}/
human-doc/
```

既存のディレクトリは作り直さない。`index.md` が無ければ、プロジェクトのREADMEとAGENTS.mdを読んで1〜2文の概要と空のリンク節を置く。対象外のプロジェクトでは作成せず、その理由を報告する。作成したパスを報告する。
