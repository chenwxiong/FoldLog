"""Generate the small native Xcode project; no external generator dependency."""
from pathlib import Path
import hashlib

root = Path(__file__).resolve().parent.parent
project = root / 'FoldLog.xcodeproj'
project.mkdir(exist_ok=True)
def uid(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()

names = ['project','main','products','appgroup','testgroup','app','tests','appproduct','testproduct',
         'appsources','appframeworks','appresources','testsources','testframeworks','testresources',
         'projectconfigs','appconfigs','testconfigs','proxy','dependency',
         'widgetgroup','coregroup','widgetviewgroup','widget','widgetproduct','widgetconfigs',
         'widgetsources','widgetframeworks','widgetresources','widgetproxy','widgetdependency','embedwidgets','embedwidgetfile','widgetexceptions','appexceptions']
i = {name: uid(name) for name in names}
objects = []
def obj(name, body):
    objects.append(f'{i.get(name, uid(name))} = {{ {body} }};')

obj('appexceptions', f'isa = PBXFileSystemSynchronizedBuildFileExceptionSet; membershipExceptions = (Info.plist,); target = {i["app"]};')
obj('appgroup', f'isa = PBXFileSystemSynchronizedRootGroup; exceptions = ({i["appexceptions"]},); path = FoldLog; sourceTree = "<group>";')
obj('testgroup', 'isa = PBXFileSystemSynchronizedRootGroup; path = FoldLogUITests; sourceTree = "<group>";')
obj('widgetexceptions', f'isa = PBXFileSystemSynchronizedBuildFileExceptionSet; membershipExceptions = (Info.plist,); target = {i["widget"]};')
obj('widgetgroup', f'isa = PBXFileSystemSynchronizedRootGroup; exceptions = ({i["widgetexceptions"]},); path = FoldLogWidgets; sourceTree = "<group>";')
obj('coregroup', 'isa = PBXFileSystemSynchronizedRootGroup; path = FoldLog/Core; name = "Shared Core"; sourceTree = "<group>";')
obj('widgetviewgroup', 'isa = PBXFileSystemSynchronizedRootGroup; path = FoldLog/Widgets; name = "Shared Widget Views"; sourceTree = "<group>";')
obj('appproduct', 'isa = PBXFileReference; explicitFileType = wrapper.application; path = FoldLog.app; sourceTree = BUILT_PRODUCTS_DIR;')
obj('testproduct', 'isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = FoldLogUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
obj('widgetproduct', 'isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; path = FoldLogWidgets.appex; sourceTree = BUILT_PRODUCTS_DIR;')
obj('main', f'isa = PBXGroup; children = ({i["appgroup"]},{i["widgetgroup"]},{i["coregroup"]},{i["widgetviewgroup"]},{i["testgroup"]},{i["products"]},); sourceTree = "<group>";')
obj('products', f'isa = PBXGroup; children = ({i["appproduct"]},{i["widgetproduct"]},{i["testproduct"]},); name = Products; sourceTree = "<group>";')
for name, kind in [('appsources','Sources'),('appframeworks','Frameworks'),('appresources','Resources'),
                   ('testsources','Sources'),('testframeworks','Frameworks'),('testresources','Resources'),
                   ('widgetsources','Sources'),('widgetframeworks','Frameworks'),('widgetresources','Resources')]:
    obj(name, f'isa = PBX{kind}BuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
obj('proxy', f'isa = PBXContainerItemProxy; containerPortal = {i["project"]}; proxyType = 1; remoteGlobalIDString = {i["app"]}; remoteInfo = FoldLog;')
obj('dependency', f'isa = PBXTargetDependency; target = {i["app"]}; targetProxy = {i["proxy"]};')
obj('widgetproxy', f'isa = PBXContainerItemProxy; containerPortal = {i["project"]}; proxyType = 1; remoteGlobalIDString = {i["widget"]}; remoteInfo = FoldLogWidgets;')
obj('widgetdependency', f'isa = PBXTargetDependency; target = {i["widget"]}; targetProxy = {i["widgetproxy"]};')
obj('embedwidgetfile', f'isa = PBXBuildFile; fileRef = {i["widgetproduct"]}; settings = {{ ATTRIBUTES = (RemoveHeadersOnCopy,); }};')
obj('embedwidgets', f'isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; files = ({i["embedwidgetfile"]},); name = "Embed App Extensions"; runOnlyForDeploymentPostprocessing = 0;')
for target, product, group, configs, phases, dependencies, producttype in [
    ('app','appproduct','appgroup','appconfigs',['appsources','appframeworks','appresources','embedwidgets'],['widgetdependency'], 'application'),
    ('tests','testproduct','testgroup','testconfigs',['testsources','testframeworks','testresources'],['dependency'], 'bundle.ui-testing'),
    ('widget','widgetproduct','widgetgroup','widgetconfigs',['widgetsources','widgetframeworks','widgetresources'],[], 'app-extension')]:
    name = {'app': 'FoldLog', 'tests': 'FoldLogUITests', 'widget': 'FoldLogWidgets'}[target]
    groups = [group] + (['coregroup', 'widgetviewgroup'] if target == 'widget' else [])
    obj(target, f'''isa = PBXNativeTarget; buildConfigurationList = {i[configs]};
        buildPhases = ({','.join(i[x] for x in phases)},); buildRules = ();
        dependencies = ({','.join(i[x] for x in dependencies)});
        fileSystemSynchronizedGroups = ({','.join(i[x] for x in groups)},); name = {name}; productName = {name};
        productReference = {i[product]}; productType = "com.apple.product-type.{producttype}";''')
obj('project', f'''isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 2710;
    TargetAttributes = {{ {i['app']} = {{ CreatedOnToolsVersion = 27.1; SystemCapabilities = {{ com.apple.ApplicationGroups.iOS = {{ enabled = 1; }}; }}; }};
    {i['widget']} = {{ CreatedOnToolsVersion = 27.1; SystemCapabilities = {{ com.apple.ApplicationGroups.iOS = {{ enabled = 1; }}; }}; }};
    {i['tests']} = {{ CreatedOnToolsVersion = 27.1; TestTargetID = {i['app']}; }}; }}; }};
    buildConfigurationList = {i['projectconfigs']}; compatibilityVersion = "Xcode 16.0";
    developmentRegion = "zh-Hans"; hasScannedForEncodings = 0; knownRegions = ("zh-Hans",en,Base,);
    mainGroup = {i['main']}; productRefGroup = {i['products']}; projectDirPath = ""; projectRoot = "";
    targets = ({i['app']},{i['tests']},{i['widget']},);''')
for owner in ['project','app','test','widget']:
    for config in ['Debug','Release']:
        key = owner + config
        if owner == 'project':
            settings = '''CLANG_ENABLE_MODULES = YES; CLANG_ENABLE_OBJC_ARC = YES;
                SDKROOT = iphoneos; SWIFT_VERSION = 6.0;
                ENABLE_USER_SCRIPT_SANDBOXING = YES; SWIFT_STRICT_CONCURRENCY = complete;'''
            settings += ' IPHONEOS_DEPLOYMENT_TARGET = 26.0; SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;' if config == 'Debug' else ' IPHONEOS_DEPLOYMENT_TARGET = 27.1;'
            settings += ' SWIFT_OPTIMIZATION_LEVEL = "-Onone"; DEBUG_INFORMATION_FORMAT = dwarf;' if config == 'Debug' else ' SWIFT_OPTIMIZATION_LEVEL = "-O"; DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";'
        else:
            is_app = owner == 'app'
            settings = f'''CODE_SIGN_STYLE = Automatic; GENERATE_INFOPLIST_FILE = YES;
                CURRENT_PROJECT_VERSION = 1; MARKETING_VERSION = 0.1.0;
                PRODUCT_BUNDLE_IDENTIFIER = app.foldlog.preview{'' if is_app else '.widgets' if owner == 'widget' else '.uitests'};
                PRODUCT_NAME = "$(TARGET_NAME)"; TARGETED_DEVICE_FAMILY = 1;
                SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
                SUPPORTS_MACCATALYST = NO; SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
                SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO;
                SWIFT_EMIT_LOC_STRINGS = YES;'''
            if is_app:
                settings += '''CODE_SIGN_ENTITLEMENTS = FoldLog/FoldLog.entitlements;
                    ASSETCATALOG_COMPILER_APPICON_NAME = FoldLogIcon;
                    INFOPLIST_FILE = FoldLog/Info.plist;
                    INFOPLIST_KEY_CFBundleDisplayName = "折记";
                    INFOPLIST_KEY_UILaunchScreen_Generation = YES;
                    INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
                    INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
                    INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
                    ENABLE_PREVIEWS = YES;'''
            elif owner == 'widget':
                settings += '''CODE_SIGN_ENTITLEMENTS = FoldLogWidgets/FoldLogWidgets.entitlements;
                    INFOPLIST_FILE = FoldLogWidgets/Info.plist;
                    INFOPLIST_KEY_CFBundleDisplayName = "折记小组件";
                    APPLICATION_EXTENSION_API_ONLY = YES; SKIP_INSTALL = YES;
                    ENABLE_PREVIEWS = YES;'''
            else:
                settings += ' TEST_TARGET_NAME = FoldLog;'
        obj(key, f'isa = XCBuildConfiguration; buildSettings = {{ {settings} }}; name = {config};')
    obj(owner + 'configs', f'isa = XCConfigurationList; buildConfigurations = ({uid(owner+"Debug")},{uid(owner+"Release")},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
(project/'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 77; objects = {\n'+'\n'.join(objects)+f'\n}}; rootObject = {i["project"]}; }}\n')
schemes = project/'xcshareddata/xcschemes'
schemes.mkdir(parents=True, exist_ok=True)
def reference(target, name):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{i[target]}" BuildableName="{name}" BlueprintName="{name.split(".")[0]}" ReferencedContainer="container:FoldLog.xcodeproj"/>'
appref=reference('app','FoldLog.app')
testref=reference('tests','FoldLogUITests.xctest')
(schemes/'FoldLog.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2710" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
<BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{appref}</BuildActionEntry>
</BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{testref}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{appref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{appref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print(project)
