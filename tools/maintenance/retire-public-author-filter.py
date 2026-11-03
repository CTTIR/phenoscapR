"""Remove exact public-author alternatives without exposing the private pattern."""
import base64
import json
import os
import re
import subprocess
from pathlib import Path


def split_choices(pattern):
    choices, start, depth, in_class, escaped = [], 0, 0, False, False
    for i, char in enumerate(pattern):
        if escaped:
            escaped = False
            continue
        if char == '\\':
            escaped = True
            continue
        if char == '[':
            in_class = True
        elif char == ']' and in_class:
            in_class = False
        elif not in_class:
            if char == '(':
                depth += 1
            elif char == ')':
                depth -= 1
                if depth < 0:
                    raise ValueError('Unsupported filter structure')
            elif char == '|' and depth == 0:
                choices.append(pattern[start:i]); start = i + 1
    if escaped or in_class or depth:
        raise ValueError('Unsupported filter structure')
    choices.append(pattern[start:])
    return choices


def unwrap(pattern):
    prefix, suffix = '', ''
    while True:
        flag = re.match(r'^\(\?[ims]+\)', pattern)
        if flag:
            prefix += flag.group(); pattern = pattern[flag.end():]; continue
        trailing_slashes = len(pattern[:-1]) - len(pattern[:-1].rstrip('\\'))
        if (pattern.startswith(r'\b') and pattern.endswith(r'\b') and
                trailing_slashes == 1 and len(split_choices(pattern)) == 1):
            prefix += r'\b'; suffix = r'\b' + suffix; pattern = pattern[2:-2]; continue
        opener = '(?:' if pattern.startswith('(?:') else '(' if pattern.startswith('(') and not pattern.startswith('(?') else None
        if opener and pattern.endswith(')'):
            inner = pattern[len(opener):-1]
            try:
                split_choices(inner)
            except ValueError:
                break
            prefix += opener; suffix = ')' + suffix; pattern = inner; continue
        break
    return prefix, pattern, suffix


def public_author(choice):
    if re.search(r'\(\?[ims]+\)', choice):
        return False
    prefix, inner, suffix = unwrap(choice)
    # Only literal spellings of the publicly named author are eligible. Complex
    # expressions, character classes, lookarounds and wider terms are retained.
    spellings = {'chteinberg', 'emil chteinberg', r'e\. chteinberg',
                 r'emil\s+chteinberg', r'e\.\s+chteinberg'}
    return inner.lower() in spellings


def retire(pattern):
    if '\n' in pattern or '\r' in pattern:
        raise ValueError('Multiline filter needs an explicit review')
    if '[' in pattern or ']' in pattern or r'\Q' in pattern or r'\E' in pattern:
        raise ValueError('Character classes or quoted literals need an explicit review')
    if re.search(r'\(\?(?!:|[ims]+\))', pattern):
        raise ValueError('Unsupported group construct needs an explicit review')
    if re.search(r'\\(?:[1-9]|g|k)|\(\?\(|\(\?P=|\(\?&|\(\?R', pattern):
        raise ValueError('Filter references need an explicit review')
    prefix, body, suffix = unwrap(pattern)
    choices = split_choices(body)
    kept = [item for item in choices if not public_author(item)]
    removed = len(choices) - len(kept)
    if not removed:
        raise ValueError('No exact public-author alternative; filter unchanged')
    replacement = prefix + ('|'.join(kept) if kept else '(?!)') + suffix
    return replacement, removed, len(kept)


def hit_count(pattern):
    result = subprocess.run(['grep', '-r', '-I', '-P', '-l', '--exclude-dir=.git',
                             '-e', pattern, '.'], capture_output=True)
    if result.returncode not in (0, 1):
        raise ValueError('Filter validation failed; no replacement produced')
    return len(result.stdout.splitlines())


def main():
    from nacl.public import PublicKey, SealedBox
    pattern = os.environ.get('CTTIR_PRIVATE_TERMS', '')
    replacement, removed, retained = retire(pattern)
    old_hits, new_hits = hit_count(pattern), hit_count(replacement)
    box = SealedBox(PublicKey(base64.b64decode(os.environ['GITHUB_SECRET_PUBLIC_KEY'])))
    def encrypted(value):
        return {'key_id': os.environ['GITHUB_SECRET_KEY_ID'],
                'encrypted_value': base64.b64encode(box.encrypt(value.encode())).decode()}
    receipt = {'secret_name': 'CTTIR_PRIVATE_TERMS', 'removed_alternatives': removed,
               'retained_alternatives': retained, 'old_hit_files': old_hits,
               'new_hit_files': new_hits, 'updated_secret': encrypted(replacement),
               'rollback_secret': encrypted(pattern)}
    output = Path(os.environ['RUNNER_TEMP']) / 'author-filter-update.json'
    output.write_text(json.dumps(receipt) + '\n')
    print('Exact public-author alternatives removed; other alternatives retained verbatim.')
    print('Only GitHub-encrypted replacement and rollback values were written.')


if __name__ == '__main__':
    try:
        main()
    except Exception:
        raise SystemExit('Filter update stopped safely; no secret value was printed or changed.')
