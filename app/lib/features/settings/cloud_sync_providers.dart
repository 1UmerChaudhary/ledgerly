import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../bootstrap/global_prefs.dart';
import '../../bootstrap/providers.dart';
import '../../sync/backend_client.dart';
import '../../sync/backend_url.dart';
import '../../sync/sync_service.dart';

/// Real by default; overridden in tests with one built on a fake http
/// client — a real socket from the flutter_tester binary is exactly the
/// kind of OS call that hangs in this project's sandboxed environment.
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

/// The server a fresh install points at. A release build gets the real one
/// baked in (`flutter build apk --dart-define=LEDGERLY_BACKEND_URL=https://...`)
/// and, without it, starts empty so Settings asks for an address -- never
/// localhost, which on a phone is the phone itself. Debug builds and tests
/// keep the local development server.
const defaultBackendUrl = String.fromEnvironment(
  'LEDGERLY_BACKEND_URL',
  defaultValue: kReleaseMode ? '' : 'http://localhost:8000',
);

final backendClientProvider = Provider<BackendClient>((ref) {
  // Normalized here too, not only when Settings saves it: an address saved
  // before that (say with a trailing slash) must still work.
  final url = normalizeBackendUrl(
    ref.watch(globalPrefsProvider).backendUrl ?? defaultBackendUrl,
  );
  return BackendClient(baseUrl: url, httpClient: ref.watch(httpClientProvider));
});

/// The seam between the app and Google Sign-In. Real by default, overridden
/// in tests with a fake — same reasoning as [httpClientProvider]: the real
/// implementation drives platform channels the flutter_tester binary has no
/// registered implementation for, exactly the kind of OS call that hangs (or
/// throws) in this project's sandboxed test environment.
abstract class GoogleAuthenticator {
  /// Returns the signed-in account's ID token, or null if the interactive
  /// flow completed without one (e.g. the user cancelled the picker).
  Future<String?> signIn();
}

class RealGoogleAuthenticator implements GoogleAuthenticator {
  @override
  Future<String?> signIn() async {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(serverClientId: googleWebClientId);
    final account = await googleSignIn.authenticate();
    return account.authentication.idToken;
  }
}

final googleAuthenticatorProvider = Provider<GoogleAuthenticator>(
  (ref) => RealGoogleAuthenticator(),
);

/// The signed-in cloud session, if any. Register/login write straight
/// through to GlobalPrefs so the connection survives a restart.
class CloudSessionNotifier extends Notifier<CloudSession?> {
  @override
  CloudSession? build() => ref.watch(globalPrefsProvider).cloudSession;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final firm = ref.read(openFirmProvider).value;
    if (firm == null) return;
    final prefs = ref.read(globalPrefsProvider);
    final client = ref.read(backendClientProvider);
    final result = await client.register(
      name: name,
      email: email,
      password: password,
      firm: BackendFirmInfo(
        id: firm.ctx.firmId,
        name: firm.firmName,
        contactNumber: firm.contactNumber,
      ),
      device: BackendDeviceInfo(
        id: firm.ctx.deviceId,
        name: 'Desktop',
        platform: 'windows',
        shortCode: firm.ctx.deviceShortCode,
      ),
    );
    final session = CloudSession(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      email: result.userEmail,
      firmId: result.firmId,
      firmName: result.firmName,
    );
    await prefs.setCloudSession(session);
    state = session;
  }

  Future<void> login({required String email, required String password}) async {
    final firm = ref.read(openFirmProvider).value;
    if (firm == null) return;
    final prefs = ref.read(globalPrefsProvider);
    final client = ref.read(backendClientProvider);
    final result = await client.login(
      email: email,
      password: password,
      deviceId: firm.ctx.deviceId,
    );
    final session = CloudSession(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      email: result.userEmail,
      firmId: result.firmId,
      firmName: result.firmName,
    );
    await prefs.setCloudSession(session);
    state = session;
  }

  Future<void> signInWithGoogle() async {
    final firm = ref.read(openFirmProvider).value;
    if (firm == null) return;
    final prefs = ref.read(globalPrefsProvider);
    final client = ref.read(backendClientProvider);
    final idToken = await ref.read(googleAuthenticatorProvider).signIn();
    if (idToken == null) {
      throw StateError('Google sign-in did not return an ID token.');
    }
    final result = await client.signInWithGoogle(
      idToken: idToken,
      firm: BackendFirmInfo(
        id: firm.ctx.firmId,
        name: firm.firmName,
        contactNumber: firm.contactNumber,
      ),
      device: BackendDeviceInfo(
        id: firm.ctx.deviceId,
        name: 'Android',
        platform: 'android',
        shortCode: firm.ctx.deviceShortCode,
      ),
    );
    final session = CloudSession(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      email: result.userEmail,
      firmId: result.firmId,
      firmName: result.firmName,
    );
    await prefs.setCloudSession(session);
    state = session;
  }

  /// Attaches a Google identity to the account this session already belongs
  /// to. This is where [BackendGoogleAccountExistsException]'s instruction
  /// ("log in with your password, then link Google sign-in from Settings")
  /// actually leads: having logged in is the proof of account ownership the
  /// backend deliberately refuses to infer from a matching email address.
  Future<void> linkGoogle() async {
    final session = state;
    if (session == null) return;
    final idToken = await ref.read(googleAuthenticatorProvider).signIn();
    if (idToken == null) {
      throw StateError('Google sign-in did not return an ID token.');
    }
    await ref
        .read(backendClientProvider)
        .linkGoogle(accessToken: session.accessToken, idToken: idToken);
  }

  Future<void> logout() async {
    await ref.read(globalPrefsProvider).setCloudSession(null);
    state = null;
  }

  /// Rewrites the token pair on the existing session after a refresh — the
  /// other fields (email, firm) don't change, only the tokens rotate.
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final current = state;
    if (current == null) return;
    final updated = CloudSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      email: current.email,
      firmId: current.firmId,
      firmName: current.firmName,
    );
    await ref.read(globalPrefsProvider).setCloudSession(updated);
    state = updated;
  }
}

final cloudSessionProvider =
    NotifierProvider<CloudSessionNotifier, CloudSession?>(
      CloudSessionNotifier.new,
    );

class SyncStatus {
  const SyncStatus({
    this.running = false,
    this.lastAt,
    this.summary,
    this.error,
  });
  final bool running;
  final DateTime? lastAt;
  final String? summary;
  final String? error;
}

/// Runs push-then-pull against the currently signed-in session. On an
/// expired access token (401), silently refreshes once and retries before
/// giving up and logging the user out. Since [syncNow] became single-flight
/// two syncs never overlap, so [_refreshOnce]'s own single-flight guard can
/// no longer be raced from here; it stays as a cheap backstop for any
/// future caller of a refresh.
class SyncRunner extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => const SyncStatus();

  Future<void>? _inFlightRefresh;
  Future<void>? _inFlightSync;
  var _rerunRequested = false;

  /// Single-flight (docs/design-spec.md Section 4): with auto-sync firing on
  /// every save, a burst of saves would otherwise start a burst of parallel
  /// syncs, each pushing the same outbox rows. A call that arrives mid-run
  /// joins it and asks for ONE more run afterwards -- without that rerun, a
  /// save made after this run read the outbox would wait for the next
  /// trigger. The returned future completes once that rerun has too, so an
  /// awaiting caller knows its own change has been pushed.
  Future<void> syncNow() {
    if (_inFlightSync case final running?) {
      _rerunRequested = true;
      return running;
    }
    return _inFlightSync = _runUntilNoRerunRequested().whenComplete(
      () => _inFlightSync = null,
    );
  }

  Future<void> _runUntilNoRerunRequested() async {
    do {
      _rerunRequested = false;
      await _syncOnce();
    } while (_rerunRequested);
  }

  Future<void> _syncOnce() async {
    final session = ref.read(cloudSessionProvider);
    // Never a reloading firm: while openFirmProvider reloads (restore, lock,
    // enabling encryption) `.value` still hands back the previous firm,
    // whose database has already been closed.
    final firmState = ref.read(openFirmProvider);
    final firm = firmState.isLoading ? null : firmState.value;
    if (session == null || firm == null) return;
    state = SyncStatus(running: true, lastAt: state.lastAt);
    try {
      await _syncRefreshingOnce(firm, session);
    } on Object catch (e) {
      // Object, not just Exception: an Error (a malformed page failing a
      // cast, the database closed mid-sync for a restore) must still clear
      // `running` -- or Sync now stays disabled with no message -- and must
      // not end the rerun loop in syncNow().
      state = SyncStatus(lastAt: state.lastAt, error: 'Sync failed: $e');
    }
  }

  Future<void> _syncRefreshingOnce(OpenFirm firm, CloudSession session) async {
    try {
      await _attemptSync(firm, session);
    } on BackendAuthException {
      final refreshed = await _refreshOnce();
      if (!refreshed) {
        state = SyncStatus(
          lastAt: state.lastAt,
          error: 'Signed out of cloud sync — please log in again.',
        );
        await ref.read(cloudSessionProvider.notifier).logout();
        return;
      }
      try {
        final newSession = ref.read(cloudSessionProvider)!;
        await _attemptSync(firm, newSession);
      } on BackendAuthException {
        state = SyncStatus(
          lastAt: state.lastAt,
          error: 'Signed out of cloud sync — please log in again.',
        );
        await ref.read(cloudSessionProvider.notifier).logout();
      }
    }
  }

  Future<void> _attemptSync(OpenFirm firm, CloudSession session) async {
    final service = SyncService(
      db: firm.db,
      ctx: firm.ctx,
      client: ref.read(backendClientProvider),
      accessToken: session.accessToken,
    );
    // pushPending() is outbox-driven and only clears server-accepted
    // entries, so re-running it here after a 401 retry is safe — it never
    // resends something the server already accepted on a prior attempt.
    final pushed = await service.pushPending();
    final pulled = await service.pullAll();
    final rejectedNote = pushed.rejected.isEmpty
        ? ''
        : ', ${pushed.rejected.length} rejected';
    state = SyncStatus(
      lastAt: DateTime.now(),
      summary: 'Pushed ${pushed.accepted}, pulled $pulled$rejectedNote',
    );
  }

  /// Single-flight: if a refresh is already in progress (a second
  /// concurrent syncNow() call also hit a 401), await the SAME refresh
  /// instead of independently calling /auth/refresh with an
  /// already-about-to-be-stale refresh token — POST /auth/refresh rotates
  /// the token on every call, so a second independent refresh call would
  /// use a token the first call is about to invalidate, and itself 401,
  /// wrongly triggering a logout.
  Future<bool> _refreshOnce() {
    return (_inFlightRefresh ??= _doRefresh())
        .then((_) => true)
        .catchError((_) => false);
  }

  Future<void> _doRefresh() async {
    try {
      // Read at the moment of the call, never captured at syncNow() entry.
      // The single-flight guard above covers refreshes that OVERLAP; this
      // covers the ones that merely follow. A caller that entered before
      // another caller's refresh completed is holding a refresh token the
      // server has already rotated away, and presenting it here is a 401 --
      // which the caller reads as "even the refresh failed" and answers with
      // the wrongful logout this whole path exists to prevent.
      final session = ref.read(cloudSessionProvider);
      if (session == null) {
        throw StateError('No cloud session left to refresh.');
      }
      final pair = await ref
          .read(backendClientProvider)
          .refresh(session.refreshToken);
      await ref
          .read(cloudSessionProvider.notifier)
          .updateTokens(
            accessToken: pair.accessToken,
            refreshToken: pair.refreshToken,
          );
    } finally {
      _inFlightRefresh = null;
    }
  }
}

final syncRunnerProvider = NotifierProvider<SyncRunner, SyncStatus>(
  SyncRunner.new,
);
