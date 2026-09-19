const String _base32 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

/// Four base32 letters derived from the device's uuid, printed on every bill
/// number so two devices numbering bills offline can never collide. Derived,
/// not allocated, because there is no server to hand out codes in phase 1.
String deviceShortCode(String deviceUuid) {
  var hash = 0x811C9DC5; // FNV-1a, 32-bit
  for (final unit in deviceUuid.toLowerCase().codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  final buffer = StringBuffer();
  for (var i = 0; i < 4; i++) {
    buffer.write(_base32[(hash >> (5 * i)) & 31]);
  }
  return buffer.toString();
}

/// The number a person reads on a slip. Rendered, never stored, so the format
/// can change without touching printed history.
String renderDisplayNo(String deviceShortCode, int displaySeq) =>
    '$deviceShortCode-$displaySeq';

/// Sequence resumes from the highest number this device has issued; integers
/// so 10 sorts after 9 (a text "A-9" would sort after "A-10").
int nextDisplaySeq(int? maxSeqForDevice) => (maxSeqForDevice ?? 0) + 1;
