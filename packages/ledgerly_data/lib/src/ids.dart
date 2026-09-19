import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Lowercase uuid v4, made on the device. The database CHECKs the shape.
String newId() => _uuid.v4();

/// Deterministic id for a history row so every writer of the same losing
/// version (this device, the server, a retry) collides into one row.
String historyId(
  String transactionId,
  int loserUpdatedAt,
  String loserDeviceId,
) => _uuid.v5(
  Namespace.url.value,
  'ledgerly:history:$transactionId:$loserUpdatedAt:$loserDeviceId',
);
