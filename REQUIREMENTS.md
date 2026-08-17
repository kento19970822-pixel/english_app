## 1. 全体概要・システム要件

### 1.1 全体概要

本アプリは、ゲームの楽しさと科学的な記憶定着アルゴリズム（エビングハウスの忘却曲線）を融合させた「2レーン落下式英単語学習アプリ」です。
ユーザーは直感的なクイズゲームを通じて英単語を効率的に暗記し、単語帳での長押し・スワイプ操作による復習や、カレンダー・スタンプコレクション機能によって毎日の学習習慣化を維持することができます。

### 1.2 システム要件

* **対応プラットフォーム**: Windows (Desktop), Web, iOS, Android (Flutterクロスプラットフォーム)
* **開発言語 / フレームワーク**: Dart / Flutter
* **ローカルデータベース**: Drift (SQLite)
* **音声機能**: FlutterTts (将来的にネイティブ音源ファイルへの切り替えが可能な抽象設計)
* **効果音**: AudioPlayers
* **開発ポリシー**:
* CSVパース処理等は外部パッケージ（`csv`パッケージ等）に依存せず、Dart標準機能（正規表現・手動パース）のみで実装する。
* コード提示時は必ず管理番号（例: `VER-20260817-xxx`）を発番・提示する。



---

## 2. 機能一覧と進捗管理

| 機能ID | 機能名 | 概要 | ステータス |
| --- | --- | --- | --- |
| **F-01** | ローカルDB基盤 | SQLite(Drift)による単語・履歴・スタンプデータのローカル保存 | **実装済み** (※要拡張) |
| **F-02** | 2レーンクイズ基本処理 | 左右2レーン同時落下＆4択回答、正誤判定、タイマー処理 | **実装済み** |
| **F-03** | モード選択機能 | チャレンジモード（1分/100問）と学習モード（章別未達成出題）の選択 | 実装予定 |
| **F-04** | 回答スピード＆3分割判定 | 落下画面を縦に3分割（緑・青・黄/赤）し、回答位置に応じた加点・ペナルティ判定 | 実装予定 |
| **F-05** | 定着度・忘却曲線ロジック | 0〜100ptの定着度管理、当日上限（70pt）制限、日付差分による自動減算処理 | 実装予定 |
| **F-06** | 単語の章分け＆粘着ヘッダー | 各レベル内100単語ごとの章分け、単語帳でのスクロール時固定ヘッダー（【初級 第1章 (42/100暗記済)】）表示 | 実装予定 |
| **F-07** | 単語帳（和訳OFF/長押し） | 和訳表示ON/OFF切替、長押しでの和訳・音声(TTS)再生 | 実装予定 |
| **F-08** | 単語帳スワイプ操作 | 右スワイプ（暗記済みON）、左スワイプ（暗記済みOFF＆定着度0ptリセット） | 実装予定 |
| **F-09** | 暗記フラグ更新機能 | 忘却曲線で80pt未満に下がった「暗記済み」単語のフラグを一括解除するメンテボタン | 実装予定 |
| **F-10** | カレンダー＆連続日数 | 日別暗記達成数表示、連続プレイ日数（ストリーク）カウント | 実装予定 |
| **F-11** | 条件付きランダムスタンプ | プレイ後に押印される日替わりスタンプ（連続日数や暗記数などの条件付きランダム抽選） | 実装予定 |
| **F-12** | スタンプ図鑑 | 獲得済み/未獲得スタンプの一覧、未獲得スタンプの出現条件ヒント表示 | 実装予定 |

---

## 3. テーブル定義

### 3.1 `words` (単語マスター＆定着度テーブル)

| カラム名 (物理) | 型 | 制約 | 説明 |
| --- | --- | --- | --- |
| `id` | INTEGER | PRIMARY KEY, AUTOINCREMENT | 単語ID |
| `english` | TEXT | NOT NULL | 英単語 |
| `japanese` | TEXT | NOT NULL | 日本語訳 |
| `cefr` | TEXT | NOT NULL | 難易度区分 (A1, A2, B1, B2, C1, C2) |
| `level` | INTEGER | NOT NULL | レベル (1: 初級, 2: 中級, 3: 上級) |
| `chapter` | INTEGER | NOT NULL | 章番号 (100単語ごとに1, 2, 3...) |
| `is_favorite` | BOOLEAN | NOT NULL DEFAULT FALSE | ★お気に入りフラグ |
| `is_memorized` | BOOLEAN | NOT NULL DEFAULT FALSE | 暗記済みフラグ (80pt以上でON, 手動変更可能) |
| `retention_rate` | REAL | NOT NULL DEFAULT 0.0 | 現在の定着度ポイント (0.0 〜 100.0) |
| `correct_count` | INTEGER | NOT NULL DEFAULT 0 | 累計正答回数 |
| `wrong_count` | INTEGER | NOT NULL DEFAULT 0 | 累計誤答回数 |
| `last_answered_at` | DATETIME | NULL | 最終解答日時 |
| `daily_limit_flag` | BOOLEAN | NOT NULL DEFAULT FALSE | 当日上限(70pt)制限フラグ |
| `last_penalty_date` | DATETIME | NULL | 制限がかかった日付 |

### 3.2 `game_histories` (ゲームプレイ履歴テーブル)

| カラム名 (物理) | 型 | 制約 | 説明 |
| --- | --- | --- | --- |
| `id` | INTEGER | PRIMARY KEY, AUTOINCREMENT | 履歴ID |
| `score` | INTEGER | NOT NULL | 獲得スコア |
| `level` | INTEGER | NOT NULL | 選択レベル (1〜3, 4:全ランダム) |
| `mode` | TEXT | NOT NULL | プレイモード (`challenge` / `learning`) |
| `played_at` | DATETIME | NOT NULL | プレイ日時 |

### 3.3 `stamps` (スタンプマスター＆獲得状態テーブル)

| カラム名 (物理) | 型 | 制約 | 説明 |
| --- | --- | --- | --- |
| `id` | TEXT | PRIMARY KEY | スタンプID (例: `stamp_lion`) |
| `name` | TEXT | NOT NULL | スタンプ名 (例: ライオンスタンプ) |
| `icon_code` | TEXT | NOT NULL | 表示用アイコン識別子 / 画像パス |
| `condition_type` | TEXT | NOT NULL | 出現条件種別 (`none`, `streak`, `daily_memorized`) |
| `condition_value` | INTEGER | NOT NULL DEFAULT 0 | 条件閾値 (例: 連続3日なら `3`) |
| `is_unlocked` | BOOLEAN | NOT NULL DEFAULT FALSE | 獲得（ロック解除）フラグ |
| `unlocked_at` | DATETIME | NULL | 初回獲得日時 |

### 3.4 `daily_records` (日別学習＆ログイン記録テーブル)

| カラム名 (物理) | 型 | 制約 | 説明 |
| --- | --- | --- | --- |
| `date_str` | TEXT | PRIMARY KEY | 日付文字列 (`YYYY-MM-DD`) |
| `memorized_count` | INTEGER | NOT NULL DEFAULT 0 | その日に新しく暗記済みにした単語数 |
| `played_count` | INTEGER | NOT NULL DEFAULT 0 | その日のゲームプレイ回数 |
| `applied_stamp_id` | TEXT | NULL | その日カレンダーに押されたスタンプID |

### 3.5 `system_settings` (アプリ設定＆最終演算日保持テーブル)

| カラム名 (物理) | 型 | 制約 | 説明 |
| --- | --- | --- | --- |
| `key` | TEXT | PRIMARY KEY | 設定キー (`last_retention_calculated_at`, `current_streak`) |
| `value` | TEXT | NOT NULL | 設定値 |

---

## 4. フォルダ構成 (ディレクトリツリー構造)

```text
english_app/
├── assets/                     # 音声・画像・効果音アセット
│   ├── audio/                  # 効果音 (SE) データ
│   └── stamps/                 # スタンプ用イラスト画像
├── lib/
│   ├── main.dart               # アプリケーションエントリーポイント
│   ├── db/                     # データベース (Drift/SQLite) 関連
│   │   ├── app_database.dart   # DB定義・クエリ・Driftテーブル
│   │   └── app_database.g.dart # Drift自動生成コード
│   ├── models/                 # データモデル
│   │   ├── word_model.dart     # 単語モデル
│   │   └── stamp_model.dart    # スタンプモデル
│   ├── services/               # ロジック・計算サービス
│   │   ├── retention_service.dart # 定着度・忘却曲線計算ロジック
│   │   ├── stamp_service.dart     # スタンプ抽選・解放判定ロジック
│   │   └── audio_service.dart     # TTS / SE 再生抽象化サービス
│   ├── screens/                # 各画面UI
│   │   ├── mode_select_screen.dart # モード選択（スタート）画面
│   │   ├── game_screen.dart        # 2レーンクイズゲーム画面
│   │   ├── dictionary_screen.dart  # 粘着ヘッダー＆スワイプ対応単語帳画面
│   │   ├── calendar_screen.dart    # カレンダー＆連続日数画面
│   │   └── stamp_gallery_screen.dart # スタンプ図鑑画面
│   └── widgets/                # 共通UI部品
│       ├── sticky_chapter_header.dart # 100単語ごとの粘着ヘッダー
│       └── word_card_tile.dart        # 長押し・スワイプ対応単語カード
└── pubspec.yaml

```

---

## 5. 本日の作業整理とスタートダッシュ

要件定義書が美しく整理できました！

本日ここからの開発は、全ての基盤となる **「1. データベース（Drift）の拡張定義」** から着手するのが一番スムーズです。

ご準備がよろしければ、「Driftのテーブル定義コード（`lib/db/app_database.dart` の拡張版）」から提示・作成に入ります。

「DBから進めて！」など、お気軽にお声がけください！