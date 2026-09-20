import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown for any non-2xx response the caller can't recover from generically.
class BackendException implements Exception {
  BackendException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'BackendException($statusCode): $message';
}

/// The access token is missing, malformed, or expired — the caller should
/// try a refresh (or send the user back to login if refresh also fails).
class BackendAuthException extends BackendException {
  BackendAuthException(String message) : super(401, message);
}

/// The server rejected the request because it already has a matching row
/// (e.g. register with an email already in use).
class BackendConflictException extends BackendException {
  BackendConflictException(String message) : super(409, message);
}

class BackendFirmInfo {
  const BackendFirmInfo({
    required this.id,
    required this.name,
    required this.contactNumber,
  });
  final String id;
  final String name;
  final String contactNumber;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'contact_number': contactNumber,
  };
}

class BackendDeviceInfo {
  const BackendDeviceInfo({
    required this.id,
    required this.name,
    required this.platform,
    required this.shortCode,
  });
  final String id;
  final String name;
  final String platform;
  final String shortCode;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'platform': platform,
    'short_code': shortCode,
  };
}

/// What register/login hand back: enough to start syncing immediately and
/// to know which firm's data this session belongs to.
class BackendSession {
  BackendSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.firmId,
    required this.firmName,
  });

  factory BackendSession.fromJson(Map<String, dynamic> json) => BackendSession(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    userId: (json['user'] as Map<String, dynamic>)['id'] as String,
    userName: (json['user'] as Map<String, dynamic>)['name'] as String,
    userEmail: (json['user'] as Map<String, dynamic>)['email'] as String,
    firmId: (json['firm'] as Map<String, dynamic>)['id'] as String,
    firmName: (json['firm'] as Map<String, dynamic>)['name'] as String,
  );

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String userName;
  final String userEmail;
  final String firmId;
  final String firmName;
}

class BackendTokenPair {
  BackendTokenPair({required this.accessToken, required this.refreshToken});

  factory BackendTokenPair.fromJson(Map<String, dynamic> json) =>
      BackendTokenPair(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );

  final String accessToken;
  final String refreshToken;
}

/// One row of any syncable table, in the shape /sync/push and /sync/pull
/// both use. `data` carries the table's own columns as plain JSON — for
/// `transactions`, that includes a `lines` list (see docs/design-spec.md
/// Section 2: a bill is header + lines together, always sent as a unit).
class BackendPushRow {
  const BackendPushRow({
    required this.table,
    required this.id,
    required this.data,
  });
  final String table;
  final String id;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {'table': table, 'id': id, 'data': data};
}

class BackendPullRow {
  BackendPullRow({required this.table, required this.id, required this.data});

  factory BackendPullRow.fromJson(Map<String, dynamic> json) => BackendPullRow(
    table: json['table'] as String,
    id: json['id'] as String,
    data: json['data'] as Map<String, dynamic>,
  );

  final String table;
  final String id;
  final Map<String, dynamic> data;
}

/// accepted/rejected are keyed by row id for quick lookup by the caller
/// clearing its outbox; rewrites map an id the caller tried to use to the
/// id it should use from now on (a customer auto-merge).
class BackendPushResult {
  BackendPushResult({
    required this.accepted,
    required this.rejected,
    required this.rewrites,
    required this.serverTime,
  });

  factory BackendPushResult.fromJson(Map<String, dynamic> json) {
    final accepted = <String, int>{
      for (final row in (json['accepted'] as List).cast<Map<String, dynamic>>())
        row['id'] as String: row['updated_at'] as int,
    };
    final rejected = <String, String>{
      for (final row in (json['rejected'] as List).cast<Map<String, dynamic>>())
        row['id'] as String: row['reason'] as String,
    };
    final rewrites = <String, String>{
      for (final row in (json['rewrites'] as List).cast<Map<String, dynamic>>())
        row['old_id'] as String: row['new_id'] as String,
    };
    return BackendPushResult(
      accepted: accepted,
      rejected: rejected,
      rewrites: rewrites,
      serverTime: json['server_time'] as int,
    );
  }

  final Map<String, int> accepted;
  final Map<String, String> rejected;
  final Map<String, String> rewrites;
  final int serverTime;
}

class BackendPullPage {
  BackendPullPage({
    required this.rows,
    required this.nextCursor,
    required this.hasMore,
  });

  factory BackendPullPage.fromJson(Map<String, dynamic> json) =>
      BackendPullPage(
        rows: (json['rows'] as List)
            .cast<Map<String, dynamic>>()
            .map(BackendPullRow.fromJson)
            .toList(),
        nextCursor: json['next_cursor'] as int,
        hasMore: json['has_more'] as bool,
      );

  final List<BackendPullRow> rows;
  final int nextCursor;
  final bool hasMore;
}

/// The one seam between the app and the phase-2 backend
/// (docs/design-spec.md Section 4). Tests replace httpClient with
/// http.testing.MockClient — a real network call from the flutter_tester
/// binary is exactly the kind of OS-touching call that hangs in this
/// project's sandboxed test environment, same reasoning as printing and
/// file pickers.
class BackendClient {
  BackendClient({required this.baseUrl, required http.Client httpClient})
    : _http = httpClient;

  final String baseUrl;
  final http.Client _http;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Map<String, String> _authHeaders(String accessToken, {String? firmId}) {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
    if (firmId != null) headers['X-Firm-Id'] = firmId;
    return headers;
  }

  Future<Map<String, dynamic>> _decode(
    http.Response response, {
    int expect = 200,
  }) async {
    if (response.statusCode != expect) {
      final detail = _detailFrom(response.body);
      if (response.statusCode == 401) throw BackendAuthException(detail);
      if (response.statusCode == 409) throw BackendConflictException(detail);
      throw BackendException(response.statusCode, detail);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _detailFrom(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
      return body;
    } on FormatException {
      return body;
    }
  }

  Future<BackendSession> register({
    required String name,
    required String email,
    required String password,
    required BackendFirmInfo firm,
    required BackendDeviceInfo device,
  }) async {
    final response = await _http.post(
      _uri('/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'firm': firm.toJson(),
        'device': device.toJson(),
      }),
    );
    return BackendSession.fromJson(await _decode(response, expect: 201));
  }

  Future<BackendSession> login({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    final response = await _http.post(
      _uri('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'device_id': deviceId,
      }),
    );
    return BackendSession.fromJson(await _decode(response));
  }

  Future<BackendTokenPair> refresh(String refreshToken) async {
    final response = await _http.post(
      _uri('/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );
    return BackendTokenPair.fromJson(await _decode(response));
  }

  Future<int> serverTime() async {
    final response = await _http.get(_uri('/sync/time'));
    final json = await _decode(response);
    return json['server_time'] as int;
  }

  Future<BackendPushResult> push({
    required String accessToken,
    required String firmId,
    required String deviceId,
    required List<BackendPushRow> rows,
  }) async {
    final response = await _http.post(
      _uri('/sync/push'),
      headers: _authHeaders(accessToken, firmId: firmId),
      body: jsonEncode({
        'device_id': deviceId,
        'schema_version': 1,
        'device_time': DateTime.now().millisecondsSinceEpoch,
        'rows': rows.map((r) => r.toJson()).toList(),
      }),
    );
    return BackendPushResult.fromJson(await _decode(response));
  }

  Future<BackendPullPage> pull({
    required String accessToken,
    required String firmId,
    required int since,
    int limit = 500,
  }) async {
    final response = await _http.get(
      _uri('/sync/pull', {'since': '$since', 'limit': '$limit'}),
      headers: _authHeaders(accessToken, firmId: firmId),
    );
    return BackendPullPage.fromJson(await _decode(response));
  }
}
