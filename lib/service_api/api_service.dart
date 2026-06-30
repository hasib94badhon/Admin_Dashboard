import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_web_dashboard/config.dart';

class DashboardService {
  static Future<Map<String, dynamic>> fetchStats() async {
    final response = await http.get(Uri.parse("$host/api/dashboard-stats/"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load stats");
    }
  }

  static Future<Map<String, dynamic>> fetchOverviewStats() async {
    final response = await http.get(Uri.parse("$host/api/overview-stats/"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load overview stats");
    }
  }
}

class DeactivationService {
  static Future<Map<String, dynamic>> fetchDeactivatedUsers({
    String sort = 'most_recent',
    String? userId,
    String? serviceId,
    String? name,
    String? mobile,
  }) async {
    final queryParams = {
      'sort': sort,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      if (serviceId != null && serviceId.isNotEmpty) 'service_id': serviceId,
      if (name != null && name.isNotEmpty) 'name': name,
      if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
    };

    final uri = Uri.parse("$host/api/deactivated-users/")
        .replace(queryParameters: queryParams);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load deactivated users");
    }
  }
}

// ── Notification Admin Service ────────────────────────────────────────────────

class NotificationAdminService {
  // ── Dropdown data ──────────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchDesCategories() async {
    final res = await http.get(Uri.parse("$host/api/notif/des-categories/"));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body)['categories'] as List?) ?? [];
    }
    throw Exception("Failed to load des-categories");
  }

  static Future<List<dynamic>> fetchDesSubCategories(int desCatId) async {
    final uri = Uri.parse("$host/api/notif/des-sub-categories/")
        .replace(queryParameters: {'des_cat_id': desCatId.toString()});
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body)['sub_categories'] as List?) ?? [];
    }
    throw Exception("Failed to load sub-categories");
  }

  static Future<List<dynamic>> fetchUserCategories() async {
    final res = await http.get(Uri.parse("$host/api/notif/user-categories/"));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body)['categories'] as List?) ?? [];
    }
    throw Exception("Failed to load user categories");
  }

  // ── Notification Rules ─────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchRules() async {
    final res = await http.get(Uri.parse("$host/api/notification-rules/"));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body)['rules'] as List?) ?? [];
    }
    throw Exception("Failed to load rules");
  }

  static Future<bool> createRule({
    required String ruleName,
    required int desCatId,
    required int desSubCatId,
    required List<int> targetCatIds,
  }) async {
    final res = await http.post(
      Uri.parse("$host/api/notification-rules/create/"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'rule_name':      ruleName,
        'des_cat_id':     desCatId,
        'des_sub_cat_id': desSubCatId,
        'target_cat_ids': targetCatIds,
      }),
    );
    return res.statusCode == 201;
  }

  static Future<bool> toggleRule(int ruleId, bool isActive) async {
    final res = await http.put(
      Uri.parse("$host/api/notification-rules/$ruleId/update/"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'is_active': isActive}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> deleteRule(int ruleId) async {
    final res = await http.delete(
      Uri.parse("$host/api/notification-rules/$ruleId/delete/"),
    );
    return res.statusCode == 200;
  }

  // ── Broadcasts ─────────────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchBroadcasts() async {
    final res = await http.get(Uri.parse("$host/api/broadcasts/"));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body)['broadcasts'] as List?) ?? [];
    }
    throw Exception("Failed to load broadcasts");
  }

  static Future<Map<String, dynamic>> createAndSendBroadcast({
    required String title,
    required String body,
    required List<int> targetCatIds,
  }) async {
    // Step 1: create
    final createRes = await http.post(
      Uri.parse("$host/api/broadcasts/create/"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title':          title,
        'body':           body,
        'target_cat_ids': targetCatIds,
        'created_by':     'admin',
      }),
    );
    if (createRes.statusCode != 201) {
      throw Exception("Failed to create broadcast");
    }
    final broadcastId = jsonDecode(createRes.body)['broadcast_id'] as int;

    // Step 2: send
    final sendRes = await http.post(
      Uri.parse("$host/api/broadcasts/$broadcastId/send/"),
      headers: {'Content-Type': 'application/json'},
    );
    final sendData = jsonDecode(sendRes.body) as Map<String, dynamic>;
    return {'broadcast_id': broadcastId, ...sendData};
  }

  // ── Send Log ───────────────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchLogs({int page = 1}) async {
    final uri = Uri.parse("$host/api/notification-logs/")
        .replace(queryParameters: {'page': page.toString()});
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body)['logs'] as List?) ?? [];
    }
    throw Exception("Failed to load notification logs");
  }
}
