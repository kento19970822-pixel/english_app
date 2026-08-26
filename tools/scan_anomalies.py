import csv
import json
import re
import sys
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

with open('assets/words.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    rows = list(reader)

print(f"Total entries: {len(rows)}")

# 1. Check for inflected phonetics on base words (e.g., word ends without 's' but phonetic ends with /z/ or /s/ or /ts/)
inflected_phonetics = []
for i, r in enumerate(rows):
    w = r['word'].lower()
    p = r['phonetic']
    if not w.endswith('s') and not w.endswith('ss') and not w.endswith('x') and not w.endswith('ch') and not w.endswith('sh'):
        if p.endswith('z/') or p.endswith('s/') or p.endswith('ts/') or p.endswith('ks/') or p.endswith('dz/'):
            inflected_phonetics.append((i+1, w, r['Japanese'], p, r['Example']))

print(f"\n[Issue 1] Words without trailing 's' but with plural/3sg phonetic ending (/z/, /s/, /ks/, etc.): {len(inflected_phonetics)} items")
for item in inflected_phonetics[:15]:
    print(f"  Line {item[0]}: word='{item[1]}', JP='{item[2]}', IPA='{item[3]}', Ex='{item[4]}'")

# 2. Check for words whose example doesn't contain the base word (case-insensitive word boundary)
missing_in_example = []
for i, r in enumerate(rows):
    w = r['word'].lower()
    ex = r['Example'].lower()
    # match exact word or basic inflections
    pattern = r'\b' + re.escape(w) + r'\b'
    if not re.search(pattern, ex):
        missing_in_example.append((i+1, w, r['Japanese'], r['Example']))

print(f"\n[Issue 2] Words not found in their own Example sentence: {len(missing_in_example)} items")
for item in missing_in_example[:10]:
    print(f"  Line {item[0]}: word='{item[1]}', Ex='{item[3]}'")

# 3. Check for specific corrupted homograph lemmas (like more -> mores, us -> uses)
corrupted_homographs = []
for i, r in enumerate(rows):
    w = r['word'].lower()
    jp = r['Japanese']
    if w == 'more' and ('慣習' in jp or '規範' in jp):
        corrupted_homographs.append((i+1, w, jp))
    elif w == 'us' and ('使用' in jp or '使う' in jp):
        corrupted_homographs.append((i+1, w, jp))
    elif w == 'out' and '３連続' in r['Example_JP']:
        corrupted_homographs.append((i+1, w, jp))

print(f"\n[Issue 3] Corrupted homographs verified: {len(corrupted_homographs)}")
for item in corrupted_homographs:
    print(f"  Line {item[0]}: word='{item[1]}', JP='{item[2]}'")
