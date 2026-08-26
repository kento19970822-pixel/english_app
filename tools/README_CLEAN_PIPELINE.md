# 英単語データセット 高品質自動クレンジング＆不整合修正パイプライン

## 1. 概要
本ツール（`tools/clean_vocab_pipeline.py`）は、アプリ本体から完全に独立したデータ整備専用のPythonスクリプトです。
約31,000件の英単語データ（`assets/words.csv`）において、単語の指定品詞・日本語訳・例文・例文訳・発音記号（IPA）・CEFRレベルの不整合をGemini API（`gemini-2.5-flash`）を用いて自動検出し、高品質かつ自然なデータに修正・更新します。

---

## 2. システム構成と特徴

```mermaid
graph TD
    A[assets/words.csv (約3.1万件)] --> B[Batch Loader (50件/チャンク)]
    B --> C[Gemini API (gemini-2.5-flash)]
    C --> D{不整合判定}
    D -- 正常 (変更なし) --> E[元データをそのまま維持]
    D -- 不整合検知 --> F[新日本語訳・原形IPA・自然な例文/訳に修正]
    E --> G[Checkpoint Manager (レジューム機能)]
    F --> G
    G --> H[assets/words_cleaned.csv (クレンジング済)]
    G --> I[tools/cleaning_audit_log.csv (修正前後ログ)]
    G --> J[tools/clean_checkpoint.json (進捗記録)]
```

### 主な機能
1. **バッチチャンク処理**:
   - 1リクエストあたり50件（調整可能）の単語をJSON構造化プロンプトで一括処理し、高速かつ低コストに実行。
2. **完全レジューム（中断・再開）機能**:
   - 処理完了した行IDを `tools/clean_checkpoint.json` に随時アトミック保存。途中で中断しても未処理の単語から自動再開し、重複課金を防止。
3. **指数バックオフ＆レート制限（429）自動回避**:
   - APIリトライ制御を内蔵し、エラーやレート制限発生時も自動で待機・再試行。
4. **監査ログ（Diff Log）の自動生成**:
   - `tools/cleaning_audit_log.csv` に「修正前後の全カラム・修正理由」を1件ずつ記録し、人間の目でも全変更を検証可能。
5. **ドライラン（`--dry-run`）対応**:
   - 先頭20件等で修正結果をターミナルにプレビュー表示し、品質を事前確認可能。
6. **ゼロ追加依存**:
   - Python標準ライブラリ（`urllib`, `json`, `csv`）のみで動作し、追加パッケージのインストール不要。

---

## 3. 使用方法

### ① APIキーの設定
```bash
# 環境変数に設定する場合
set GEMINI_API_KEY=AIzaSy...
```

### ② ドライラン（動作確認・品質チェック）
```bash
# 先頭20件をテスト実行し、修正プレビューを表示（ファイルは更新されません）
python tools/clean_vocab_pipeline.py --api-key YOUR_API_KEY --dry-run
```

### ③ 全件クレンジング実行
```bash
# 全31,130件の自動修正を実行
python tools/clean_vocab_pipeline.py --api-key YOUR_API_KEY
```

### ④ オプション一覧
| オプション | デフォルト値 | 説明 |
| :--- | :--- | :--- |
| `--input` | `assets/words.csv` | 入力元CSVパス |
| `--output` | `assets/words_cleaned.csv` | 出力先クレンジング済CSVパス |
| `--checkpoint` | `tools/clean_checkpoint.json` | 進捗チェックポイントJSON |
| `--audit-log` | `tools/cleaning_audit_log.csv` | 修正差分ログCSV |
| `--batch-size` | `50` | 1バッチの単語数（50〜100推奨） |
| `--model` | `gemini-2.5-flash` | 使用モデル |
| `--limit` | `0` (全件) | 処理件数の上限（例: `--limit 500`） |
| `--dry-run` | `False` | プレビューのみ実行するフラグ |

---

## 4. クレンジング後のアプリ反映手順

1. 監査ログ（`tools/cleaning_audit_log.csv`）を確認し、修正内容に問題がないことを確認します。
2. クレンジング済みファイル `assets/words_cleaned.csv` を `assets/words.csv` に上書き配置します：
   ```bash
   move /Y assets\words_cleaned.csv assets\words.csv
   ```
3. アプリのDBシード再インポートや単語帳画面で最新データが反映されます。
