---
bootstrapped_at: 2026-10-02T18:13:11Z
starter_id: flutter
starter_name: Flutter
project_name: bulk-tempo
language_family: dart
package_manager: pub
cwd_strategy: subdir-then-move
bootstrapper_confidence: verified
phase_3_status: ok
audit_command: null
---

## Hand-off

```yaml
---
starter_id: flutter
package_manager: pub
project_name: bulk-tempo
hints:
  language_family: dart
  team_size: solo
  deployment_target: playstore
  ci_provider: github-actions
  ci_default_flow: auto-deploy-on-merge
  bootstrapper_confidence: verified
  path_taken: standard
  quality_override: false
  self_check_answers: null
  has_auth: true
  has_payments: false
  has_realtime: false
  has_ai: false
  has_background_jobs: false
---
```

## Why this stack

Flutter is the verified, typed, convention-based starter for this small Dart mobile project and its five-week after-hours MVP. The first release targets Google Play, with GitHub Actions and automatic deployment on merge. The product needs separate email-and-password accounts and private data available across devices; Firebase Authentication and Firebase cloud storage are the user's chosen services for those needs. The Flutter starter does not include that integration, so it must be added after scaffolding. AI guidance remains outside the required MVP.

## Pre-scaffold verification

| Signal | Value | Severity | Notes |
| --- | --- | --- | --- |
| npm package | not run | unavailable | Dart starter; no npm create CLI |
| GitHub repo | not run | unavailable | Registry docs URL is `https://flutter.dev/docs`, not a GitHub repository |

## Scaffold log

**Resolved invocation**: `flutter create -e .bootstrap-scaffold --project-name bulk_tempo --org com.example --platforms android,ios,web`  
**Strategy**: subdir-then-move  
**Exit code**: 0  
**Files moved**: 101  
**Conflicts (.scaffold siblings)**: none  
**.gitignore handling**: moved silently  
**.bootstrap-scaffold cleanup**: deleted  
**CLI output**:

```text
Creating project .bootstrap-scaffold...
Resolving dependencies in `.bootstrap-scaffold`...
Downloading packages...
Got dependencies in `.bootstrap-scaffold`.
Wrote 81 files.
All done!
```

**Generated files**: Flutter reported 81 files written; the move counted 101 files including generated tool and platform support files.  
**Additional check**: `flutter analyze` exited 0 with “No issues found!”

**File-by-file move log** (101 files; each moved to the same relative path in the current directory):

```text
.dart_tool/dartpad/web_plugin_registrant.dart
.dart_tool/package_config.json
.dart_tool/package_graph.json
.dart_tool/version
.gitignore
.idea/libraries/Dart_SDK.xml
.idea/libraries/KotlinJavaRuntime.xml
.idea/modules.xml
.idea/runConfigurations/main_dart.xml
.idea/workspace.xml
.metadata
README.md
analysis_options.yaml
android/.gitignore
android/app/build.gradle.kts
android/app/src/debug/AndroidManifest.xml
android/app/src/main/AndroidManifest.xml
android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java
android/app/src/main/kotlin/com/example/bulk_tempo/MainActivity.kt
android/app/src/main/res/drawable-v21/launch_background.xml
android/app/src/main/res/drawable/launch_background.xml
android/app/src/main/res/mipmap-hdpi/ic_launcher.png
android/app/src/main/res/mipmap-mdpi/ic_launcher.png
android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
android/app/src/main/res/values-night/styles.xml
android/app/src/main/res/values/styles.xml
android/app/src/profile/AndroidManifest.xml
android/build.gradle.kts
android/bulk_tempo_android.iml
android/gradle.properties
android/gradle/wrapper/gradle-wrapper.jar
android/gradle/wrapper/gradle-wrapper.properties
android/gradlew
android/gradlew.bat
android/local.properties
android/settings.gradle.kts
bulk_tempo.iml
ios/.gitignore
ios/Flutter/AppFrameworkInfo.plist
ios/Flutter/Debug.xcconfig
ios/Flutter/Generated.xcconfig
ios/Flutter/Release.xcconfig
ios/Flutter/ephemeral/.swift_pm.lock
ios/Flutter/ephemeral/Packages/.packages/FlutterFramework/Package.swift
ios/Flutter/ephemeral/Packages/.packages/FlutterFramework/Sources/FlutterFramework/FlutterFramework.swift
ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift
ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Sources/FlutterGeneratedPluginSwiftPackage/FlutterGeneratedPluginSwiftPackage.swift
ios/Flutter/ephemeral/flutter_lldb_helper.py
ios/Flutter/ephemeral/flutter_lldbinit
ios/Flutter/ephemeral/flutter_native_integration.env
ios/Flutter/flutter_export_environment.sh
ios/Runner.xcodeproj/project.pbxproj
ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata
ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist
ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings
ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme
ios/Runner.xcworkspace/contents.xcworkspacedata
ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist
ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings
ios/Runner/AppDelegate.swift
ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json
ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png
ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png
ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png
ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md
ios/Runner/Base.lproj/LaunchScreen.storyboard
ios/Runner/Base.lproj/Main.storyboard
ios/Runner/GeneratedPluginRegistrant.h
ios/Runner/GeneratedPluginRegistrant.m
ios/Runner/Info.plist
ios/Runner/Runner-Bridging-Header.h
ios/Runner/SceneDelegate.swift
ios/RunnerTests/RunnerTests.swift
lib/main.dart
pubspec.lock
pubspec.yaml
web/favicon.png
web/icons/Icon-192.png
web/icons/Icon-512.png
web/icons/Icon-maskable-192.png
web/icons/Icon-maskable-512.png
web/index.html
web/manifest.json
```

## Post-scaffold audit

**Tool**: skipped — no built-in audit tool for dart  
**Recommended external tool**: configure a Dart dependency advisory scanner separately. `dart pub outdated` can inspect outdated dependencies but is not a security audit.  
**Findings**: unavailable; a skipped audit is not a zero-findings result.

## Hints recorded but not acted on

| Hint | Value |
| --- | --- |
| bootstrapper_confidence | verified |
| quality_override | false |
| path_taken | standard |
| self_check_answers | null |
| team_size | solo |
| deployment_target | playstore |
| ci_provider | github-actions |
| ci_default_flow | auto-deploy-on-merge |
| has_auth | true |
| has_payments | false |
| has_realtime | false |
| has_ai | false |
| has_background_jobs | false |

## Next steps

The project is scaffolded and verified. A future skill will set up agent context (`AGENTS.md`); this run did not generate one. Review the generated Flutter app, replace the example organization identifier before release, and configure Firebase Authentication and cloud storage as specified in the hand-off. No `.scaffold` conflicts were created. A Dart dependency security audit remains to be configured separately.
