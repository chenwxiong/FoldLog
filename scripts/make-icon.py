"""Warm ivory continuous folio + custom 00, with native Composer materials.

Run `python3 scripts/make-icon.py`, then `swift scripts/make-icon.swift`.
No third-party packages. Previous renderers remain in archive-v1/v2/v3.
"""
from pathlib import Path
import json
import shutil
import subprocess

ROOT = Path(__file__).resolve().parent.parent
DEST = ROOT / 'design/app-icon/v4-warm-ivory'
TOOL = Path('/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool')
LIGHT_BACKGROUND = '#f1e9dc'
DARK_BACKGROUND = '#ddd4c4'


def composer_color(hex_color):
    channels = [int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return 'extended-srgb:' + ','.join(f'{value:.5f}' for value in channels) + ',1.00000'

# A single uninterrupted page surface. There is no central layer boundary,
# hinge strip, divider, color join or separately shaded left/right half.
BOOK = '''M255 247 C326 265 429 319 486 337 C502 342 522 342 538 337
 C595 319 698 265 769 247 C790 242 808 256 808 281
 L808 624 C808 659 789 685 762 698 C694 727 595 772 539 797
 C522 805 502 805 485 797 C429 772 330 727 262 698
 C235 685 216 659 216 624 L216 281 C216 256 234 242 255 247 Z'''

# Hand-drawn counter-style 0, not a font, SF Symbol or live number badge.
# Squarer counters and close spacing make the pair read as numerals.
ZERO = '''M40 0 L114 0 C140 0 154 14 154 40 L154 220
 C154 246 140 260 114 260 L40 260 C14 260 0 246 0 220 L0 40 C0 14 14 0 40 0 Z
 M60 43 C49 43 43 49 43 60 L43 200 C43 211 49 217 60 217
 L94 217 C105 217 111 211 111 200 L111 60 C111 49 105 43 94 43 Z'''
LEFT = 'matrix(1 .2 0 1 325 385)'
RIGHT = 'matrix(1 -.2 0 1 545 415.8)'
TURN = '''M98 0 L114 0 C140 0 154 14 154 40 L154 88
 C151 67 137 53 111 47 C107 44 101 43 94 43 L78 43
 C95 32 101 16 98 0 Z'''
DEFS = '''<defs>
 <linearGradient id="page" x1="330" y1="260" x2="695" y2="773" gradientUnits="userSpaceOnUse">
  <stop offset="0" stop-color="#fffefa"/><stop offset=".4" stop-color="#faf7f0"/>
  <stop offset=".74" stop-color="#e9e4d9"/><stop offset="1" stop-color="#d1c9b9"/>
 </linearGradient>
 <linearGradient id="gold" x1="268" y1="550" x2="754" y2="780" gradientUnits="userSpaceOnUse">
  <stop offset="0" stop-color="#f7e2ae"/><stop offset=".5" stop-color="#d9ba80"/>
  <stop offset="1" stop-color="#a7844e"/>
 </linearGradient>
 <linearGradient id="ink" x1="320" y1="380" x2="700" y2="680" gradientUnits="userSpaceOnUse">
  <stop offset="0" stop-color="#766652"/><stop offset=".55" stop-color="#635441"/>
  <stop offset="1" stop-color="#504434"/>
 </linearGradient>
</defs>'''


def svg(content):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" '
            'viewBox="0 0 1024 1024">' + DEFS + content + '</svg>\n')


for name, has_turn in [('connected-00', True), ('plain-00', False)]:
    folder = DEST / name
    assets = folder / 'FoldLogIcon.icon/Assets'
    assets.mkdir(parents=True, exist_ok=True)
    page = f'<path d="{BOOK}" fill="url(#page)"/>'
    edge = f'<path d="{BOOK}" transform="translate(0 12)" fill="url(#gold)"/>'
    digits = (f'<g fill="url(#ink)" fill-rule="evenodd">'
              f'<path transform="{LEFT}" d="{ZERO}"/>'
              f'<path transform="{RIGHT}" d="{ZERO}"/></g>')
    if has_turn:
        digits += f'<path transform="{RIGHT}" d="{TURN}" fill="url(#gold)"/>'
    artwork = {'digits.svg': digits, 'book.svg': page, 'gold-edge.svg': edge}
    for filename, content in artwork.items():
        (assets / filename).write_text(svg(content))
    for stale in assets.glob('*.svg'):
        if stale.name not in artwork:
            stale.unlink()
    (folder / 'mark.svg').write_text(svg(edge + page + digits))
    for filename, background in [('source.svg', LIGHT_BACKGROUND), ('source-dark.svg', DARK_BACKGROUND)]:
        (folder / filename).write_text(svg(f'<rect width="1024" height="1024" fill="{background}"/>'
                                           + edge + page + digits))
    spec = {
        # Use the specialization array for BOTH the default and dark values.
        # A top-level `fill` takes precedence over this array. Automatic gradients
        # also generate a black dark background, so dark uses an explicit solid.
        'fill-specializations': [
            {'value': {'automatic-gradient': composer_color(LIGHT_BACKGROUND)}},
            {'appearance': 'dark', 'value': {'solid': composer_color(DARK_BACKGROUND)}},
        ],
        'groups': [{
            'name': 'Continuous folio and 00',
            'lighting': 'individual',
            'shadow': {'kind': 'neutral', 'opacity': .25},
            'specular': True,
            # Composer layer arrays run front to back.
            'layers': [
                {'image-name': 'digits.svg', 'name': 'Custom 00 with turn' if has_turn else 'Custom 00'},
                {'image-name': 'book.svg', 'name': 'One continuous pearl page surface'},
                {'image-name': 'gold-edge.svg', 'name': 'Champagne lower page edge'},
            ],
        }],
        'supported-platforms': {'squares': 'shared'},
    }
    (assets.parent / 'icon.json').write_text(json.dumps(spec, indent=2) + '\n')
    for rendition, filename in [('Default', 'default'), ('Dark', 'dark'),
                                ('TintedLight', 'tinted-light'), ('TintedDark', 'tinted'),
                                ('ClearLight', 'clear-light'), ('ClearDark', 'clear-dark')]:
        result = subprocess.run([str(TOOL), str(assets.parent), '--export-image',
            '--output-file', str(folder / f'{filename}.png'), '--platform', 'iOS',
            '--rendition', rendition, '--width', '1024', '--height', '1024', '--scale', '1'],
            capture_output=True, text=True)
        if result.returncode:
            raise RuntimeError(f'{name}/{rendition}: {result.stdout} {result.stderr}')
        print(f'{name}/{filename}.png', flush=True)

# Cover the generated document only; other application assets and data stay intact.
source = DEST / 'connected-00/FoldLogIcon.icon'
target = ROOT / 'FoldLog/FoldLogIcon.icon'
shutil.copytree(source, target, dirs_exist_ok=True)
for stale in (target / 'Assets').glob('*.svg'):
    if not (source / 'Assets' / stale.name).exists():
        stale.unlink()
print('Native document:', target.relative_to(ROOT))
