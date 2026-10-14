import 'package:bulk_tempo/core/constants/locale_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/app/app.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting(LocaleConstants.english, null);
  await initializeDateFormatting(LocaleConstants.polish, null);

  runApp(const ProviderScope(child: BulkTempoApp()));
}
