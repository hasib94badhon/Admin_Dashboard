import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/pages/overview/widgets/bar_chart.dart';
import 'package:flutter_web_dashboard/pages/overview/widgets/revenue_info.dart';
import 'package:flutter_web_dashboard/service_api/api_service.dart';
import 'package:flutter_web_dashboard/widgets/custom_text.dart';

class RevenueSectionSmall extends StatefulWidget {
  const RevenueSectionSmall({super.key});

  @override
  State<RevenueSectionSmall> createState() => _RevenueSectionSmallState();
}

class _RevenueSectionSmallState extends State<RevenueSectionSmall> {
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
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 20),
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
      child: Column(
        children: [
          // Chart Section
          SizedBox(
            height: 400, // Fixed height
            child: Column(
              children: [
                const CustomText(
                  text: "User Registration Graph",
                  size: 18,
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

          const SizedBox(height: 20),
          const Divider(color: lightGrey),
          const SizedBox(height: 20),

          // Statistics Section
          Column(
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
              const SizedBox(height: 20),
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
        ],
      ),
    );
  }
}
