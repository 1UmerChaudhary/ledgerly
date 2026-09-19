import 'package:ledgerly_core/ledgerly_core.dart';

/// Who and where a write comes from. One per open firm database.
class DeviceContext {
  DeviceContext({
    required this.firmId,
    required this.deviceId,
    required this.deviceShortCode,
    required this.userId,
    required this.hlc,
  });

  final String firmId;
  final String deviceId;
  final String deviceShortCode;
  final String userId;
  final Hlc hlc;

  int stamp() => hlc.next();
}
