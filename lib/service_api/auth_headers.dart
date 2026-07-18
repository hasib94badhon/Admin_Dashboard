import 'package:get_storage/get_storage.dart';

String? get _authToken => GetStorage().read('auth_token') as String?;

/// Headers for authenticated JSON requests (get/post/put/patch/delete with a
/// jsonEncode body). The backend identifies the caller purely from this
/// token (see members/permissions.py's resolve_token_user) -- there's no
/// session/cookie fallback.
Map<String, String> authHeaders() {
  final token = _authToken;
  return {
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Token $token',
  };
}

/// Auth-only headers for MultipartRequest.headers -- do NOT set
/// Content-Type here, MultipartRequest computes its own (with boundary).
Map<String, String> authHeadersMultipart() {
  final token = _authToken;
  return {
    if (token != null && token.isNotEmpty) 'Authorization': 'Token $token',
  };
}
