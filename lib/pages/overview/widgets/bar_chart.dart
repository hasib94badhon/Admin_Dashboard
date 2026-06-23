import 'dart:math' show max;
import 'package:fl_chart/fl_chart.dart';
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
  List<Map<String, dynamic>> registrationsDay = [];
  List<Map<String, dynamic>> registrationsMonth = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await DashboardService.fetchStats();
    setState(() {
      registrationsDay =
          List<Map<String, dynamic>>.from(stats['registrations_day'] ?? []);
      registrationsMonth =
          List<Map<String, dynamic>>.from(stats['registrations_month'] ?? []);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _label(Map<String, dynamic> entry) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (showMonth) {
      final parts = entry['month'].toString().split('-');
      return '${months[int.parse(parts[1]) - 1]}\n${parts[0]}';
    } else {
      final parts = entry['day'].toString().split('-');
      return '${parts[2]}\n${months[int.parse(parts[1]) - 1]}';
    }
  }

  String _formatValue(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final data = showMonth ? registrationsMonth : registrationsDay;
    const double groupW = 72;
    final chartWidth = max(500.0, data.length * groupW);
    final maxY = data.isEmpty
        ? 10.0
        : data
                .map((e) => (e['count'] as num).toDouble())
                .reduce(max) *
            1.25;

    final groups = data.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: (e.value['count'] as num).toDouble(),
            color: active,
            width: 26,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => showMonth = false),
              child: Text(
                'Day',
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
                'Month',
                style: TextStyle(
                  fontWeight:
                      showMonth ? FontWeight.bold : FontWeight.normal,
                  color: showMonth ? active : Colors.black54,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Flexible(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                height: 360,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8),
                  child: BarChart(
                    BarChartData(
                      maxY: maxY,
                      barGroups: groups,
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) =>
                              Colors.blueGrey.shade700,
                          getTooltipItem: (group, gi, rod, _) =>
                              BarTooltipItem(
                            '${_label(data[gi])}\n${_formatValue(rod.toY)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 52,
                            getTitlesWidget: (value, _) {
                              final i = value.toInt();
                              if (i < 0 || i >= data.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(
                                    _label(data[i]),
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.black54),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.max || value == 0) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                _formatValue(value),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.black54),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.grey.withValues(alpha: 0.18),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          showMonth
              ? 'Showing ${data.length} months — scroll horizontally'
              : 'Showing ${data.length} days — scroll horizontally',
          textAlign: TextAlign.center,
          style: TextStyle(color: lightGrey, fontSize: 12),
        ),
      ],
    );
  }
}
