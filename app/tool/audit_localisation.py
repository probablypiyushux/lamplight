"""Every English literal in lib/ that a person could see on a screen.

Deliberately over-inclusive, then filtered by hand — the point is to end with a
list nobody has to trust, rather than a number.
"""
import io
import os
import re

LIB = 'lib'
LITERAL = re.compile(r"'((?:[^'\\\n]|\\.)*)'")

# Things that are code even though they look like words.
SKIP_FILE_PREFIXES = ('lib/l10n/generated', 'lib\\l10n\\generated')
SKIP_SUFFIXES = ('.g.dart',)

# A literal is a candidate sentence if it has a space and at least two words of
# letters, and is not obviously an identifier, a path, a MIME type or a format.
IDENTIFIERISH = re.compile(r'^[a-z0-9_.\-/]*$')
MIME = re.compile(r'^[a-z]+/[a-z0-9.+*\-]+$')

def candidates():
    out = []
    for root, _dirs, files in os.walk(LIB):
        for name in files:
            path = os.path.join(root, name).replace('\\', '/')
            if not path.endswith('.dart'):
                continue
            if path.startswith(SKIP_FILE_PREFIXES) or path.endswith(SKIP_SUFFIXES):
                continue
            src = io.open(path, encoding='utf-8', newline=None).read()
            for i, line in enumerate(src.split('\n'), 1):
                stripped = line.strip()
                if stripped.startswith('//') or stripped.startswith('///'):
                    continue
                if stripped.startswith('*') or stripped.startswith('/*'):
                    continue
                for m in LITERAL.finditer(line):
                    text = m.group(1)
                    if len(text) < 6 or ' ' not in text:
                        continue
                    if IDENTIFIERISH.match(text) or MIME.match(text):
                        continue
                    words = re.findall(r'[A-Za-z]{2,}', text)
                    if len(words) < 2:
                        continue
                    out.append((path, i, text))
    return out

if __name__ == '__main__':
    rows = candidates()
    byfile = {}
    for path, line, text in rows:
        byfile.setdefault(path, []).append((line, text))
    total = 0
    for path in sorted(byfile):
        print('== %s (%d)' % (path, len(byfile[path])))
        for line, text in byfile[path]:
            print('   %5d  %s' % (line, text[:120]))
            total += 1
    print('TOTAL', total)
