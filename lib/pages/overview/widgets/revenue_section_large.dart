import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/pages/overview/widgets/bar_chart.dart';
import 'package:flutter_web_dashboard/pages/overview/widgets/revenue_info.dart';
import 'package:flutter_web_dashboard/service/dashboard_service.dart';
import 'package:flutter_web_dashboard/widgets/custom_text.dart';

class RevenueSectionLarge extends StatefulWidget {
  const RevenueSectionLarge({super.key});

  @override
  State<RevenueSectionLarge> createState() => _RevenueSectionLargeState();
}

class _RevenueSectionLargeState extends State<RevenueSectionLarge> {
  Map<String, dynamic>? stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final data = await DashboardService.fetchStats();
    setState(() {
      stats = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              offset: const Offset(0, 6),
              color: lightGrey.withOpacity(.1),
              blurRadius: 12)
        ],
        border: Border.all(color: lightGrey, width: .5),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 500, // Give it enough height
              child: Column(
                children: [
                  const CustomText(
                    text: "User Registration Graph",
                    size: 20,
                    weight: FontWeight.bold,
                    color: lightGrey,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: RegistrationChart(),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 400,
            color: lightGrey,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const CustomText(
                      text: "Posts Statistics",
                      size: 16,
                      weight: FontWeight.bold,
                      color: lightGrey,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        RevenueInfo(
                          title: "Today",
                          amount: stats!['today_posts'].toString(),
                        ),
                        RevenueInfo(
                          title: "Last 7 days",
                          amount: stats!['last7_posts'].toString(),
                        ),
                        RevenueInfo(
                          title: "Last 30 days",
                          amount: stats!['last30_posts'].toString(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Column(
                  children: [
                    const CustomText(
                      text: "Login Statistics",
                      size: 16,
                      weight: FontWeight.bold,
                      color: lightGrey,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        RevenueInfo(
                          title: "Today",
                          amount: stats!['today_logins'].toString(),
                        ),
                        RevenueInfo(
                          title: "Last 7 days",
                          amount: stats!['last7_logins'].toString(),
                        ),
                        RevenueInfo(
                          title: "Last 30 days",
                          amount: stats!['last30_logins'].toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
