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
