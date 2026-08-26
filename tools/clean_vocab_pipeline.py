#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
英単語データセット 高品質自動クレンジング＆不整合修正パイプライン
=============================================================================
【目的】
約3万件の英単語データ（assets/words.csv 等）において、
単語の品詞・日本語訳・例文・例文訳・発音記号（IPA）・CEFRレベルの不整合
（例: 'more'が'mores'の意になっている、名詞訳に動詞例文がついている等）を
Gemini等のLLM APIを用いて自動検出し、高品質かつ自然なデータに修正・更新します。

【主な特徴】
1. バッチ処理（デフォルト50件単位）による高速・低コスト処理
2. レジューム機能（中断してもチェックポイントから自動再開、重複課金防止）
3. 指数バックオフ＆レートリミット（429）自動リトライ機構
4. 修正前後の差分を監査ログ（CSV）として詳細記録
5. ドライラン（--dry-run）による事前品質確認対応
6. 外部SDK不要（標準ライブラリ + requests のみで即座に動作）
=============================================================================
"""

import os
import sys
import csv
import json
import time
import argparse
import logging
from dataclasses import dataclass, asdict
from typing import List, Dict, Any, Optional
import urllib.request
import urllib.error

# ログ設定
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S"
)
logger = logging.getLogger("VocabCleaner")


@dataclass
class WordRow:
    row_id: int
    word: str
    CEFR: str
    Japanese: str
    phonetic: str
    category: str
    Example: str
    Example_JP: str

    def to_dict(self) -> Dict[str, Any]:
        return {
            "word": self.word,
            "CEFR": self.CEFR,
            "Japanese": self.Japanese,
            "phonetic": self.phonetic,
            "category": self.category,
            "Example": self.Example,
            "Example_JP": self.Example_JP,
        }


class CheckpointManager:
    """進捗と中断・再開（レジューム）を管理するクラス"""

    def __init__(self, checkpoint_path: str, output_csv_path: str, audit_csv_path: str):
        self.checkpoint_path = checkpoint_path
        self.output_csv_path = output_csv_path
        self.audit_csv_path = audit_csv_path
        self.processed_ids = set()
        self.last_processed_index = 0
        self.total_modified = 0
        self._load_checkpoint()

    def _load_checkpoint(self):
        if os.path.exists(self.checkpoint_path):
            try:
                with open(self.checkpoint_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    self.last_processed_index = data.get("last_processed_index", 0)
                    self.processed_ids = set(data.get("processed_ids", []))
                    self.total_modified = data.get("total_modified", 0)
                logger.info(
                    f"チェックポイントを検出: インデックス {self.last_processed_index} から再開します "
                    f"(処理済: {len(self.processed_ids)}件, 修正済: {self.total_modified}件)"
                )
            except Exception as e:
                logger.warning(f"チェックポイントの読み込みに失敗したため新規開始します: {e}")

    def save_checkpoint(self, last_index: int, new_processed_ids: List[int], modified_count_delta: int):
        self.last_processed_index = last_index
        self.processed_ids.update(new_processed_ids)
        self.total_modified += modified_count_delta

        temp_path = self.checkpoint_path + ".tmp"
        with open(temp_path, "w", encoding="utf-8") as f:
            json.dump({
                "last_processed_index": self.last_processed_index,
                "processed_ids": list(self.processed_ids),
                "total_modified": self.total_modified,
                "updated_at": time.strftime("%Y-%m-%d %H:%M:%S"),
            }, f, ensure_ascii=False, indent=2)
        os.replace(temp_path, self.checkpoint_path)

    def append_cleaned_rows(self, rows: List[WordRow], is_first_write: bool = False):
        mode = "w" if (is_first_write and not os.path.exists(self.output_csv_path)) else "a"
        file_exists = os.path.exists(self.output_csv_path) and os.path.getsize(self.output_csv_path) > 0

        with open(self.output_csv_path, mode, encoding="utf-8", newline="") as f:
            writer = csv.DictWriter(
                f,
                fieldnames=["word", "CEFR", "Japanese", "phonetic", "category", "Example", "Example_JP"],
                quoting=csv.QUOTE_MINIMAL
            )
            if not file_exists or (is_first_write and mode == "w"):
                writer.writeheader()
            for r in rows:
                writer.writerow(r.to_dict())

    def append_audit_logs(self, audit_entries: List[Dict[str, Any]]):
        if not audit_entries:
            return
        file_exists = os.path.exists(self.audit_csv_path) and os.path.getsize(self.audit_csv_path) > 0
        with open(self.audit_csv_path, "a", encoding="utf-8", newline="") as f:
            writer = csv.DictWriter(
                f,
                fieldnames=[
                    "row_id", "word", "original_CEFR", "new_CEFR",
                    "original_Japanese", "new_Japanese",
                    "original_phonetic", "new_phonetic",
                    "original_category", "new_category",
                    "original_Example", "new_Example",
                    "original_Example_JP", "new_Example_JP",
                    "reason"
                ],
                quoting=csv.QUOTE_MINIMAL
            )
            if not file_exists:
                writer.writeheader()
            for entry in audit_entries:
                writer.writerow(entry)


class GeminiBatchCleaner:
    """Gemini API を直接呼び出してバッチで不整合を判定・修正するクライアント"""

    def __init__(self, api_key: str, model: str = "gemini-2.5-flash", timeout: int = 60):
        self.api_key = api_key
        self.model = model
        self.timeout = timeout
        self.url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent?key={self.api_key}"

    def clean_batch(self, batch: List[WordRow], max_retries: int = 5) -> List[Dict[str, Any]]:
        """1バッチ（50〜100語）をプロンプトに送り、修正結果のJSONリストを受け取る"""
        system_instruction = (
            "あなたは英語教育および辞書編纂の最高峰エキスパートです。\n"
            "与えられた英単語データリストを1件ずつ厳密に検証し、意味・品詞・例文・例文訳・発音記号・CEFRレベルの不整合を修正してください。\n\n"
            "【重要な修正ルール】\n"
            "1. 単語（word）の意味・品詞と例文（Example）の使われ方が100%一致しているか確認すること。\n"
            "   - 例: 単語が 'drink (飲み物 [名])' なのに例文が 'He drinks water (彼は水を飲む [動])' と動詞で使われている場合は、名詞用例文 'She ordered a cold drink.' または意味に合わせた適切な例文に修正する。\n"
            "   - 例: 'more' が 'mores (社会規範)' と混同されている場合は、A1の最重要語 'もっと、より多くの' /mɔːr/ に修正する。\n"
            "   - 例: 'us' が 'uses (使用する)' と混同されている場合は、代名詞 '私たちを、私たちに' /ʌs/ に修正する。\n"
            "   - 例: 'can' が 'cans (缶)' になっている場合は、適切な意味・発音・例文に整える。\n"
            "2. 発音記号（phonetic）は、複数形や三人称単数の発音（/s/, /z/, /ɪz/）が誤って残っている場合、原形の正確なIPA（例: /mɔːr/, /ʌs/）に修正すること。\n"
            "3. 例文（Example）は、自然で平易な日常英語（当該CEFRレベルに合致）とし、Example_JPはその直訳・自然な日本語訳とすること。\n"
            "4. カテゴリ（category）は 'Daily', 'Business', 'Academic', 'Nature', 'Culture', 'Technology', 'Health', 'General' の8種から最適なものを選択すること。\n"
            "5. データが既に完全に正確で自然な場合は、無理に変更せず \"modified\": false とすること。\n"
            "6. 出力は必ず指定されたJSONフォーマットのみを返すこと。"
        )

        items_payload = []
        for row in batch:
            items_payload.append({
                "row_id": row.row_id,
                "word": row.word,
                "CEFR": row.CEFR,
                "Japanese": row.Japanese,
                "phonetic": row.phonetic,
                "category": row.category,
                "Example": row.Example,
                "Example_JP": row.Example_JP,
            })

        user_content = (
            "以下の英単語データリストを検査し、不整合を修正した結果をJSON形式で返してください。\n\n"
            "```json\n"
            + json.dumps(items_payload, ensure_ascii=False, indent=2)
            + "\n```\n\n"
            "返却JSONの形式:\n"
            "{\n"
            '  "results": [\n'
            "    {\n"
            '      "row_id": 1,\n'
            '      "word": "one",\n'
            '      "CEFR": "A1",\n'
            '      "Japanese": "1",\n'
            '      "phonetic": "/ˈwʌn/",\n'
            '      "category": "Daily",\n'
            '      "Example": "I have one brother.",\n'
            '      "Example_JP": "私には1人の兄弟がいる。",\n'
            '      "modified": false,\n'
            '      "reason": ""\n'
            "    },\n"
            "    ...\n"
            "  ]\n"
            "}"
        )

        request_data = {
            "contents": [
                {
                    "parts": [
                        {"text": system_instruction + "\n\n" + user_content}
                    ]
                }
            ],
            "generationConfig": {
                "responseMimeType": "application/json",
                "temperature": 0.1,
            }
        }

        # 指数バックオフ付きリトライループ
        delay = 2.0
        for attempt in range(1, max_retries + 1):
            try:
                json_bytes = json.dumps(request_data).encode("utf-8")
                req = urllib.request.Request(
                    self.url,
                    data=json_bytes,
                    headers={"Content-Type": "application/json"}
                )
                with urllib.request.urlopen(req, timeout=self.timeout) as response:
                    res_body = response.read().decode("utf-8")
                    res_json = json.loads(res_body)
                    
                    candidate_text = res_json["candidates"][0]["content"]["parts"][0]["text"]
                    parsed = json.loads(candidate_text)
                    if "results" in parsed and isinstance(parsed["results"], list):
                        return parsed["results"]
                    elif isinstance(parsed, list):
                        return parsed
                    else:
                        raise ValueError(f"予期しないJSON構造: {candidate_text[:200]}")

            except urllib.error.HTTPError as e:
                error_body = e.read().decode("utf-8") if e.fp else ""
                status_code = e.code
                logger.warning(f"[試行 {attempt}/{max_retries}] HTTPエラー {status_code}: {error_body[:150]}")
                if status_code == 429:
                    # レートリミット時は長めに待機
                    sleep_time = delay * 2 + 5.0
                    logger.info(f"レート制限(429)を検知。{sleep_time:.1f}秒間待機してリトライします...")
                    time.sleep(sleep_time)
                else:
                    time.sleep(delay)
                delay *= 1.5

            except Exception as e:
                logger.warning(f"[試行 {attempt}/{max_retries}] エラー発生: {e}")
                time.sleep(delay)
                delay *= 1.5

        raise RuntimeError(f"バッチ処理が {max_retries} 回の試行後も失敗しました。")


def run_pipeline(args):
    # APIキーの検証
    api_key = args.api_key or os.environ.get("GEMINI_API_KEY")
    if not api_key:
        logger.error(
            "Gemini APIキーが設定されていません。\n"
            "引数 `--api-key YOUR_KEY` を渡すか、環境変数 `GEMINI_API_KEY` を設定してください。"
        )
        sys.exit(1)

    if not os.path.exists(args.input):
        logger.error(f"入力ファイルが見つかりません: {args.input}")
        sys.exit(1)

    # 入力CSVの読み込み
    logger.info(f"入力ファイルを読み込み中: {args.input}")
    all_rows: List[WordRow] = []
    with open(args.input, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for i, row in enumerate(reader, start=1):
            all_rows.append(WordRow(
                row_id=i,
                word=row.get("word", "").strip(),
                CEFR=row.get("CEFR", "A1").strip(),
                Japanese=row.get("Japanese", "").strip(),
                phonetic=row.get("phonetic", "").strip(),
                category=row.get("category", "General").strip(),
                Example=row.get("Example", "").strip(),
                Example_JP=row.get("Example_JP", "").strip(),
            ))

    total_count = len(all_rows)
    logger.info(f"総単語数: {total_count} 件")

    # チェックポイント管理の初期化
    checkpoint_mgr = CheckpointManager(
        checkpoint_path=args.checkpoint,
        output_csv_path=args.output,
        audit_csv_path=args.audit_log,
    )

    # 処理対象行の抽出（未処理のもののみ）
    if args.dry_run:
        target_rows = all_rows[:min(args.dry_run_count, total_count)]
        logger.info(f"【ドライランモード】先頭 {len(target_rows)} 件のみを検証実行します（出力ファイルは更新されません）")
    else:
        target_rows = [r for r in all_rows if r.row_id not in checkpoint_mgr.processed_ids]
        if args.limit and args.limit > 0:
            target_rows = target_rows[:args.limit]
        logger.info(f"今回の処理対象: {len(target_rows)} 件 (スキップ済: {total_count - len(target_rows)} 件)")

    if not target_rows:
        logger.info("全単語のクレンジングが既に完了しています！")
        return

    cleaner = GeminiBatchCleaner(api_key=api_key, model=args.model, timeout=args.timeout)
    batch_size = args.batch_size

    total_batches = (len(target_rows) + batch_size - 1) // batch_size
    start_time = time.time()
    session_modified_count = 0

    try:
        for b_idx in range(total_batches):
            batch = target_rows[b_idx * batch_size : (b_idx + 1) * batch_size]
            b_num = b_idx + 1
            logger.info(
                f"[バッチ {b_num}/{total_batches}] 行 {batch[0].row_id}〜{batch[-1].row_id} ({len(batch)}件) を処理中..."
            )

            results = cleaner.clean_batch(batch)
            result_map = {item["row_id"]: item for item in results if "row_id" in item}

            cleaned_batch_rows: List[WordRow] = []
            audit_entries: List[Dict[str, Any]] = []
            modified_in_batch = 0

            for original in batch:
                cleaned_data = result_map.get(original.row_id)
                if cleaned_data and cleaned_data.get("modified", False):
                    # 修正あり
                    modified_in_batch += 1
                    session_modified_count += 1
                    new_row = WordRow(
                        row_id=original.row_id,
                        word=cleaned_data.get("word", original.word),
                        CEFR=cleaned_data.get("CEFR", original.CEFR),
                        Japanese=cleaned_data.get("Japanese", original.Japanese),
                        phonetic=cleaned_data.get("phonetic", original.phonetic),
                        category=cleaned_data.get("category", original.category),
                        Example=cleaned_data.get("Example", original.Example),
                        Example_JP=cleaned_data.get("Example_JP", original.Example_JP),
                    )
                    cleaned_batch_rows.append(new_row)

                    audit_entries.append({
                        "row_id": original.row_id,
                        "word": original.word,
                        "original_CEFR": original.CEFR,
                        "new_CEFR": new_row.CEFR,
                        "original_Japanese": original.Japanese,
                        "new_Japanese": new_row.Japanese,
                        "original_phonetic": original.phonetic,
                        "new_phonetic": new_row.phonetic,
                        "original_category": original.category,
                        "new_category": new_row.category,
                        "original_Example": original.Example,
                        "new_Example": new_row.Example,
                        "original_Example_JP": original.Example_JP,
                        "new_Example_JP": new_row.Example_JP,
                        "reason": cleaned_data.get("reason", "自動整合性修正"),
                    })

                    if args.dry_run:
                        logger.info(
                            f"  [修正検知] {original.word} ({original.CEFR})\n"
                            f"    旧訳: {original.Japanese} | 新訳: {new_row.Japanese}\n"
                            f"    旧音: {original.phonetic} | 新音: {new_row.phonetic}\n"
                            f"    旧例: {original.Example} ({original.Example_JP})\n"
                            f"    新例: {new_row.Example} ({new_row.Example_JP})\n"
                            f"    理由: {cleaned_data.get('reason', '')}\n"
                        )
                else:
                    # 変更なし（そのまま維持）
                    cleaned_batch_rows.append(original)

            if not args.dry_run:
                # 差分ログ追記
                checkpoint_mgr.append_audit_logs(audit_entries)
                # クレンジング済みCSV追記
                checkpoint_mgr.append_cleaned_rows(cleaned_batch_rows)
                # チェックポイント保存
                processed_ids = [r.row_id for r in batch]
                checkpoint_mgr.save_checkpoint(
                    last_index=batch[-1].row_id,
                    new_processed_ids=processed_ids,
                    modified_count_delta=modified_in_batch
                )

            logger.info(
                f"[バッチ {b_num}/{total_batches} 完了] 修正: {modified_in_batch}件 / 合計修正: {checkpoint_mgr.total_modified + (session_modified_count if args.dry_run else 0)}件"
            )

            # API負荷調整インターバル（0.5秒）
            time.sleep(0.5)

    except KeyboardInterrupt:
        logger.info("\nユーザーにより中断されました。進捗はチェックポイントに正常保存されています。")
    finally:
        elapsed = time.time() - start_time
        logger.info("=" * 60)
        logger.info("【パイプライン実行サマリー】")
        logger.info(f"・処理時間: {elapsed:.1f} 秒")
        logger.info(f"・セッション内修正件数: {session_modified_count} 件")
        if not args.dry_run:
            logger.info(f"・累計修正件数: {checkpoint_mgr.total_modified} 件")
            logger.info(f"・出力ファイル: {args.output}")
            logger.info(f"・監査ログ: {args.audit_log}")
            logger.info(f"・チェックポイント: {args.checkpoint}")
        logger.info("=" * 60)


def main():
    parser = argparse.ArgumentParser(description="英単語データセット 自動クレンジング＆不整合修正パイプライン")
    parser.add_argument("--input", default="assets/words.csv", help="入力CSVファイルパス (デフォルト: assets/words.csv)")
    parser.add_argument("--output", default="assets/words_cleaned.csv", help="出力クレンジング済みCSVファイルパス (デフォルト: assets/words_cleaned.csv)")
    parser.add_argument("--checkpoint", default="tools/clean_checkpoint.json", help="チェックポイントJSONファイルパス")
    parser.add_argument("--audit-log", default="tools/cleaning_audit_log.csv", help="修正監査ログCSVファイルパス")
    parser.add_argument("--batch-size", type=int, default=50, help="1バッチあたりの単語数 (デフォルト: 50)")
    parser.add_argument("--api-key", default=None, help="Gemini APIキー (未指定時は環境変数 GEMINI_API_KEY を使用)")
    parser.add_argument("--model", default="gemini-2.5-flash", help="使用するモデル名 (デフォルト: gemini-2.5-flash)")
    parser.add_argument("--limit", type=int, default=0, help="処理する最大件数 (0で全件処理)")
    parser.add_argument("--dry-run", action="store_true", help="ドライランモード（ファイル書き込みを行わず動作確認のみ実施）")
    parser.add_argument("--dry-run-count", type=int, default=20, help="ドライラン時に処理する件数 (デフォルト: 20)")
    parser.add_argument("--timeout", type=int, default=60, help="APIタイムアウト秒数 (デフォルト: 60)")

    args = parser.parse_args()
    run_pipeline(args)


if __name__ == "__main__":
    main()
