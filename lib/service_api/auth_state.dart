import 'dart:convert';
import 'package:get_storage/get_storage.dart';

/// Reads the auth/permission state written by AuthenticationPage on login.
/// Superadmins (is_superadmin == true) always have full access; everyone
/// else is restricted to the pages listed in allowed_pages.
class AuthState {
  static bool get isSuperAdmin =>
      GetStorage().read('is_superadmin') as bool? ?? false;

  static List<String> get allowedPages {
    final raw = GetStorage().read('allowed_pages') as String?;
    if (raw == null || raw.isEmpty) return [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  static bool canAccessPageKey(String pageKey) =>
      isSuperAdmin || allowedPages.contains(pageKey);
}
