# カスタムAgent一覧

このディレクトリのTOMLが、Codexで利用するカスタムAgentの定義です。モデル名、推論強度、sandboxは各TOMLを正とし、この一覧は設定を確認するための入口として使います。変更時は`bash scripts/verify-harness.sh`で一覧との整合を確認します。

| Agent | Model | 推論強度 | Sandbox | 役割 |
| --- | --- | --- | --- | --- |
| `advisor` | `gpt-5.6` | `high` | `read-only` | 難しい局所判断のsecond opinionを返す |
| `code-reviewer` | `gpt-5.6` | `high` | `read-only` | 完成した差分を読み取り専用でレビューする |
| `doc-writer` | `gpt-5.6-luna` | `low` | `workspace-write` | doc-storageへ作業記録を保存する |
| `plan-reviewer` | `gpt-5.6` | `high` | `read-only` | 実装計画の前提と要件漏れを批評する |
| `senior-advisor` | `gpt-6-astra` | `medium` | `read-only` | 高影響なアーキテクチャ判断のsecond opinionを返す |
| `test-runner` | `gpt-5.6-terra` | `high` | `workspace-write` | 必要なテスト・検証と失敗の切り分けを行う |

通常の作業はメインAgentが担当します。これらのAgentは、変更の規模、リスク、独立した検証の必要性に応じて使います。`workspace-write`はAgent定義上のsandboxであり、プロンプトによる書き込み範囲の説明だけで完全なファイル単位の権限制御にはなりません。
