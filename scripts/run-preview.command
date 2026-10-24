#!/bin/zsh
set -euo pipefail
task_root="${0:A:h:h}"
cd "$task_root"
mkdir -p build
preview_device=$(python3 - <<'PY'
import json, subprocess
data=json.loads(subprocess.check_output(['xcrun','simctl','list','devices','available','-j']))
for devices in data['devices'].values():
    for device in devices:
        if device['name']=='FoldLog Preview':
            print(device['udid'])
            raise SystemExit
runtimes=json.loads(subprocess.check_output(['xcrun','simctl','list','runtimes','-j']))['runtimes']
ios=[r for r in runtimes if r.get('isAvailable') and r['name'].startswith('iOS')]
if not ios: raise SystemExit('请先在 Xcode 中安装一个 iOS 26 或更新的模拟器运行时。')
runtime=max(ios,key=lambda r:tuple(map(int,r['version'].split('.'))))
print(subprocess.check_output(['xcrun','simctl','create','FoldLog Preview','com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro',runtime['identifier']],text=True).strip())
PY
)
if ! xcodebuild -quiet -project FoldLog.xcodeproj -scheme FoldLog \
    -destination "platform=iOS Simulator,id=$preview_device" \
    -derivedDataPath build CODE_SIGN_IDENTITY=- build > build/preview-build.log 2>&1; then
    cat build/preview-build.log
    exit 1
fi
xcrun simctl boot "$preview_device" 2>/dev/null || true
xcrun simctl bootstatus "$preview_device" -b
xcrun simctl install "$preview_device" build/Build/Products/Debug-iphonesimulator/FoldLog.app
xcrun simctl launch --terminate-running-process "$preview_device" app.foldlog.preview --design-preview
preview_developer="$(xcode-select -p)"
preview_hub="${preview_developer:h}/Applications/DeviceHub.app"
if [[ -d "$preview_hub" ]]; then
    open -a "$preview_hub"
else
    preview_simulator="$preview_developer/Applications/Simulator.app"
    open -a "$preview_simulator" --args -CurrentDeviceUDID "$preview_device"
fi
