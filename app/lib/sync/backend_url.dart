/// The server address as people paste it, cleaned up: surrounding spaces and
/// trailing slashes dropped (BackendClient appends "/auth/...", so a pasted
/// "https://x/" requested "https://x//auth/..." and 404'd), and https://
/// added when no scheme was typed at all.
String normalizeBackendUrl(String input) {
  var url = input.trim();
  if (url.isEmpty) return url;
  if (!url.contains('://')) url = 'https://$url';
  final uri = Uri.tryParse(url);
  // Unparseable or host-less ("https://"): left as typed, slashes and all,
  // so backendUrlProblem can say so -- stripping them blindly used to turn
  // "https://" into "https://https:", which then passed every check.
  if (uri == null || uri.host.isEmpty) return url;
  return uri
      .replace(path: uri.path.replaceFirst(RegExp(r'/+$'), ''))
      .toString();
}

/// Why [url] can't work as the sync server on this device, in words for the
/// person typing it -- or null when it can. Checked before any request, so a
/// wrong address fails with an explanation instead of a raw socket error.
String? backendUrlProblem(String url, {required bool isAndroid}) {
  if (url.trim().isEmpty) {
    return "Enter your server's address, e.g. "
        'https://ledgerly-backend.onrender.com';
  }
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !(uri.scheme == 'https' || uri.scheme == 'http') ||
      uri.host.isEmpty ||
      // "http:/host" typed without its second slash parses as a server
      // literally named "http".
      const {'http', 'https'}.contains(uri.host)) {
    return "That isn't a web address. It should look like "
        'https://ledgerly-backend.onrender.com';
  }
  if (isAndroid && const {'localhost', '127.0.0.1', '::1'}.contains(uri.host)) {
    return '"${uri.host}" means this phone itself, not your server. '
        "Enter the server's real address.";
  }
  // Android refuses plain-http (cleartext) connections from release builds.
  // Desktop keeps http for a server on the same machine or office network.
  if (isAndroid && uri.scheme == 'http') {
    return 'Android only connects to secure servers: '
        'the address must start with https://';
  }
  return null;
}
