import 'package:file_selector/file_selector.dart';

/// The native "choose a folder" / "choose a file" dialogs, behind one seam
/// so tests never have to open a real OS dialog. A folder picker and a file
/// picker are the only two shapes Settings needs (backup folder; a backup
/// file to restore from).
abstract class NativePickers {
  Future<String?> pickFolder();
  Future<String?> pickFile({
    required List<String> extensions,
    required String label,
  });
}

class RealNativePickers implements NativePickers {
  @override
  Future<String?> pickFolder() async {
    final dir = await getDirectoryPath();
    return dir;
  }

  @override
  Future<String?> pickFile({
    required List<String> extensions,
    required String label,
  }) async {
    final file = await openFile(
      acceptedTypeGroups: [XTypeGroup(label: label, extensions: extensions)],
    );
    return file?.path;
  }
}
