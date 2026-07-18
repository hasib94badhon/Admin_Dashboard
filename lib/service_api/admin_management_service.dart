import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/service_api/auth_headers.dart';

class AdminManagementService {
  static Future<List<dynamic>> fetchAdmins() async {
    final res = await http.get(Uri.parse('$host/api/admins/'), headers: authHeaders());
    if (res.statusCode == 200) {
      return (jsonDecode(res.body)['results'] as List?) ?? [];
    }
    throw Exception('Failed to load admins');
  }

  static Future<Map<String, dynamic>> createAdmin({
    required String username,
    required String password,
    String email = '',
    required List<String> allowedPages,
  }) async {
    final res = await http.post(
      Uri.parse('$host/api/admins/create/'),
      headers: authHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
        'allowed_pages': allowedPages,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 201) return data;
    throw Exception(data['message'] ?? 'Failed to create admin');
  }

  static Future<void> updatePermissions(int adminId, List<String> allowedPages) async {
    final res = await http.patch(
      Uri.parse('$host/api/admins/$adminId/permissions/'),
      headers: authHeaders(),
      body: jsonEncode({'allowed_pages': allowedPages}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update permissions');
    }
  }

  static Future<bool> toggleActive(int adminId) async {
    final res = await http.patch(
      Uri.parse('$host/api/admins/$adminId/toggle-active/'),
      headers: authHeaders(),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['is_active'] as bool;
    }
    throw Exception('Failed to toggle admin status');
  }

  static Future<void> deleteAdmin(int adminId) async {
    final res = await http.delete(
      Uri.parse('$host/api/admins/$adminId/delete/'),
      headers: authHeaders(),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to delete admin');
    }
  }

  static Future<void> resetPassword(int adminId, String newPassword) async {
    final res = await http.patch(
      Uri.parse('$host/api/admins/$adminId/reset-password/'),
      headers: authHeaders(),
      body: jsonEncode({'password': newPassword}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to reset password');
    }
  }
}
