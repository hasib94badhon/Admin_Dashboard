import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/pages/overview/widgets/info_card.dart';
import 'package:http/http.dart' as http;
<<<<<<< HEAD
import "package:flutter_web_dashboard/config.dart";
=======
import'package:flutter_web_dashboard/config.dart';
>>>>>>> 6c736d0932110085b7e83a0d2968fbbc51a94ad9

class OverviewCardsLargeScreen extends StatefulWidget {
  const OverviewCardsLargeScreen({super.key});

  @override
  State<OverviewCardsLargeScreen> createState() =>
      _OverviewCardsLargeScreenState();
}

class _OverviewCardsLargeScreenState extends State<OverviewCardsLargeScreen> {
  // Variables to store API data
  int userCount = 0;
  int catCount = 0;
  int postCount = 0;

  // Method to fetch data from API
  Future<void> fetchCounts() async {
    try {
      final response = await http.get(
        Uri.parse('$host/api/count'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userCount = data['user_count'];
          catCount = data['cat_count'];
          postCount = data['post_count'];
        });
      } else {
        throw Exception('Failed to load counts');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCounts(); // Fetch data when the widget initializes
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Row(
      children: [
        InfoCard(
          title: "Total Users",
          value: userCount.toString(),
          onTap: () {},
          topColor: Colors.orange,
        ),
        SizedBox(
          width: width / 64,
        ),
        InfoCard(
          title: "Total Categories",
          value: catCount.toString(),
          topColor: Colors.lightGreen,
          onTap: () {},
        ),
        SizedBox(
          width: width / 64,
        ),
        InfoCard(
          title: "Total Posts",
          value: postCount.toString(),
          topColor: Colors.redAccent,
          onTap: () {},
        ),
      ],
    );
  }
}
