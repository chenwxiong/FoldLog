"""Capture the Duo's active display at XCTest markers (XCTest may capture its inactive screen)."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('result', type=Path)
parser.add_argument('device')
parser.add_argument('--seconds', type=int, default=240)
parser.add_argument('--prefix', default='', help='Prefix screenshot names when validating another device.')
args = parser.parse_args()
seen = set()
checks = []
deadline = time.monotonic() + args.seconds
while time.monotonic() < deadline:
    for file in args.result.glob('**/StandardOutputAndStandardError.txt'):
        try:
            output = file.read_text(errors='ignore')
        except OSError:
            continue
        for name in re.findall(r'FOLDLOG_SCREENSHOT: ([\w-]+)', output):
            if name in seen:
                continue
            seen.add(name)
            time.sleep(0.3)
            subprocess.run(['xcrun', 'simctl', 'io', args.device, 'screenshot',
                            str(args.result.parent / (args.prefix + name + '.png'))], check=True, capture_output=True)
            if name.startswith('widget-shared-'):
                group = subprocess.check_output(['xcrun', 'simctl', 'get_app_container', args.device,
                    'app.foldlog.preview', 'group.app.foldlog.preview'], text=True).strip()
                snapshot = json.loads((Path(group) / 'fold-widget-v1.json').read_text())
                checks.append({'stage': name, 'snapshot': snapshot})
                (args.result.parent / 'widget-sync-checks.json').write_text(
                    json.dumps(checks, ensure_ascii=False, indent=2))
            print(name, flush=True)
    if (args.result / 'Info.plist').exists():
        break
    time.sleep(0.4)
print(f'Captured {len(seen)} native screenshots.', flush=True)
