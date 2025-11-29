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
