import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-level settings that are not part of any firm's data: which device
/// this is, which firm was open last, where backups go.
abstract class GlobalPrefs {
  String get deviceId;
  String? get lastFirmId;
  String? get backupFolder;

  /// The saved default printer for silent printing. Matched by name first;
  /// [printerUrl] is kept alongside because a USB printer's URL can change
  /// when it is unplugged and reconnected, while its name usually does not.
  String? get printerName;
  String? get printerUrl;
  Future<void> setLastFirmId(String? id);
  Future<void> setBackupFolder(String? path);
  Future<void> setPrinter({String? name, String? url});
}

class SharedPrefsGlobalPrefs implements GlobalPrefs {
  SharedPrefsGlobalPrefs._(this._prefs);

  static Future<SharedPrefsGlobalPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('device_id') == null) {
      await prefs.setString('device_id', newId());
    }
    return SharedPrefsGlobalPrefs._(prefs);
  }

  final SharedPreferences _prefs;

  @override
  String get deviceId => _prefs.getString('device_id')!;
  @override
  String? get lastFirmId => _prefs.getString('last_firm_id');
  @override
  String? get backupFolder => _prefs.getString('backup_folder');
  @override
  String? get printerName => _prefs.getString('printer_name');
  @override
  String? get printerUrl => _prefs.getString('printer_url');
  @override
  Future<void> setLastFirmId(String? id) => id == null
      ? _prefs.remove('last_firm_id')
      : _prefs.setString('last_firm_id', id);
  @override
  Future<void> setBackupFolder(String? path) => path == null
      ? _prefs.remove('backup_folder')
      : _prefs.setString('backup_folder', path);
  @override
  Future<void> setPrinter({String? name, String? url}) async {
    if (name == null) {
      await _prefs.remove('printer_name');
    } else {
      await _prefs.setString('printer_name', name);
    }
    if (url == null) {
      await _prefs.remove('printer_url');
    } else {
      await _prefs.setString('printer_url', url);
    }
  }
}

class InMemoryGlobalPrefs implements GlobalPrefs {
  InMemoryGlobalPrefs({String? deviceId}) : deviceId = deviceId ?? newId();

  @override
  final String deviceId;
  @override
  String? lastFirmId;
  @override
  String? backupFolder;
  @override
  String? printerName;
  @override
  String? printerUrl;
  @override
  Future<void> setLastFirmId(String? id) async => lastFirmId = id;
  @override
  Future<void> setBackupFolder(String? path) async => backupFolder = path;
  @override
  Future<void> setPrinter({String? name, String? url}) async {
    printerName = name;
    printerUrl = url;
  }
}
