import '../config/optica2_config.dart';

/// Prefix required when static files are served from /public on production.
String _assetWebPrefixForBase(Uri base) {
  final host = base.host.toLowerCase();
  if (host == 'madebymaa.online' || host.endsWith('.madebymaa.online')) {
    return '/public';
  }
  return '';
}

bool _isLocalDevHost(String host) {
  final h = host.toLowerCase();
  return h == 'localhost' ||
      h == '127.0.0.1' ||
      h == '10.0.2.2' ||
      h.startsWith('192.168.');
}

bool _isRootRelativeAssetPath(String path) {
  return path.startsWith('/uploads/') ||
      path.startsWith('/storage/') ||
      path.startsWith('/public/uploads/') ||
      path.startsWith('/public/storage/');
}

String _normalizeAssetPath(String path, {required String webPrefix}) {
  var normalized = path;

  // Collapse /public/public/... if backend and client both prefix.
  while (normalized.startsWith('/public/public/')) {
    normalized = normalized.substring('/public'.length);
  }

  if (webPrefix.isEmpty) {
    if (normalized.startsWith('/public/uploads/') ||
        normalized.startsWith('/public/storage/')) {
      return normalized.substring('/public'.length);
    }
    return normalized;
  }

  if (normalized.startsWith('/public/uploads/') ||
      normalized.startsWith('/public/storage/')) {
    return normalized;
  }

  if (normalized.startsWith('/uploads/') || normalized.startsWith('/storage/')) {
    return '$webPrefix$normalized';
  }

  return normalized;
}

String _joinBaseUrl(String path) {
  final base = Optica2Config.baseUrl;
  if (path.startsWith('/')) return '$base$path';
  return '$base/$path';
}

/// Resolves API asset paths to the active Optica2 host.
String? resolveOptica2AssetUrl(String? url) {
  if (url == null || url.isEmpty) return url;

  final apiBase = Uri.parse(Optica2Config.baseUrl);
  final webPrefix = _assetWebPrefixForBase(apiBase);

  if (url.startsWith('/')) {
    if (_isRootRelativeAssetPath(url)) {
      return _joinBaseUrl(_normalizeAssetPath(url, webPrefix: webPrefix));
    }
    return _joinBaseUrl(url);
  }

  final parsed = Uri.tryParse(url);
  if (parsed == null || !parsed.hasScheme) return url;

  if (_isLocalDevHost(parsed.host)) {
    if (_isRootRelativeAssetPath(parsed.path)) {
      final normalized = _normalizeAssetPath(parsed.path, webPrefix: webPrefix);
      return Uri(
        scheme: apiBase.scheme,
        host: apiBase.host,
        port: apiBase.hasPort ? apiBase.port : null,
        path: normalized,
        query: parsed.query.isEmpty ? null : parsed.query,
      ).toString();
    }
    return url;
  }

  if (!_isRootRelativeAssetPath(parsed.path)) {
    return url;
  }

  final normalized = _normalizeAssetPath(parsed.path, webPrefix: webPrefix);
  if (parsed.host.toLowerCase() == apiBase.host.toLowerCase()) {
    return parsed.replace(path: normalized).toString();
  }

  return Uri(
    scheme: apiBase.scheme,
    host: apiBase.host,
    port: apiBase.hasPort ? apiBase.port : null,
    path: normalized,
    query: parsed.query.isEmpty ? null : parsed.query,
  ).toString();
}
