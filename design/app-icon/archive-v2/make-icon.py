"""Original folded-ribbon artwork; native Icon Composer layers plus PNG fallbacks.

Run with Python 3, then `swift scripts/make-icon.swift`. No third-party packages.
The first round remains in design/app-icon/ and archive-v1/.
"""
from pathlib import Path
import json
import shutil
import subprocess

ROOT = Path(__file__).resolve().parent.parent
DEST = ROOT / "design/app-icon/v2-fold-light"
TOOL = Path("/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool")

# Broad surface gradients describe the curl. Highlights, edge bevels, cast
# shadows and appearance treatments come from Icon Composer, not these SVGs.
DEFS = '''<defs>
 <linearGradient id="pearl" x1="260" y1="280" x2="650" y2="537" gradientUnits="userSpaceOnUse">
  <stop offset="0" stop-color="#fffef9"/>
  <stop offset=".34" stop-color="#f7f5ef"/>
  <stop offset=".64" stop-color="#e9e7e9"/>
  <stop offset=".85" stop-color="#cdd1df"/>
  <stop offset="1" stop-color="#adb3c8"/>
 </linearGradient>
 <linearGradient id="gold" x1="294" y1="746" x2="733" y2="432" gradientUnits="userSpaceOnUse">
  <stop offset="0" stop-color="#c7a675"/>
  <stop offset=".22" stop-color="#f5dfac"/>
  <stop offset=".5" stop-color="#ead09b"/>
  <stop offset=".77" stop-color="#c5a36d"/>
  <stop offset="1" stop-color="#8c6e47"/>
 </linearGradient>
 <linearGradient id="return" x1="767" y1="385" x2="622" y2="588" gradientUnits="userSpaceOnUse">
  <stop offset="0" stop-color="#f0dbab"/>
  <stop offset=".28" stop-color="#d8bd83"/>
  <stop offset=".63" stop-color="#aa864d"/>
  <stop offset="1" stop-color="#74522b"/>
 </linearGradient>
 <linearGradient id="pearlBook" x1="254" y1="323" x2="555" y2="636" gradientUnits="userSpaceOnUse">
  <stop offset="0" stop-color="#fffef9"/>
  <stop offset=".42" stop-color="#f3f1eb"/>
  <stop offset=".72" stop-color="#d8d9dc"/>
  <stop offset="1" stop-color="#a4a6b1"/>
 </linearGradient>
 <linearGradient id="goldBook" x1="778" y1="311" x2="488" y2="677" gradientUnits="userSpaceOnUse">
  <stop offset="0" stop-color="#f8e4ae"/>
  <stop offset=".36" stop-color="#e6c989"/>
  <stop offset=".72" stop-color="#bd9658"/>
  <stop offset="1" stop-color="#84602e"/>
 </linearGradient>
</defs>'''

# A folded strip: a broad pearl front curls into a gold reverse at the right.
# Tangent-continuous corners are deliberately rounder than v1's polygons.
RIBBON = [
    ("01-gold-reverse", "Gold reverse", "gold", '''M 350 482
       L 742 380 C 769 373 789 387 782 414
       L 698 650 C 688 678 667 695 637 703
       L 270 800 C 240 808 223 787 233 759
       L 313 530 C 321 506 331 491 350 482 Z'''),
    ("02-pearl-front", "Pearl front", "pearl", '''M 270 342
       L 595 254 C 641 241 666 248 694 281
       C 722 314 750 352 767 386 C 780 413 764 433 731 442
       L 395 533 C 365 541 346 533 326 510
       L 248 414 C 224 384 235 352 270 342 Z'''),
]
BOOK = [
    ("01-gold-wing", "Gold wing", "goldBook", '''M 513 355
       C 558 331 663 269 732 238 C 760 225 784 240 784 273
       L 784 621 C 784 660 768 680 737 696
       L 526 801 C 502 814 478 801 478 772 L 478 417
       C 478 387 489 368 513 355 Z'''),
    ("02-pearl-wing", "Pearl wing", "pearlBook", '''M 273 246
       C 341 273 431 322 488 350 C 521 366 538 389 538 425
       L 538 775 C 538 807 515 821 486 807
       L 280 709 C 252 696 237 674 237 641 L 237 280
       C 237 249 249 236 273 246 Z'''),
]

def svg(content, background=False):
    back = '<rect width="1024" height="1024" fill="#15171b"/>' if background else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">{DEFS}{back}{content}</svg>\n'

for name, shapes in [("fold-light", RIBBON), ("fold-wings", BOOK)]:
    folder = DEST / name
    assets = folder / "FoldLogIcon.icon/Assets"
    assets.mkdir(parents=True, exist_ok=True)
    layers = []
    paths = []
    for stem, title, fill, d in shapes:
        content = f'<path d="{d}" fill="url(#{fill})"/>'
        (assets / f'{stem}.svg').write_text(svg(content))
        layers.append({'image-name': f'{stem}.svg', 'name': title})
        paths.append(content)
    for stale in assets.glob('*.svg'):
        if stale.name not in {layer['image-name'] for layer in layers}:
            stale.unlink()
    (folder / 'source.svg').write_text(svg(''.join(paths), True))
    (folder / 'mark.svg').write_text(svg(''.join(paths)))
    spec = {
        'fill': {'automatic-gradient': 'extended-srgb:0.055,0.06,0.073,1.0'},
        'groups': [{'name': 'Folded ribbon' if name == 'fold-light' else 'Folded wings',
                    'lighting': 'individual',
                    'shadow': {'kind': 'neutral', 'opacity': 0.35},
                    'specular': True,
                    'translucency': {'enabled': True, 'value': 0.14},
                    'layers': list(reversed(layers))}],
        'supported-platforms': {'squares': 'shared'},
    }
    (assets.parent / 'icon.json').write_text(json.dumps(spec, indent=2) + '\n')
    for rendition, filename in [('Default', 'default'), ('Dark', 'dark'), ('TintedDark', 'tinted'),
                                ('ClearLight', 'clear-light'), ('ClearDark', 'clear-dark')]:
        output = folder / f'{filename}.png'
        result = subprocess.run([str(TOOL), str(assets.parent), '--export-image',
              '--output-file', str(output), '--platform', 'iOS', '--rendition', rendition,
              '--width', '1024', '--height', '1024', '--scale', '1'], capture_output=True, text=True)
        if result.returncode:
            raise RuntimeError(f'{rendition}: {result.stdout} {result.stderr}')
        print(f'{name}/{filename}.png')

# Xcode compiles this document; the separate SVGs remain editable in Composer.
target = ROOT / 'FoldLog/FoldLogIcon.icon'
target.mkdir(exist_ok=True)
shutil.copytree(DEST / 'fold-light/FoldLogIcon.icon', target, dirs_exist_ok=True)
for stale in (target / 'Assets').glob('*.svg'):
    if not (DEST / 'fold-light/FoldLogIcon.icon/Assets' / stale.name).exists():
        stale.unlink()
print('Native document:', target.relative_to(ROOT))
