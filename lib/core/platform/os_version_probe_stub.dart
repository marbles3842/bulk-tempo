/// Returns the host operating system version string (or empty string on web).
String currentOperatingSystemVersion() => '';

/// True when running on a real iOS device/simulator runtime (outside headless tests).
bool isNativeIosRuntime() => false;
