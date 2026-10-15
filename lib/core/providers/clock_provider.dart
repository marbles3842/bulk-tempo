import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides an injectable current-time function ([DateTime Function()]),
/// defaulting to [DateTime.now].
///
/// Injecting this provider makes calendar-week window generation and
/// current-week detection deterministic in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
