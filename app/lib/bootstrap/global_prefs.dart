import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Everything about a signed-in cloud sync connection. Kept as one record
/// so connecting and disconnecting are one write, same reasoning as the
/// printer choice.
class CloudSession {
  const CloudSession({
    required this.accessToken,
    required this.refreshToken,
    required this.email,
    required this.firmId,
    required this.firmName,
  });
  final String accessToken;
  final String refreshToken;
  final String email;
  final String firmId;
  final String firmName;
}

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

  /// Where the phase-2 backend lives. Editable so the same build can point
  /// at a local dev server or the real deployment.
  String? get backendUrl;

  /// Null until the device has registered or logged in.
  CloudSession? get cloudSession;

  Future<void> setLastFirmId(String? id);
  Future<void> setBackupFolder(String? path);
  Future<void> setPrinter({String? name, String? url});
  Future<void> setBackendUrl(String? url);
  Future<void> setCloudSession(CloudSession? session);
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
  String? get backendUrl => _prefs.getString('backend_url');
  @override
  CloudSession? get cloudSession {
    final token = _prefs.getString('cloud_access_token');
    final refresh = _prefs.getString('cloud_refresh_token');
    final email = _prefs.getString('cloud_email');
    final firmId = _prefs.getString('cloud_firm_id');
    final firmName = _prefs.getString('cloud_firm_name');
    if (token == null ||
        refresh == null ||
        email == null ||
        firmId == null ||
        firmName == null) {
      return null;
    }
    return CloudSession(
      accessToken: token,
      refreshToken: refresh,
      email: email,
      firmId: firmId,
      firmName: firmName,
    );
  }

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

  @override
  Future<void> setBackendUrl(String? url) => url == null
      ? _prefs.remove('backend_url')
      : _prefs.setString('backend_url', url);

  @override
  Future<void> setCloudSession(CloudSession? session) async {
    if (session == null) {
      await _prefs.remove('cloud_access_token');
      await _prefs.remove('cloud_refresh_token');
      await _prefs.remove('cloud_email');
      await _prefs.remove('cloud_firm_id');
      await _prefs.remove('cloud_firm_name');
      return;
    }
    await _prefs.setString('cloud_access_token', session.accessToken);
    await _prefs.setString('cloud_refresh_token', session.refreshToken);
    await _prefs.setString('cloud_email', session.email);
    await _prefs.setString('cloud_firm_id', session.firmId);
    await _prefs.setString('cloud_firm_name', session.firmName);
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
  String? backendUrl;
  @override
  CloudSession? cloudSession;
  @override
  Future<void> setLastFirmId(String? id) async => lastFirmId = id;
  @override
  Future<void> setBackupFolder(String? path) async => backupFolder = path;
  @override
  Future<void> setPrinter({String? name, String? url}) async {
    printerName = name;
    printerUrl = url;
  }

  @override
  Future<void> setBackendUrl(String? url) async => backendUrl = url;
  @override
  Future<void> setCloudSession(CloudSession? session) async =>
      cloudSession = session;
}
