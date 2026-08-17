# 📘 英単語学習アプリ システム要件定義書（詳細決定版）

## 1. 全体概要・システム要件

### 1.1 全体概要

本アプリは、ゲームの爽快感（2レーン落下式アクション）と科学的な記憶定着アルゴリズム（エビングハウスの忘却曲線モデル）を融合させた英単語学習アプリです。
直感的なクイズゲームによるアウトプットと、単語帳でのスワイプ/長押し操作によるインプット・手動メンテ、そして毎日の連続プレイ（ストリーク）をトリガーとしたコレクター要素（スタンプ図鑑）により、学習の習慣化と高効率な記憶定着を実現します。

### 1.2 システム要件

* **対応プラットフォーム**: Windows (Desktop), Web, iOS, Android (Flutterクロスプラットフォーム)
* **開発言語 / フレームワーク**: Dart / Flutter
* **ローカルデータベース**: Drift (SQLite)
* **音声・効果音機能**: FlutterTts (TTS再生) / AudioPlayers (SE再生)
* **開発ポリシー**:
* CSVパース処理等は外部パッケージ（`csv`パッケージ等）に依存せず、Dart標準機能（正規表現・手動パース）のみで実装する。
* コード提示時は必ず管理番号（例: `VER-20260817-xxx`）を発番・提示する。
* クイズ機能は「2レーン落下式アクションゲーム」に一本化し、スタンダードな1問1答形式は採用しない。



---

## 2. 機能一覧と詳細仕様

### 2.1 機能一覧表

| 機能ID | 機能名 | 概要 | ステータス |
| --- | --- | --- | --- |
| **F-01** | ローカルDB基盤 | SQLite(Drift)による単語・履歴・スタンプ・学習記録データの保存 | **一部実装済み** (要拡張) |
| **F-02** | 2レーンクイズ基本処理 | 左右2レーン同時落下＆4択選択肢、正誤判定、コンボ・スコア計算 | **実装済み** |
| **F-03** | モード選択機能 | チャレンジモード（1分/100問）と学習モード（章別未達成出題）の選択 | 未実装 |
| **F-04** | 回答スピード＆3分割判定 | 落下画面を縦に3分割判定し、回答位置（上/中/下）に応じた加点・ペナルティ判定 | 未実装 |
| **F-05** | 定着度・忘却曲線ロジック | 0〜100ptの定着度管理、当日上限（70pt）制限、日付差分による自動減算処理 | 未実装 |
| **F-06** | 単語の章分け＆粘着ヘッダー | 各レベル内100単語ごとの章分け、単語帳でのスクロール時固定ヘッダー表示 | 未実装 |
| **F-07** | 単語帳（和訳OFF/長押し） | 和訳表示ON/OFF切替、長押しでの和訳表示・音声(TTS)再生 | 未実装 |
| **F-08** | 単語帳スワイプ操作 | 右スワイプ（暗記済みON）、左スワイプ（暗記済みOFF＆定着度0ptリセット＋当日上限70pt） | 未実装 |
| **F-09** | 暗記フラグ更新機能 | 忘却曲線で80pt未満に下がった「暗記済み」単語のフラグを一括解除するメンテボタン | 未実装 |
| **F-10** | カレンダー＆連続日数 | 日別暗記達成数表示、連続プレイ日数（ストリーク）カウント | 未実装 |
| **F-11** | 条件付きランダムスタンプ | プレイ後に押印される日替わりスタンプ（連続日数や暗記数などの条件付きランダム抽選） | 未実装 |
| **F-12** | スタンプ図鑑 | 獲得済み/未獲得スタンプの一覧、未獲得スタンプの出現条件ヒント表示 | 未実装 |

---

### 2.2 詳細アルゴリズム・ルール仕様

#### 🧠 ① 定着度ポイント（retention_rate）と当日上限制限（daily_limit_flag）

1. **ポイント範囲**: `0.0` 〜 `100.0` pt（初期値: 0.0 pt）
2. **暗記済み判定**: `retention_rate >= 80.0` で `is_memorized = true` と自動設定。手動解除がない限り保持。
3. **ゲーム完走時の一括反映**:
* 途中中断・キャンセル時はポイント変動なし。
* 1プレイ中に同単語が再出題された場合、**最初の1回目の解答結果のみ**をポイント変動対象とする。


4. **回答判定ゾーンと加算/減算ルール**:
* 🟢 **上部 1/3 ゾーン正解（スピード回答）**: `+50 pt`
* 🔵 **中部 2/3 ゾーン正解（通常回答）**: `+30 pt`
* 🟡 **下部 3/3 ゾーン正解（迷い回答）**: `+20 pt` ＋ 【当日上限 70pt 制限付与】
* 🔴 **誤答 / タイムオーバー**: `-30 pt` ＋ 【当日上限 70pt 制限付与】（下限 0pt）
* **ポイント反映計算**: $\text{次回定着度} = \min(\text{現在の定着度} + \text{加算pt}, \text{当日の上限値})$
* ※当日上限（70pt）が付与されている場合は、加算後も最大70ptで頭打ち。




5. **当日上限のリセット**: 日付更新（0:00跨ぎ）時に `daily_limit_flag` が自動解除され、100ptまで獲得可能になる。

#### 📉 ② 忘却曲線ロジック（エビングハウス忘却モデル）

* アプリ起動時または画面描画時に、最終解答日時（`last_answered_at`）からの経過日数（$\text{delta\_days}$）と累計正答回数（$\text{correct\_count}$）を用いて一括減算処理を適用する。

$$\text{次回定着度} = \text{現在の定着度} \times \left( 1 - \frac{\text{経過日数}}{\text{経過日数} + 2 + (\text{正解回数} \times 2)} \right)$$



#### 🎮 ③ ゲームモード別出題ルール

1. **チャレンジモード（アーケード系）**:
* 制限時間: 1分間 / 出題数: 100問連続出題。
* 対象: 選択レベル（初級・中級・上級・全単語）の全単語からランダム。


2. **学習モード（ステップアップ系）**:
* 章選択（例: 初級 第2章）。
* 出題対象: 「`is_memorized == false`（未暗記）」かつ「`retention_rate < 70`（当日の上限未到達）」の単語のみ。
* 章クリア判定: その章の出題対象単語が0件になった時点で「第X章クリア🎉」を表示。



#### 📖 ④ 単語帳の拡張スワイプ＆長押し仕様

1. **和訳表示ON/OFFスイッチ**: OFF時は日本語訳をマスク処理。
2. **長押し（Press & Hold）**: 長押し中のみ和訳表示 ＋ 英語TTS発音を再生。
3. **右スワイプ**: `is_memorized = true`（暗記済みON）に設定。（定着度は現状維持または80ptへ繰り上げ）
4. **左スワイプ**: `is_memorized = false`（暗記済みOFF） / `retention_rate = 0.0`（0ptリセット） / 当日上限70pt制限付与。
5. **「暗記フラグ更新（メンテ）」ボタン**:
* 忘却曲線減算により `is_memorized == true` でありながら `retention_rate < 80.0` に低下した単語を一括検出し、`is_memorized = false` へ自動更新して復習対象に戻す。



#### 🎨 ⑤ スタンプ抽選＆図鑑ルール

1. **抽選ロジック**: ゲームプレイ後、その日満たしている「出現条件（連続プレイ日数・当日暗記単語数など）」に適合するスタンプ候補グループ（ガチャ箱）の中からランダムで1つを当選・カレンダーに押印。
2. **図鑑機能**: 未獲得スタンプはロック状態で表示し、「💡 出現条件: 連続プレイ7日以上で出現候補に追加！」などのヒントを表示する。

---

## 3. テーブル定義

### 3.1 `words` (単語マスター＆定着度テーブル)

| カラム名 (物理) | 型 | 制約 | 説明 |
| --- | --- | --- | --- |
| `id` | INTEGER | PRIMARY KEY, AUTOINCREMENT | 単語ID |
| `english` | TEXT | NOT NULL | 英単語 |
| `japanese` | TEXT | NOT NULL | 日本語訳 |
| `phonetic` | TEXT | NULL | 発音記号 |
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

## 5. 次のステップと開発手順のご案内

要件定義書の詳細が完璧に整理されました！

これに基づき、ここからの実装手順は以下のステップで進めることを推奨いたします：

1. **Step 1: Drift データベース基盤の拡張 (`lib/db/app_database.dart`)**
* 上記の全テーブル（`words` への `retention_rate` や `daily_limit_flag` 等のカラム追加、`stamps`, `daily_records`, `system_settings` の新規定義）をコードに反映します。
* ※このステップでは `build_runner` を使用したビルドが必要になります。


2. **Step 2: 定着度・忘却曲線計算サービス (`retention_service.dart`) の構築**
* 回答位置（3分割ゾーン）に応じた加減算、およびアプリ起動時の忘却曲線一括計算ロジックを実装します。


3. **Step 3: 2レーンゲーム画面 (`game_screen.dart`) の判定・モード対応強化**
4. **Step 4: 単語帳画面のUI強化（粘着ヘッダー / スワイプ / 和訳OFF / メンテボタン）**

準備が整いましたら、まずは **「Step 1: データベース（Drift）拡張コード」** から提示・作成を開始いたします。「DB拡張から進めて！」とお知らせください！