/// Hybrid logical clock: a millisecond timestamp that can only move forward on
/// this device, nudged by the wall clock and by stamps seen from other devices.
///
/// Why: last-writer-wins compares these stamps, so a phone whose clock was set
/// back must not produce stamps that lose to its own earlier edits. Ordering
/// between devices still comes from the server's sequence numbers, not from this.
class Hlc {
  Hlc({required int Function() nowMs, this.offsetMs = 0, int last = 0})
    : _nowMs = nowMs,
      _last = last;

  final int Function() _nowMs;

  /// server_time − device_time, learned at every sync.
  int offsetMs;

  int _last;
  int get last => _last;

  /// The next stamp to write on a row this device changes.
  int next() {
    final candidate = _nowMs() + offsetMs;
    _last = candidate > _last ? candidate : _last + 1;
    return _last;
  }

  /// Called for every stamp pulled from the server so nothing we issue later
  /// can sort below something we have already seen.
  void observe(int remoteStamp) {
    if (remoteStamp > _last) _last = remoteStamp;
  }

  /// After the server rejects our stamps as too far in the future, drop the
  /// floor to its time. Safe because nothing with the old stamps was accepted.
  void reseed(int serverTimeMs) {
    _last = serverTimeMs;
  }
}
