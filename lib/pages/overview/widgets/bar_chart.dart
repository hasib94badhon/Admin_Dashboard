import 'dart:math';
import 'package:charts_flutter_new/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/service_api/api_service.dart';

class RegistrationChart extends StatefulWidget {
  const RegistrationChart({super.key});

  @override
  State<RegistrationChart> createState() => _RegistrationChartState();
}

class _RegistrationChartState extends State<RegistrationChart> {
  bool showMonth = false;
  List<dynamic> registrationsDay = [];
  List<dynamic> registrationsMonth = [];

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

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

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

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
    return "${monthNames[monthNum - 1]} $year";
  }

  String formatDay(String dateStr) {
    try {
      final parts = dateStr.split("-");
      final year = parts[0];
      final monthNum = int.parse(parts[1]);
      final day = parts[2];
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
      return "$day ${monthNames[monthNum - 1]} $year";
    } catch (e) {
      return dateStr;
    }
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
            : formatDay(reg['day'].toString()),
        measureFn: (Map<String, dynamic> reg, _) => reg['count'],
        data: data.cast<Map<String, dynamic>>(),
        labelAccessorFn: (Map<String, dynamic> reg, _) =>
            reg['count'].toString(),
      )
    ];

    const double perBarWidth = 100;
    const double baseHeight = 400;
    final chartWidth = max(600.0, data.length * perBarWidth);
    final chartHeight = baseHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toggle Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => showMonth = false),
              child: Text(
                "Day",
                style: TextStyle(
                  fontWeight: !showMonth ? FontWeight.bold : FontWeight.normal,
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
        const SizedBox(height: 10),

        // Scrollable Chart Area
        Flexible(
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: chartWidth,
                  minHeight: chartHeight,
                ),
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      width: chartWidth,
                      height: chartHeight,
                      child: charts.BarChart(
                        series,
                        animate: true,
                        vertical: true,
                        barRendererDecorator: charts.BarLabelDecorator<String>(
                          labelPosition: charts.BarLabelPosition.auto,
                        ),
                        domainAxis: charts.OrdinalAxisSpec(
                          renderSpec: charts.SmallTickRendererSpec(
                            labelRotation: 60,
                            labelStyle: charts.TextStyleSpec(
                              fontSize: 11,
                              color: charts.MaterialPalette.black,
                            ),
                          ),
                        ),
                        primaryMeasureAxis: charts.NumericAxisSpec(
                          tickFormatterSpec:
                              charts.BasicNumericTickFormatterSpec(
                            (num? value) {
                              if (value == null) return '';
                              if (value >= 1000000)
                                return '${(value / 1000000).toStringAsFixed(1)}M';
                              if (value >= 1000)
                                return '${(value / 1000).toStringAsFixed(1)}K';
                              return value.toString();
                            },
                          ),
                        ),
                        behaviors: [
                          charts.PanAndZoomBehavior(),
                          charts.ChartTitle(
                            showMonth
                                ? 'Monthly Registrations'
                                : 'Daily Registrations',
                            behaviorPosition: charts.BehaviorPosition.top,
                            titleStyleSpec: charts.TextStyleSpec(fontSize: 14),
                            titleOutsideJustification:
                                charts.OutsideJustification.middleDrawArea,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
        Text(
          showMonth
              ? 'Showing ${data.length} months — scroll horizontally or vertically'
              : 'Showing ${data.length} days — scroll horizontally or vertically',
          textAlign: TextAlign.center,
          style: TextStyle(color: lightGrey, fontSize: 12),
        ),
      ],
    );
  }
}
