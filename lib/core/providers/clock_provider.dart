import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable clock provider returning the current [DateTime].
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
