"""Builds assets/json/mushaf_lines.json, the 15-line page layout of each of
the 604 pages, from the King Fahd Complex Hafs developer data:

  python3 tool/build_mushaf.py hafsData_v2-0.json

hafsData_v2-0.json (https://qurancomplex.gov.sa/techquran/dev/) gives each
ayah's text (with its ayah-number glyph for the KFGQPC Uthmanic Hafs font),
its page and the first and last line it occupies. The text is copied
unchanged. Where an ayah runs over several lines, the data doesn't say at
which word each line breaks, so the words are split so that the lines of
the page come out as even in length as possible, with every ayah still
starting and ending on its official line.

It also sets the "page" of every ayah in assets/json/quran_ar_uthmani.json to
the page the Complex gives, so page numbers agree everywhere in the app (the
older bundled data placed 56 ayahs on a neighbouring page), and each surah's
page range in assets/json/surahs.json to match.

Output: a list of 604 pages; each page is a list of [line, kind, value]:
kind 0 = text (string), 1 = surah header (surah number), 2 = basmala (its
text), 3 = surah header and basmala sharing one line (surah number).
"""

import json
import re
import sys
import unicodedata

src = sys.argv[1]
out = sys.argv[2] if len(sys.argv) > 2 else 'assets/json/mushaf_lines.json'

ayahs = json.load(open(src, encoding='utf-8'))
assert len(ayahs) == 6236
problems = []


def width(token):
    return sum(1 for c in token if not unicodedata.combining(c)) + 1


def split(text):
    body, mark = re.match(r'(.*)\s(\S+)$', text.strip(), re.S).groups()
    return [w for w in body.split(' ') if w] + [mark]


def lay_out(page_ayahs):
    """Assign each token of the page a line: returns {line: [tokens]}."""
    tokens, lo, hi = [], [], []
    for a in page_ayahs:
        ws = split(a['aya_text'])
        for i, w in enumerate(ws):
            tokens.append(w)
            lo.append(a['line_start'] if i == 0 else a['line_start'])
            hi.append(a['line_end'])
        lo[-len(ws)] = hi[-len(ws)] = a['line_start']
        lo[-1] = a['line_end']
    lines = sorted({l for a in page_ayahs for l in range(a['line_start'], a['line_end'] + 1)})
    n = len(tokens)
    pre = [0]
    for t in tokens:
        pre.append(pre[-1] + width(t))
    target = pre[-1] / len(lines)
    inf = float('inf')
    best = [[inf] * (n + 1) for _ in lines]
    back = [[0] * (n + 1) for _ in lines]
    for j, line in enumerate(lines):
        for i in range(1, n + 1):
            if not lo[i - 1] <= line <= hi[i - 1]:
                continue
            k = i - 1
            while k >= 0 and lo[k] <= line <= hi[k]:
                prev = 0 if j == 0 and k == 0 else (best[j - 1][k] if j > 0 else inf)
                if prev < inf:
                    cost = prev + (pre[i] - pre[k] - target) ** 2
                    if cost < best[j][i]:
                        best[j][i], back[j][i] = cost, k
                if j == 0 and k == 0:
                    break
                k -= 1
    if best[-1][n] == inf:
        problems.append(f"page {page_ayahs[0]['page']}: no layout fits the line ranges")
        return {}
    placed, i = {}, n
    for j in range(len(lines) - 1, -1, -1):
        k = back[j][i]
        placed[lines[j]] = tokens[k:i]
        i = k
    return placed


def lines_on(page):
    return 8 if page <= 2 else 15


basmala = split(ayahs[0]['aya_text'])[:-1]
basmala = ' '.join(basmala)
by_page = {}
for a in ayahs:
    by_page.setdefault(a['page'], []).append(a)
assert sorted(by_page) == list(range(1, 605))

slots = {}
for p, page_ayahs in by_page.items():
    for line, words in lay_out(page_ayahs).items():
        slots[(p, line)] = ' '.join(words)

first_ayah = {(a['page'], a['line_start']): a for a in ayahs if a['aya_no'] == 1}
order = [(p, l) for p in range(1, 605) for l in range(1, lines_on(p) + 1)]
pages = [[] for _ in range(604)]
gap = []
for p, l in order:
    if (p, l) not in slots:
        gap.append((p, l))
        continue
    if gap:
        a = first_ayah.get((p, l))
        if a is None:
            problems.append(f'empty lines {gap} not before a surah start')
        else:
            s = a['sura_no']
            if s in (1, 9):
                kinds = [(1, s)]
            elif len(gap) == 1:
                kinds = [(3, s)]
            else:
                kinds = [(1, s), (2, basmala)]
            if len(kinds) != len(gap):
                problems.append(f'surah {s}: {len(gap)} empty lines, {len(kinds)} expected')
            for (gp, gl), (k, v) in zip(gap, kinds):
                pages[gp - 1].append([gl, k, v])
        gap = []
    pages[p - 1].append([l, 0, slots[(p, l)]])
if gap:
    problems.append(f'trailing empty lines {gap}')
for page in pages:
    page.sort()

if problems:
    print('\n'.join(problems[:40]), f'\n{len(problems)} problems', file=sys.stderr)
    sys.exit(1)
json.dump(pages, open(out, 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
app = 'assets/json/quran_ar_uthmani.json'
page_of = {a['id']: a['page'] for a in ayahs}
text = open(app, encoding='utf-8').read().split('\n')
number, moved = None, 0
for i, line in enumerate(text):
    m = re.match(r'(\s*)"(number|numberInSurah|page)": (\d+)(,?)$', line)
    if not m:
        continue
    indent, key, value, comma = m.groups()
    if key == 'number':
        number = int(value)
    elif key == 'page' and number in page_of and int(value) != page_of[number]:
        text[i] = f'{indent}"page": {page_of[number]}{comma}'
        moved += 1
open(app, 'w', encoding='utf-8').write('\n'.join(text))
print(f'{moved} ayahs moved to their KFGQPC page in {app}')
surahs = 'assets/json/surahs.json'
span = {}
for a in ayahs:
    lo, hi = span.get(a['sura_no'], (a['page'], a['page']))
    span[a['sura_no']] = (min(lo, a['page']), max(hi, a['page']))
meta = open(surahs, encoding='utf-8').read()
meta, n = re.subn(
    r'(\{"number": (\d+),[^{}]*?"pages": )\[\d+, \d+\]',
    lambda m: f'{m[1]}[{span[int(m[2])][0]}, {span[int(m[2])][1]}]',
    meta,
)
assert n == 114
open(surahs, 'w', encoding='utf-8').write(meta)
shared = sum(1 for p in pages for l in p if l[1] == 3)
print(f'wrote {out}: {sum(len(p) for p in pages)} lines on {len(pages)} pages, {shared} shared header lines')
