import 'package:intl/intl.dart';

// final String host = 'https://control.aarambd.com';
final String host = 'http://127.0.0.1:8000';

class NumberFormatter {
  static String formatNumber(int value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}k";
    } else {
      return value.toString();
    }
  }
}

class DateTimeFormatter {
  static String formatBdTime(String isoString) {
    try {
      // BD time already stored (no need to convert toLocal)
      final dt = DateTime.parse(isoString);

      // Use 12-hour format with AM/PM
      final formatter = DateFormat('dd MMM yyyy, hh:mm a');
      return formatter.format(dt);
    } catch (e) {
      return isoString;
    }
  }
}

class TimeFormatter {
  static String formatBdTime(String isoString) {
    try {
      // Parse + convert to local timezone (BD)
      final dt = DateTime.parse(isoString).toLocal();
      // 12-hour format + AM/PM
      final formatter = DateFormat('dd MMM yyyy, hh:mm a');
      return formatter.format(dt);
    } catch (e) {
      return isoString;
    }
  }
}

class ServiceShopDateTimeFormatter {
  /// Format date string into `dd-MMM-yyyy, HH:mm`
  /// - If timezone offset (+06:00) আছে → remove করে 6 hours minus করবে
  /// - If ends with Z → 그대로 রাখবে
  static String formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";

    try {
      DateTime dt;

      if (dateStr.contains("+06:00")) {
        // Parse করে 6 ঘণ্টা minus করো
        dt = DateTime.parse(dateStr);
      } else {
        // Normal ISO8601 parse (Z থাকলে UTC হিসেবে নেবে)
        dt = DateTime.parse(dateStr);
      }

      // Format into dd-MMM-yyyy, HH:mm
      final formatter = DateFormat("dd-MMM-yyyy, HH:mm");
      return formatter.format(dt);
    } catch (e) {
      return dateStr; // যদি parse fail করে, original string ফেরত দাও
    }
  }
}
