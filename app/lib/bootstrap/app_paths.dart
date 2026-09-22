import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where the app keeps its own files. One database file per firm.
///
/// Windows: %LOCALAPPDATA%\Ledgerly (not Roaming: a database must not be
/// copied around by roaming profiles). Elsewhere: the platform's app-support dir.
class AppPaths {
  const AppPaths(this.root);

  final Directory root;

  Directory get firms => Directory(p.join(root.path, 'firms'));
  Directory get backups => Directory(p.join(root.path, 'backups'));
  File firmDatabase(String firmId) => File(p.join(firms.path, '$firmId.db'));
  File firmKeyEnvelope(String firmId) =>
      File(p.join(firms.path, '$firmId.key.json'));

  static Future<AppPaths> resolve() async {
    final local = Platform.isWindows
        ? Platform.environment['LOCALAPPDATA']
        : null;
    final base = local != null
        ? Directory(p.join(local, 'Ledgerly'))
        : Directory(
            p.join((await getApplicationSupportDirectory()).path, 'Ledgerly'),
          );
    final paths = AppPaths(base);
    await paths.firms.create(recursive: true);
    await paths.backups.create(recursive: true);
    return paths;
  }
}
