#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
英単語データセット バッチ別 精密クレンジング＆修正エンジン
=============================================================================
"""

import csv
import json
import os
import re
import sys
import nltk

sys.stdout.reconfigure(encoding='utf-8')

# CMUDict読み込み
try:
    cmu = nltk.corpus.cmudict.dict()
except Exception:
    nltk.download('cmudict', quiet=True)
    cmu = nltk.corpus.cmudict.dict()

# CMU to IPA マッピング
cmu_to_ipa = {
    'AA': 'ɑː', 'AE': 'æ', 'AH0': 'ə', 'AH1': 'ʌ', 'AH2': 'ʌ',
    'AO': 'ɔː', 'AW': 'aʊ', 'AY': 'aɪ', 'B': 'b', 'CH': 'tʃ',
    'D': 'd', 'DH': 'ð', 'EH': 'e', 'ER0': 'ɚ', 'ER1': 'ɜːr', 'ER2': 'ɜːr',
    'EY': 'eɪ', 'F': 'f', 'G': 'ɡ', 'HH': 'h', 'IH': 'ɪ',
    'IY': 'iː', 'JH': 'dʒ', 'K': 'k', 'L': 'l', 'M': 'm',
    'N': 'n', 'NG': 'ŋ', 'OW': 'oʊ', 'OY': 'ɔɪ', 'P': 'p',
    'R': 'r', 'S': 's', 'SH': 'ʃ', 'T': 't', 'TH': 'θ',
    'UH': 'ʊ', 'UW': 'uː', 'V': 'v', 'W': 'w', 'Y': 'j',
    'Z': 'z', 'ZH': 'ʒ'
}

def get_clean_ipa(word: str) -> str:
    phones = cmu.get(word.lower())
    if not phones:
        return None
    p_list = phones[0]
    res = []
    for p in p_list:
        stress = ''
        if '1' in p: stress = 'ˈ'
        elif '2' in p: stress = 'ˌ'
        base_p = p.rstrip('012')
        val = cmu_to_ipa.get(p, cmu_to_ipa.get(base_p, base_p.lower()))
        if stress:
            res.append(stress + val)
        else:
            res.append(val)
    return '/' + ''.join(res) + '/'

# 精査済みの高品質単語マスター辞書（不整合の完全修正用）
CURATED_FIXES = {
    'more': {
        'Japanese': 'もっと、より多くの',
        'phonetic': '/mɔːr/',
        'category': 'Daily',
        'Example': 'I need more time to finish the work.',
        'Example_JP': '仕事を終わらせるためにもっと時間が必要です。'
    },
    'us': {
        'Japanese': '私たちを、私たちに',
        'phonetic': '/ʌs/',
        'category': 'Daily',
        'Example': 'She gave us a warm welcome.',
        'Example_JP': '彼女は私たちを温かく歓迎してくれた。'
    },
    'can': {
        'Japanese': '〜できる、缶',
        'phonetic': '/kæn/',
        'category': 'Daily',
        'Example': 'I can speak English and Japanese.',
        'Example_JP': '私は英語と日本語を話すことができます。'
    },
    'will': {
        'Japanese': '〜だろう、意志',
        'phonetic': '/wɪl/',
        'category': 'Daily',
        'Example': 'I will call you tomorrow morning.',
        'Example_JP': '明日の朝あなたに電話します。'
    },
    'like': {
        'Japanese': '好き、〜のような',
        'phonetic': '/laɪk/',
        'category': 'Daily',
        'Example': 'I like listening to classical music.',
        'Example_JP': '私はクラシック音楽を聴くのが好きです。'
    },
    'out': {
        'Japanese': '外へ、外に、外出して',
        'phonetic': '/aʊt/',
        'category': 'Daily',
        'Example': 'Let us go out for lunch together.',
        'Example_JP': '一緒にお昼ご飯を食べに外へ行きましょう。'
    },
    'see': {
        'Japanese': '見る、会う、わかる',
        'phonetic': '/siː/',
        'category': 'Daily',
        'Example': 'I can see the ocean from my window.',
        'Example_JP': '窓から海が見えます。'
    },
    'make': {
        'Japanese': '作る、〜にする',
        'phonetic': '/meɪk/',
        'category': 'Daily',
        'Example': 'She wants to make a fresh salad.',
        'Example_JP': '彼女は新鮮なサラダを作りたいと思っています。'
    },
    'say': {
        'Japanese': '言う、述べる',
        'phonetic': '/seɪ/',
        'category': 'Daily',
        'Example': 'What did you say to the teacher?',
        'Example_JP': '先生に何と言ったのですか？'
    },
    'life': {
        'Japanese': '人生、生活、命',
        'phonetic': '/laɪf/',
        'category': 'Daily',
        'Example': 'He enjoys a healthy and active life.',
        'Example_JP': '彼は健康的で活動的な生活を楽しんでいます。'
    },
    'down': {
        'Japanese': '下へ、下に、落ちて',
        'phonetic': '/daʊn/',
        'category': 'Daily',
        'Example': 'Please sit down on this comfortable sofa.',
        'Example_JP': 'この心地よいソファにお座りください。'
    },
    'lot': {
        'Japanese': 'たくさん、多くのこと',
        'phonetic': '/lɑːt/',
        'category': 'Daily',
        'Example': 'Thank you a lot for your kind help.',
        'Example_JP': 'ご親切に手伝っていただき、本当にありがとうございます。'
    },
    'night': {
        'Japanese': '夜、晩',
        'phonetic': '/naɪt/',
        'category': 'Daily',
        'Example': 'The stars look so beautiful tonight.',
        'Example_JP': '今夜は星がとても美しく見えます。'
    },
    'order': {
        'Japanese': '注文、順番、命令',
        'phonetic': '/ˈɔːrdɚ/',
        'category': 'Business',
        'Example': 'Are you ready to order your food?',
        'Example_JP': 'お料理のご注文はお決まりですか？'
    },
    'put': {
        'Japanese': '置く、入れる',
        'phonetic': '/pʊt/',
        'category': 'Daily',
        'Example': 'Please put the keys on the counter.',
        'Example_JP': '鍵をカウンターの上に置いてください。'
    },
    'go': {
        'Japanese': '行く、進む',
        'phonetic': '/ɡoʊ/',
        'category': 'Daily',
        'Example': 'I go to school by bicycle every day.',
        'Example_JP': '私は毎日自転車で学校へ行きます。'
    },
    'drink': {
        'Japanese': '飲む、飲み物',
        'phonetic': '/drɪŋk/',
        'category': 'Daily',
        'Example': 'I always drink a glass of water after waking up.',
        'Example_JP': '私は起きた後にいつもコップ1杯の水を飲みます。'
    },
    'beverage': {
        'Japanese': '飲み物、飲料',
        'phonetic': '/ˈbevɚɪdʒ/',
        'category': 'Daily',
        'Example': 'They serve a wide variety of cold beverages.',
        'Example_JP': '彼らは多種多様な冷たい飲み物を提供しています。'
    },
    'orchard': {
        'Japanese': '果樹園',
        'phonetic': '/ˈɔːrtʃɚd/',
        'category': 'Nature',
        'Example': 'They picked fresh apples at the local orchard.',
        'Example_JP': '彼らは地元の果樹園で新鮮なリンゴを収穫しました。'
    },
    'year': {
        'Japanese': '年、1年',
        'phonetic': '/jɪr/',
        'category': 'Daily',
        'Example': 'We traveled abroad twice this year.',
        'Example_JP': '私たちは今年2回海外旅行をしました。'
    },
    'house': {
        'Japanese': '家、住宅',
        'phonetic': '/haʊs/',
        'category': 'Daily',
        'Example': 'They bought a beautiful house near the park.',
        'Example_JP': '彼らは公園の近くに美しい家を買いました。'
    },
    'use': {
        'Japanese': '使う、使用する',
        'phonetic': '/juːz/',
        'category': 'General',
        'Example': 'You can use my laptop whenever you want.',
        'Example_JP': 'いつでも好きな時に私のノートパソコンを使っていいですよ。'
    },
    'white': {
        'Japanese': '白い、白色',
        'phonetic': '/waɪt/',
        'category': 'Daily',
        'Example': 'She wore a lovely white dress to the party.',
        'Example_JP': '彼女はパーティーに素敵な白いドレスを着ていきました。'
    },
    'let': {
        'Japanese': '〜させる、〜しよう',
        'phonetic': '/let/',
        'category': 'Daily',
        'Example': 'Please let me know your final decision.',
        'Example_JP': 'あなたの最終的な決定を私に教えてください。'
    }
}

def clean_dataset(input_csv: str, output_csv: str, audit_csv: str, start_row: int = 1, end_row: int = None):
    with open(input_csv, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        all_rows = list(reader)

    total_len = len(all_rows)
    end_row = end_row or total_len

    print(f"=== 単語データセット クレンジング開始 ===")
    print(f"対象範囲: 行 {start_row} 〜 {end_row} (全 {end_row - start_row + 1} 件)")

    audit_logs = []
    modified_count = 0

    for i in range(start_row - 1, end_row):
        row = all_rows[i]
        w = row['word'].strip()
        w_lower = w.lower()
        orig_row = dict(row)
        modified = False
        reasons = []

        # 1. 精査済みマスター辞書による完全一致修正
        if w_lower in CURATED_FIXES:
            fix = CURATED_FIXES[w_lower]
            for k, v in fix.items():
                if row[k] != v:
                    row[k] = v
                    modified = True
            reasons.append("精査マスター辞書による完全整合化")

        # 2. 屈折形IPAの原形化（末尾 /z/, /s/, /ks/, /ts/ などの誤り修正）
        if not w_lower.endswith(('s', 'ss', 'x', 'ch', 'sh')) and row['phonetic'].endswith(('z/', 's/', 'ts/', 'ks/', 'dz/')):
            cmu_ipa = get_clean_ipa(w_lower)
            if cmu_ipa and cmu_ipa != row['phonetic']:
                row['phonetic'] = cmu_ipa
                modified = True
                reasons.append("屈折IPAの原形化")

        # 3. 例文中に単語が存在しない場合の例文修正（3人称単数形や複数形を原形に自然変換）
        if not re.search(r'\b' + re.escape(w_lower) + r'\b', row['Example'], re.IGNORECASE):
            # 例: "She likes to read books." で word="like" の場合 -> "I like to read books."
            # "She makes cookies." で word="make" -> "They make cookies."
            # "He goes to school." で word="go" -> "I go to school."
            ex = row['Example']
            ex_jp = row['Example_JP']

            # パターン置換
            if re.search(r'\b' + re.escape(w_lower) + r's\b', ex, re.IGNORECASE):
                # 3人称単数 / 複数形の置換
                ex_new = re.sub(r'\bShe ' + re.escape(w_lower) + r's\b', f'I {w_lower}', ex, flags=re.IGNORECASE)
                ex_new = re.sub(r'\bHe ' + re.escape(w_lower) + r's\b', f'I {w_lower}', ex_new, flags=re.IGNORECASE)
                ex_new = re.sub(r'\b' + re.escape(w_lower) + r's\b', w_lower, ex_new, flags=re.IGNORECASE)
                
                if ex_new != ex:
                    row['Example'] = ex_new
                    # 日本語訳も主語調整
                    ex_jp_new = ex_jp.replace('彼女は', '私は').replace('彼は', '私は')
                    row['Example_JP'] = ex_jp_new
                    modified = True
                    reasons.append("例文の原形主語整合化")

        if modified:
            modified_count += 1
            audit_logs.append({
                'row_id': i + 1,
                'word': w,
                'orig_CEFR': orig_row['CEFR'],
                'new_CEFR': row['CEFR'],
                'orig_JP': orig_row['Japanese'],
                'new_JP': row['Japanese'],
                'orig_IPA': orig_row['phonetic'],
                'new_IPA': row['phonetic'],
                'orig_Ex': orig_row['Example'],
                'new_Ex': row['Example'],
                'orig_Ex_JP': orig_row['Example_JP'],
                'new_Ex_JP': row['Example_JP'],
                'reasons': ' / '.join(reasons)
            })

    print(f"\n[処理完了] 修正件数: {modified_count} 件")

    # 出力ファイル書き込み
    with open(output_csv, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=all_rows[0].keys())
        writer.writeheader()
        writer.writerows(all_rows)

    # 監査ログ書き込み
    if audit_logs:
        with open(audit_csv, 'w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=audit_logs[0].keys())
            writer.writeheader()
            writer.writerows(audit_logs)

    print(f"クレンジング済みCSV: {output_csv}")
    print(f"監査ログCSV: {audit_csv}")
    return modified_count, audit_logs

if __name__ == '__main__':
    clean_dataset(
        input_csv='assets/words.csv',
        output_csv='assets/words_cleaned.csv',
        audit_csv='tools/cleaning_audit_log.csv',
        start_row=1,
        end_row=31130
    )
