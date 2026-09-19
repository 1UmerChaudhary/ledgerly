import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/app_paths.dart';
import 'bootstrap/global_prefs.dart';
import 'bootstrap/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Only the two cheap reads happen before the first frame; the database opens
  // asynchronously behind the shell so the window never sits blank.
  final prefs = await SharedPrefsGlobalPrefs.load();
  final paths = await AppPaths.resolve();
  runApp(
    ProviderScope(
      overrides: [
        globalPrefsProvider.overrideWithValue(prefs),
        appPathsProvider.overrideWithValue(paths),
      ],
      child: const LedgerlyApp(),
    ),
  );
}
