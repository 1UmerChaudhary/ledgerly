import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../bootstrap/global_prefs.dart';
import '../../bootstrap/providers.dart';
import '../../sync/backend_client.dart';
import '../../sync/sync_service.dart';

/// Real by default; overridden in tests with one built on a fake http
/// client — a real socket from the flutter_tester binary is exactly the
/// kind of OS call that hangs in this project's sandboxed environment.
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

const defaultBackendUrl = 'http://localhost:8000';

final backendClientProvider = Provider<BackendClient>((ref) {
  final url = ref.watch(globalPrefsProvider).backendUrl ?? defaultBackendUrl;
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
/// giving up and logging the user out — see [_refreshOnce] for why
/// concurrent callers share a single in-flight refresh instead of each
/// calling /auth/refresh independently.
class SyncRunner extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => const SyncStatus();

  Future<void>? _inFlightRefresh;

  Future<void> syncNow() async {
    final session = ref.read(cloudSessionProvider);
    final firm = ref.read(openFirmProvider).value;
    if (session == null || firm == null) return;
    state = SyncStatus(running: true, lastAt: state.lastAt);
    try {
      await _attemptSync(firm, session);
    } on BackendAuthException {
      final refreshed = await _refreshOnce(session);
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
    } on Exception catch (e) {
      state = SyncStatus(lastAt: state.lastAt, error: 'Sync failed: $e');
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
  Future<bool> _refreshOnce(CloudSession session) {
    return (_inFlightRefresh ??= _doRefresh(session))
        .then((_) => true)
        .catchError((_) => false);
  }

  Future<void> _doRefresh(CloudSession session) async {
    try {
      final pair = await ref.read(backendClientProvider).refresh(
        session.refreshToken,
      );
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
