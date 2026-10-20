import 'dart:io' show Platform;

/// Returns the host operating system version string from `dart:io`.
String currentOperatingSystemVersion() => Platform.operatingSystemVersion;

/// True when running on an iOS device/simulator runtime outside `flutter test`.
bool isNativeIosRuntime() =>
    Platform.isIOS && !Platform.environment.containsKey('FLUTTER_TEST');
