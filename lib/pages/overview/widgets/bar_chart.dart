import 'package:charts_flutter_new/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/service/dashboard_service.dart';
import 'package:flutter_web_dashboard/config.dart';

class RegistrationChart extends StatefulWidget {
  const RegistrationChart({super.key});

  @override
  State<RegistrationChart> createState() => _RegistrationChartState();
}

class _RegistrationChartState extends State<RegistrationChart> {
  bool showMonth = false;
  List<dynamic> registrationsDay = [];
  List<dynamic> registrationsMonth = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await DashboardService.fetchStats();
    setState(() {
      registrationsDay = stats['registrations_day'] ?? [];
      registrationsMonth = stats['registrations_month'] ?? [];
    });
  }

  // Helper: month number → name + year
  String formatMonth(String ym) {
    final parts = ym.split("-");
    final year = parts[0];
    final monthNum = int.parse(parts[1]);
    const monthNames = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return "${monthNames[monthNum - 1]} $year"; // 👉 Jan 2025
  }

  @override
  Widget build(BuildContext context) {
    final data = showMonth ? registrationsMonth : registrationsDay;

    final series = [
      charts.Series<Map<String, dynamic>, String>(
        id: 'Registrations',
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(active),
        domainFn: (Map<String, dynamic> reg, _) => showMonth
            ? formatMonth(reg['month'].toString())
            : reg['day'].toString(),
        measureFn: (Map<String, dynamic> reg, _) => reg['count'],
        data: data.cast<Map<String, dynamic>>(),
        labelAccessorFn: (Map<String, dynamic> reg, _) =>
            reg['count'].toString(),
      )
    ];

    return SingleChildScrollView(
      // vertical scroll for whole widget
      child: Column(
        children: [
          // Toggle buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => showMonth = false),
                child: Text(
                  "Day",
                  style: TextStyle(
                    fontWeight:
                        !showMonth ? FontWeight.bold : FontWeight.normal,
                    color: !showMonth ? active : Colors.black54,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => showMonth = true),
                child: Text(
                  "Month",
                  style: TextStyle(
                    fontWeight: showMonth ? FontWeight.bold : FontWeight.normal,
                    color: showMonth ? active : Colors.black54,
                  ),
                ),
              ),
            ],
          ),

          // Chart with InteractiveViewer for horizontal scroll
          SizedBox(
            height: 300,
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: false,
              child: SizedBox(
                width: (data.length * 80)
                    .toDouble(), // dynamic width per data point
                child: charts.BarChart(
                  series,
                  animate: true,
                  barRendererDecorator: charts.BarLabelDecorator<String>(),
                  domainAxis: const charts.OrdinalAxisSpec(
                    renderSpec: charts.SmallTickRendererSpec(
                      labelRotation: 60,
                      labelStyle: charts.TextStyleSpec(
                        fontSize: 12,
                        color: charts.MaterialPalette.black,
                      ),
                    ),
                  ),
                  primaryMeasureAxis: charts.NumericAxisSpec(
                    tickFormatterSpec:
                        charts.BasicNumericTickFormatterSpec((num? value) {
                      if (value == null) return '';
                      if (value >= 1000000)
                        return '${(value / 1000000).toStringAsFixed(1)}M';
                      if (value >= 1000)
                        return '${(value / 1000).toStringAsFixed(1)}K';
                      return value.toString();
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
