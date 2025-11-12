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
