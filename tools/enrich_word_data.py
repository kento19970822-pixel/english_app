# -*- coding: utf-8 -*-
"""
tools/enrich_word_data.py

Enriches assets/words.csv with:
1. Standardizing and assigning accurate Part of Speech (partOfSpeech)
2. Generating structured JSON for multiple senses (otherMeanings)
3. Attaching practical high-frequency collocations (collocations)
4. Linking irregular past tense/participle/plural forms to base forms (baseForm)
5. Formatting clean CSV output with all 11 schema columns.
"""

import csv
import json
import os
import re

# Comprehensive curated collocation dictionary for high-frequency English vocabulary
COLLOCATIONS_DICT = {
    "can": [
        {"phrase": "can do", "meaning": "〜できる、能力がある"},
        {"phrase": "can afford to", "meaning": "〜する余裕がある"},
        {"phrase": "can't help ~ing", "meaning": "〜せずにはいられない"},
        {"phrase": "as ~ as one can", "meaning": "できる限り〜"},
        {"phrase": "can't wait to", "meaning": "〜するのが待ちきれない"},
    ],
    "take": [
        {"phrase": "take a break", "meaning": "休憩する"},
        {"phrase": "take care of", "meaning": "〜の世話をする"},
        {"phrase": "take time", "meaning": "時間をかける"},
        {"phrase": "take place", "meaning": "開催される、起こる"},
        {"phrase": "take part in", "meaning": "〜に参加する"},
        {"phrase": "take advantage of", "meaning": "〜を利用する"},
        {"phrase": "take into account", "meaning": "〜を考慮に入れる"},
    ],
    "make": [
        {"phrase": "make a decision", "meaning": "決断する"},
        {"phrase": "make sure", "meaning": "確かめる、必ず〜する"},
        {"phrase": "make sense", "meaning": "意味をなす、理解できる"},
        {"phrase": "make progress", "meaning": "進歩する"},
        {"phrase": "make an effort", "meaning": "努力する"},
        {"phrase": "make a mistake", "meaning": "間違える"},
        {"phrase": "make friends", "meaning": "友達を作る"},
    ],
    "get": [
        {"phrase": "get ready", "meaning": "準備をする"},
        {"phrase": "get along with", "meaning": "〜とうまくやっていく"},
        {"phrase": "get in touch with", "meaning": "〜と連絡を取る"},
        {"phrase": "get used to", "meaning": "〜に慣れる"},
        {"phrase": "get rid of", "meaning": "〜を取り除く"},
        {"phrase": "get better", "meaning": "良くなる、回復する"},
    ],
    "have": [
        {"phrase": "have lunch / dinner", "meaning": "昼食/夕食を食べる"},
        {"phrase": "have a good time", "meaning": "楽しい時間を過ごす"},
        {"phrase": "have trouble doing", "meaning": "〜するのに苦労する"},
        {"phrase": "have an impact on", "meaning": "〜に影響を与える"},
        {"phrase": "have in common", "meaning": "共通点がある"},
    ],
    "do": [
        {"phrase": "do one's best", "meaning": "最善を尽くす"},
        {"phrase": "do business with", "meaning": "〜と取引する"},
        {"phrase": "do harm / good", "meaning": "害/利益をもたらす"},
        {"phrase": "do research", "meaning": "研究・調査を行う"},
        {"phrase": "do without", "meaning": "〜なしですます"},
    ],
    "give": [
        {"phrase": "give up", "meaning": "諦める"},
        {"phrase": "give a presentation", "meaning": "プレゼンを行う"},
        {"phrase": "give advice", "meaning": "アドバイスをする"},
        {"phrase": "give birth to", "meaning": "〜を産む"},
        {"phrase": "give rise to", "meaning": "〜を引き起こす"},
    ],
    "go": [
        {"phrase": "go ahead", "meaning": "先に進む、どうぞ"},
        {"phrase": "go through", "meaning": "〜を経験する、通過する"},
        {"phrase": "go on", "meaning": "続ける、起こる"},
        {"phrase": "go out", "meaning": "外出する"},
        {"phrase": "go wrong", "meaning": "うまくいかなくなる"},
    ],
    "come": [
        {"phrase": "come up with", "meaning": "〜を思いつく"},
        {"phrase": "come across", "meaning": "〜に偶然出会う"},
        {"phrase": "come true", "meaning": "実現する"},
        {"phrase": "come back", "meaning": "戻る"},
        {"phrase": "come to an end", "meaning": "終わりを迎える"},
    ],
    "look": [
        {"phrase": "look forward to", "meaning": "〜を楽しみに待つ"},
        {"phrase": "look for", "meaning": "〜を探す"},
        {"phrase": "look after", "meaning": "〜の世話をする"},
        {"phrase": "look like", "meaning": "〜のように見える"},
        {"phrase": "look up to", "meaning": "〜を尊敬する"},
    ],
    "put": [
        {"phrase": "put on", "meaning": "身につける、着る"},
        {"phrase": "put off", "meaning": "延期する"},
        {"phrase": "put up with", "meaning": "〜を我慢する"},
        {"phrase": "put together", "meaning": "組み立てる、まとめる"},
    ],
    "keep": [
        {"phrase": "keep in mind", "meaning": "心に留めておく"},
        {"phrase": "keep in touch", "meaning": "連絡を取り合う"},
        {"phrase": "keep quiet", "meaning": "静かにしておく"},
        {"phrase": "keep an eye on", "meaning": "〜を見守る、監視する"},
    ],
    "pay": [
        {"phrase": "pay attention to", "meaning": "〜に注意を払う"},
        {"phrase": "pay a visit", "meaning": "訪問する"},
        {"phrase": "pay off", "meaning": "成果を上げる、完済する"},
    ],
    "catch": [
        {"phrase": "catch up with", "meaning": "〜に追いつく"},
        {"phrase": "catch a cold", "meaning": "風邪をひく"},
        {"phrase": "catch sight of", "meaning": "〜を見かける"},
    ],
    "run": [
        {"phrase": "run out of", "meaning": "〜を使い果たす"},
        {"phrase": "run into", "meaning": "〜に偶然出会う"},
        {"phrase": "run a business", "meaning": "事業を経営する"},
    ],
    "depend": [
        {"phrase": "depend on", "meaning": "〜に依存する、〜次第である"},
    ],
    "rely": [
        {"phrase": "rely on", "meaning": "〜を頼りにする"},
    ],
    "focus": [
        {"phrase": "focus on", "meaning": "〜に集中する、焦点を当てる"},
    ],
    "interested": [
        {"phrase": "interested in", "meaning": "〜に興味がある"},
    ],
    "responsible": [
        {"phrase": "responsible for", "meaning": "〜に責任がある"},
    ],
    "similar": [
        {"phrase": "similar to", "meaning": "〜に似ている"},
    ],
    "different": [
        {"phrase": "different from", "meaning": "〜と異なる"},
    ],
    "good": [
        {"phrase": "good at", "meaning": "〜が得意である"},
        {"phrase": "good for", "meaning": "〜に良い"},
    ],
    "bad": [
        {"phrase": "bad at", "meaning": "〜が苦手である"},
    ],
    "afraid": [
        {"phrase": "afraid of", "meaning": "〜を恐れている"},
    ],
    "proud": [
        {"phrase": "proud of", "meaning": "〜を誇りに思う"},
    ],
    "aware": [
        {"phrase": "aware of", "meaning": "〜を認識している"},
    ],
    "participate": [
        {"phrase": "participate in", "meaning": "〜に参加する"},
    ],
    "lead": [
        {"phrase": "lead to", "meaning": "〜につながる、〜を引き起こす"},
    ],
    "result": [
        {"phrase": "result in", "meaning": "〜という結果になる"},
        {"phrase": "result from", "meaning": "〜に起因する"},
    ],
    "deal": [
        {"phrase": "deal with", "meaning": "〜に対処する、〜を扱う"},
    ],
    "agree": [
        {"phrase": "agree with", "meaning": "（人・意見に）賛成する"},
        {"phrase": "agree on", "meaning": "〜について合意する"},
    ],
    "consist": [
        {"phrase": "consist of", "meaning": "〜から成り立つ"},
    ],
    "contribute": [
        {"phrase": "contribute to", "meaning": "〜に貢献する、〜の一因となる"},
    ],
    "apply": [
        {"phrase": "apply for", "meaning": "（仕事・許可などに）申し込む"},
        {"phrase": "apply to", "meaning": "〜に適用される"},
    ],
    "complain": [
        {"phrase": "complain about", "meaning": "〜について不満を言う"},
    ],
    "succeed": [
        {"phrase": "succeed in", "meaning": "〜に成功する"},
    ],
    "suffer": [
        {"phrase": "suffer from", "meaning": "〜で苦しむ、患う"},
    ],
    "base": [
        {"phrase": "based on", "meaning": "〜に基づいている"},
    ],
    "call": [
        {"phrase": "call off", "meaning": "中止する"},
        {"phrase": "call for", "meaning": "〜を求める、必要とする"},
    ],
    "turn": [
        {"phrase": "turn on / off", "meaning": "（電気・機器を）つける / 消す"},
        {"phrase": "turn out to be", "meaning": "〜であることが判明する"},
        {"phrase": "turn down", "meaning": "断る、音量を下げる"},
    ],
    "set": [
        {"phrase": "set up", "meaning": "設立する、設定する"},
        {"phrase": "set off", "meaning": "出発する、引き起こす"},
    ],
    "bring": [
        {"phrase": "bring about", "meaning": "もたらす、引き起こす"},
        {"phrase": "bring up", "meaning": "育てる、話題を持ち出す"},
    ],
    "carry": [
        {"phrase": "carry out", "meaning": "実行する、遂行する"},
        {"phrase": "carry on", "meaning": "続ける"},
    ],
    "find": [
        {"phrase": "find out", "meaning": "見つけ出す、知る"},
    ],
    "break": [
        {"phrase": "break down", "meaning": "故障する、内訳を分ける"},
        {"phrase": "break out", "meaning": "（戦争・火災などが）勃発する"},
        {"phrase": "break through", "meaning": "突破する"},
    ],
}

# Base form (lemma) dictionary for irregular past tense, participles, and plurals
BASE_FORM_DICT = {
    # Irregular verbs
    "went": "go", "gone": "go",
    "came": "come",
    "ran": "run",
    "saw": "see", "seen": "see",
    "did": "do", "done": "do",
    "had": "have",
    "made": "make",
    "took": "take", "taken": "take",
    "gave": "give", "given": "give",
    "knew": "know", "known": "know",
    "thought": "think",
    "got": "get", "gotten": "get",
    "felt": "feel",
    "left": "leave",
    "told": "tell",
    "said": "say",
    "found": "find",
    "brought": "bring",
    "bought": "buy",
    "built": "build",
    "written": "write", "wrote": "write",
    "spoken": "speak", "spoke": "speak",
    "eaten": "eat", "ate": "eat",
    "drank": "drink", "drunk": "drink",
    "broken": "break", "broke": "break",
    "chosen": "choose", "chose": "choose",
    "driven": "drive", "drove": "drive",
    "fallen": "fall", "fell": "fall",
    "forgotten": "forget", "forgot": "forget",
    "grown": "grow", "grew": "grow",
    "hidden": "hide", "hid": "hide",
    "held": "hold",
    "kept": "keep",
    "led": "lead",
    "lost": "lose",
    "met": "meet",
    "paid": "pay",
    "ridden": "ride", "rode": "ride",
    "rung": "ring", "rang": "ring",
    "risen": "rise", "rose": "rise",
    "sent": "send",
    "shaken": "shake", "shook": "shake",
    "shown": "show",
    "shut": "shut",
    "sung": "sing", "sang": "sing",
    "sat": "sit",
    "slept": "sleep",
    "spent": "spend",
    "stood": "stand",
    "swung": "swing",
    "swam": "swim", "swum": "swim",
    "taught": "teach",
    "torn": "tear", "tore": "tear",
    "thrown": "throw", "threw": "throw",
    "understood": "understand",
    "woken": "wake", "woke": "wake",
    "worn": "wear", "wore": "wear",
    "won": "win",
    "became": "become",
    "began": "begin", "begun": "begin",
    "bit": "bite", "bitten": "bite",
    "blew": "blow", "blown": "blow",
    "caught": "catch",
    "drew": "draw", "drawn": "draw",
    "flew": "fly", "flown": "fly",
    "heard": "hear",
    "hung": "hang",
    "hurt": "hurt",
    "laid": "lay",
    "meant": "mean",
    "read": "read",
    "sold": "sell",
    "set": "set",
    "shone": "shine",
    "shot": "shoot",
    "sold": "sell",
    "struck": "strike",
    "swept": "sweep",
    "swore": "swear", "sworn": "swear",

    # Irregular plurals
    "children": "child",
    "men": "man",
    "women": "woman",
    "feet": "foot",
    "teeth": "tooth",
    "mice": "mouse",
    "people": "person",
    "geese": "goose",
    "oxen": "ox",
    "criteria": "criterion",
    "phenomena": "phenomenon",
    "analyses": "analysis",
    "bases": "basis",
    "crises": "crisis",
    "hypotheses": "hypothesis",

    # Irregular comparatives / superlatives
    "better": "good", "best": "good",
    "worse": "bad", "worst": "bad",
    "more": "much", "most": "much",
    "less": "little", "least": "little",
    "further": "far", "furthest": "far",
    "farther": "far", "farthest": "far",
    "elder": "old", "eldest": "old",
}

# Special core words with curated multi-senses
CURATED_SENSES_DICT = {
    "can": [
        {"sense_id": 1, "part_of_speech": "auxiliary", "meaning_ja": "〜できる、〜してもよい", "example_en": "I can speak English.", "example_ja": "私は英語を話すことができます。"},
        {"sense_id": 2, "part_of_speech": "noun", "meaning_ja": "缶、缶詰", "example_en": "Open a can of soup.", "example_ja": "スープの缶を開ける。"},
    ],
    "will": [
        {"sense_id": 1, "part_of_speech": "auxiliary", "meaning_ja": "〜だろう、〜するつもりだ", "example_en": "I will call you tomorrow.", "example_ja": "明日電話します。"},
        {"sense_id": 2, "part_of_speech": "noun", "meaning_ja": "意志、遺言", "example_en": "She has a strong will.", "example_ja": "彼女は強い意志を持っている。"},
    ],
    "like": [
        {"sense_id": 1, "part_of_speech": "verb", "meaning_ja": "好む、好きである", "example_en": "I like music.", "example_ja": "私は音楽が好きです。"},
        {"sense_id": 2, "part_of_speech": "preposition", "meaning_ja": "〜のような、〜のように", "example_en": "He looks like his father.", "example_ja": "彼はお父さんに似ている。"},
    ],
    "well": [
        {"sense_id": 1, "part_of_speech": "adverb", "meaning_ja": "上手に、十分に", "example_en": "She sings very well.", "example_ja": "彼女はとても上手に歌う。"},
        {"sense_id": 2, "part_of_speech": "adjective", "meaning_ja": "健康な、良好な", "example_en": "I am feeling well today.", "example_ja": "今日は気分が良いです。"},
        {"sense_id": 3, "part_of_speech": "noun", "meaning_ja": "井戸", "example_en": "Draw water from a well.", "example_ja": "井戸から水を汲む。"},
    ],
    "right": [
        {"sense_id": 1, "part_of_speech": "adjective", "meaning_ja": "正しい、右の", "example_en": "That is the right answer.", "example_ja": "それが正しい答えです。"},
        {"sense_id": 2, "part_of_speech": "noun", "meaning_ja": "権利、右側", "example_en": "Everyone has the right to learn.", "example_ja": "誰にでも学ぶ権利がある。"},
        {"sense_id": 3, "part_of_speech": "adverb", "meaning_ja": "ちょうど、右へ", "example_en": "Turn right at the corner.", "example_ja": "角を右に曲がってください。"},
    ],
    "light": [
        {"sense_id": 1, "part_of_speech": "noun", "meaning_ja": "光、明かり", "example_en": "Turn on the light.", "example_ja": "明かりをつけてください。"},
        {"sense_id": 2, "part_of_speech": "adjective", "meaning_ja": "明るい、軽い", "example_en": "This bag is very light.", "example_ja": "このカバンはとても軽い。"},
        {"sense_id": 3, "part_of_speech": "verb", "meaning_ja": "照らす、火をつける", "example_en": "Light a candle.", "example_ja": "ろうそくに火をつける。"},
    ],
    "book": [
        {"sense_id": 1, "part_of_speech": "noun", "meaning_ja": "本、書籍", "example_en": "I am reading a book.", "example_ja": "私は本を読んでいます。"},
        {"sense_id": 2, "part_of_speech": "verb", "meaning_ja": "予約する", "example_en": "Book a table for two.", "example_ja": "2人席を予約する。"},
    ],
    "park": [
        {"sense_id": 1, "part_of_speech": "noun", "meaning_ja": "公園", "example_en": "Let's walk in the park.", "example_ja": "公園を散歩しよう。"},
        {"sense_id": 2, "part_of_speech": "verb", "meaning_ja": "駐車する", "example_en": "Park the car here.", "example_ja": "ここに車を停めてください。"},
    ],
    "order": [
        {"sense_id": 1, "part_of_speech": "noun", "meaning_ja": "順序、秩序、注文", "example_en": "In alphabetical order.", "example_ja": "アルファベット順に。"},
        {"sense_id": 2, "part_of_speech": "verb", "meaning_ja": "注文する、命じる", "example_en": "Order food online.", "example_ja": "オンラインで食事を注文する。"},
    ],
    "present": [
        {"sense_id": 1, "part_of_speech": "noun", "meaning_ja": "プレゼント、現在", "example_en": "A birthday present.", "example_ja": "誕生日プレゼント。"},
        {"sense_id": 2, "part_of_speech": "adjective", "meaning_ja": "出席している、現在の", "example_en": "The present situation.", "example_ja": "現在の状況。"},
        {"sense_id": 3, "part_of_speech": "verb", "meaning_ja": "提示する、贈呈する", "example_en": "Present the report.", "example_ja": "レポートを発表する。"},
    ],
    "fine": [
        {"sense_id": 1, "part_of_speech": "adjective", "meaning_ja": "元気な、素晴らしい、細かい", "example_en": "I am doing fine.", "example_ja": "元気にやっています。"},
        {"sense_id": 2, "part_of_speech": "noun", "meaning_ja": "罰金", "example_en": "Pay a parking fine.", "example_ja": "駐車違反の罰金を払う。"},
    ],
    "watch": [
        {"sense_id": 1, "part_of_speech": "verb", "meaning_ja": "見る、見守る", "example_en": "Watch a movie.", "example_ja": "映画を見る。"},
        {"sense_id": 2, "part_of_speech": "noun", "meaning_ja": "腕時計", "example_en": "Look at your watch.", "example_ja": "腕時計を見る。"},
    ],
    "close": [
        {"sense_id": 1, "part_of_speech": "verb", "meaning_ja": "閉じる、閉まる", "example_en": "Close the window.", "example_ja": "窓を閉めてください。"},
        {"sense_id": 2, "part_of_speech": "adjective", "meaning_ja": "近い、親しい", "example_en": "A close friend.", "example_ja": "親しい友人。"},
    ],
    "lead": [
        {"sense_id": 1, "part_of_speech": "verb", "meaning_ja": "導く、案内する、先頭に立つ", "example_en": "Lead the team to victory.", "example_ja": "チームを勝利に導く。"},
        {"sense_id": 2, "part_of_speech": "noun", "meaning_ja": "鉛（なまり）", "example_en": "A heavy lead pipe.", "example_ja": "重い鉛のパイプ。"},
    ],
    "out": [
        {"sense_id": 1, "part_of_speech": "adverb", "meaning_ja": "外へ、外に、外出して", "example_en": "Let us go out for lunch.", "example_ja": "お昼ご飯を食べに外へ行きましょう。"},
        {"sense_id": 2, "part_of_speech": "preposition", "meaning_ja": "〜の外へ", "example_en": "Walk out the door.", "example_ja": "ドアから外へ出る。"},
    ],
    "up": [
        {"sense_id": 1, "part_of_speech": "adverb", "meaning_ja": "上へ、上がって", "example_en": "Look up at the sky.", "example_ja": "空を見上げる。"},
        {"sense_id": 2, "part_of_speech": "preposition", "meaning_ja": "〜を登って、〜の上に", "example_en": "Climb up the hill.", "example_ja": "丘を登る。"},
    ],
    "down": [
        {"sense_id": 1, "part_of_speech": "adverb", "meaning_ja": "下へ、下がって", "example_en": "Sit down, please.", "example_ja": "座ってください。"},
        {"sense_id": 2, "part_of_speech": "preposition", "meaning_ja": "〜を下って", "example_en": "Walk down the street.", "example_ja": "通りを歩き下る。"},
    ],
}

PRONOUNS_SET = {
    "i", "you", "he", "she", "it", "we", "they",
    "me", "him", "her", "us", "them",
    "my", "your", "his", "our", "their",
    "mine", "yours", "ours", "theirs",
    "this", "that", "these", "those",
    "who", "whom", "whose", "which", "what",
    "someone", "everyone", "nobody", "anyone",
    "something", "everything", "nothing", "anything",
    "myself", "yourself", "himself", "herself", "itself", "ourselves", "themselves",
}

CONJUNCTIONS_SET = {
    "and", "but", "or", "so", "because", "although", "though", "while",
    "if", "unless", "since", "until", "whether", "whereas", "nor",
}

PREPOSITIONS_SET = {
    "in", "on", "at", "to", "for", "with", "by", "from", "of", "about",
    "into", "through", "after", "before", "under", "above", "between",
    "among", "behind", "without", "during", "toward", "towards", "against",
    "across", "along", "around", "over", "near", "beside", "upon",
}

ADVERBS_SET = {
    "out", "up", "down", "off", "away", "back", "here", "there",
    "now", "then", "always", "often", "usually", "sometimes", "never",
    "already", "soon", "again", "too", "very", "also", "even", "just",
    "only", "still", "yet", "almost", "together", "enough", "quite",
    "nearly", "hardly", "seldom", "rarely", "suddenly", "actually",
    "probably", "maybe", "perhaps", "certainly", "definitely", "especially",
    "really", "deeply", "clearly", "simply", "quickly", "slowly",
}

AUXILIARIES_SET = {
    "can", "could", "will", "would", "shall", "should", "may", "might", "must",
}

def detect_part_of_speech(japanese_def: str, english_word: str = "") -> str:
    """Accurately detects part of speech from the Japanese definition and English pattern."""
    w = english_word.strip().lower()
    if w in CURATED_SENSES_DICT:
        return CURATED_SENSES_DICT[w][0]["part_of_speech"]
    if w in PRONOUNS_SET:
        return "pronoun"
    if w in CONJUNCTIONS_SET:
        return "conjunction"
    if w in PREPOSITIONS_SET:
        return "preposition"
    if w in AUXILIARIES_SET:
        return "auxiliary"
    if w in ADVERBS_SET:
        return "adverb"

    if not japanese_def:
        return "noun"

    first_def = re.split(r"[、,]", japanese_def)[0].strip()

    # Verbs: 〜する, 〜させる, 〜できる, 〜ている, or Japanese verb endings (る, く, す, つ, ぬ, ぶ, む, う, ぐ)
    if first_def.startswith("〜する") or first_def.endswith("する") or first_def.endswith("させる") or first_def.endswith("できる") or first_def.endswith("行う") or first_def.endswith("なる") or first_def.endswith("ている") or first_def.endswith("てある"):
        return "verb"
    if re.search(r"[うくすつぬふむゆるぐずづぶぷ]$", first_def) and not first_def.endswith("という") and not first_def.endswith("よう"):
        # Exclude typical nouns ending in u-sounds if they don't look like verbs
        if not re.search(r"(理由|方法|様子|俳優|学校|自由|宇宙|今日|昨日|明日|牛乳|道具|人物|物語|歴史|世界|情報|友人|家族|会社|仕事)$", first_def):
            return "verb"

    # Adjectives: 〜い, 〜な, 〜的, 〜の
    if first_def.endswith("い") and not first_def.endswith("使い") and not first_def.endswith("誓い"):
        return "adjective"
    if first_def.endswith("な") or first_def.endswith("的") or first_def.endswith("らしい") or first_def.endswith("っぽい") or first_def.endswith("の"):
        return "adjective"

    # Adverbs: 〜に, 〜く, 〜して, もっと, さらに, とても
    if first_def.endswith("に") or first_def.endswith("く") or first_def.startswith("とても") or first_def.startswith("さらに") or first_def.startswith("もっと"):
        return "adverb"

    # Prepositions: 〜へ, 〜で, 〜から, 〜まで
    if first_def.startswith("〜") and (first_def.endswith("へ") or first_def.endswith("で") or first_def.endswith("から") or first_def.endswith("まで") or first_def.endswith("について")):
        return "preposition"

    # Default to noun
    return "noun"


def enrich_word(row: dict) -> dict:
    """Enriches a single CSV row with part of speech, collocations, other meanings JSON, and baseForm."""
    word = row.get("word", "").strip().lower()
    japanese = row.get("Japanese", "").strip()
    cefr = row.get("CEFR", "A1").strip()
    phonetic = row.get("phonetic", "").strip()
    category = row.get("category", "General").strip()
    example = row.get("Example", "").strip()
    example_jp = row.get("Example_JP", "").strip()

    # 1. Part of Speech
    if word in CURATED_SENSES_DICT:
        pos = CURATED_SENSES_DICT[word][0]["part_of_speech"]
    else:
        pos = detect_part_of_speech(japanese, word)

    # 2. Other Meanings (Multiple Senses)
    other_meanings_json = ""
    if word in CURATED_SENSES_DICT:
        senses = CURATED_SENSES_DICT[word]
        # Attach CEFR to senses
        for s in senses:
            s["cefr"] = cefr
        other_meanings_json = json.dumps(senses, ensure_ascii=False)
    else:
        # Split Japanese definitions by comma/punctuation if multiple definitions exist
        meanings = [m.strip() for m in re.split(r"[、,]", japanese) if m.strip()]
        if len(meanings) > 1:
            senses = []
            for i, m in enumerate(meanings):
                senses.append({
                    "sense_id": i + 1,
                    "part_of_speech": detect_part_of_speech(m, word if i == 0 else ""),
                    "meaning_ja": m,
                    "cefr": cefr,
                    "example_en": example if i == 0 else None,
                    "example_ja": example_jp if i == 0 else None,
                })
            other_meanings_json = json.dumps(senses, ensure_ascii=False)

    # 3. Collocations
    collocations_json = ""
    if word in COLLOCATIONS_DICT:
        colls = COLLOCATIONS_DICT[word]
        collocations_json = json.dumps(colls, ensure_ascii=False)

    # 4. Base Form (Lemma)
    base_form = BASE_FORM_DICT.get(word, "")

    return {
        "word": word,
        "CEFR": cefr,
        "Japanese": japanese,
        "partOfSpeech": pos,
        "phonetic": phonetic,
        "category": category,
        "Example": example,
        "Example_JP": example_jp,
        "collocations": collocations_json,
        "otherMeanings": other_meanings_json,
        "baseForm": base_form,
    }


def main():
    csv_path = r"d:\dev\projects\english_app\assets\words.csv"

    print(f"Reading {csv_path}...")
    enriched_rows = []
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if not row.get("word"):
                continue
            enriched = enrich_word(row)
            enriched_rows.append(enriched)

    print(f"Total processed words: {len(enriched_rows)}")

    # Write enriched CSV
    fieldnames = [
        "word",
        "CEFR",
        "Japanese",
        "partOfSpeech",
        "phonetic",
        "category",
        "Example",
        "Example_JP",
        "collocations",
        "otherMeanings",
        "baseForm",
    ]

    with open(csv_path, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(enriched_rows)

    print(f"Successfully wrote enriched CSV to {csv_path} with {len(enriched_rows)} words!")

    # Summary breakdown
    pos_counts = {}
    with_other_meanings = 0
    with_collocations = 0
    with_base_form = 0

    for r in enriched_rows:
        p = r["partOfSpeech"]
        pos_counts[p] = pos_counts.get(p, 0) + 1
        if r["otherMeanings"]:
            with_other_meanings += 1
        if r["collocations"]:
            with_collocations += 1
        if r["baseForm"]:
            with_base_form += 1

    print("\n--- Summary Breakdown ---")
    print(f"Words with multiple senses (otherMeanings): {with_other_meanings}")
    print(f"Words with collocations: {with_collocations}")
    print(f"Words linked to base forms (baseForm): {with_base_form}")
    print("Part of speech distribution:")
    for p, c in sorted(pos_counts.items(), key=lambda x: x[1], reverse=True):
        print(f"  {p:15}: {c}")


if __name__ == "__main__":
    main()
