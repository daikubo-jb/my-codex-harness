---
name: doc
description: 直近の作業をdoc-storageに記録する。話題や要約を明示されたときに使う。
---

渡された話題をもとに、直近の作業を `$doc-storage` に記録する。

`doc-writer` に次の情報を要約して渡す。

- 何を・なぜ・どう変えたか（2〜5行）
- 関連するプランやレビュー結果のパス
- 記録先の種別（plans / reviews / research / decisions）

要約はメインエージェントが書く。doc-writerに差分から推測させない。
