import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/config.dart'; // এখানে $host আছে
import 'package:http/http.dart' as http;
import 'package:data_table_2/data_table_2.dart';
import 'package:google_fonts/google_fonts.dart';

class SubscriberPage extends StatefulWidget {
  const SubscriberPage({super.key});

  @override
  State<SubscriberPage> createState() => _SubscriberPageState();
}

class _SubscriberPageState extends State<SubscriberPage> {
  List<dynamic> subscribers = [];
  Map<String, dynamic> summary = {};
  int currentPage = 1;
  bool hasMore = true;
  bool isLoading = false;

  String searchQuery = "";
  String sortBy = "";

  final TextEditingController _searchController = TextEditingController();

  final List<Color> rowColors = [
    Colors.blue.shade50,
    Colors.orange.shade50,
    Colors.purple.shade50,
    Colors.teal.shade50,
    Colors.amber.shade50,
    Colors.indigo.shade50,
  ];

  Future<void> fetchSubscribers() async {
    setState(() => isLoading = true);

    final url = Uri.parse(
        "$host/api/subscriber-users/?page=$currentPage&search=$searchQuery&sort=$sortBy");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        summary = data['results']['summary'] ?? {};
        subscribers = data['results']['results'] ?? [];
        hasMore = data['next'] != null;
      });
    }
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    fetchSubscribers();
  }

  Widget _buildSummaryCard() {
    if (summary.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
                "Total", summary['total_subscribers'].toString(), Colors.blue),
            _buildSummaryItem("Service Paid",
                summary['service_paid'].toString(), Colors.green),
            _buildSummaryItem("Service Unpaid",
                summary['service_unpaid'].toString(), Colors.red),
            _buildSummaryItem(
                "Shop Paid", summary['shop_paid'].toString(), Colors.green),
            _buildSummaryItem(
                "Shop Unpaid", summary['shop_unpaid'].toString(), Colors.red),
            _buildSummaryItem("Categories",
                summary['total_categories'].toString(), Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Subscribers")),
      body: Column(
        children: [
          _buildSummaryCard(),

          // 🔎 Search + Sort controls
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                // Create Subscribers Button
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white70,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text("Add Eligible Subscribers"),
                      onPressed: () async {
                        setState(() => isLoading = true);

                        final url = Uri.parse("$host/api/create-subscribers/");
                        final response = await http.post(url);

                        setState(() => isLoading = false);

                        if (response.statusCode == 201) {
                          final data = json.decode(response.body);
                          final summary = data['summary'];

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "New: ${summary['total_new']} "
                                "(Service: ${summary['service_new']}, Shop: ${summary['shop_new']})",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );

                          // Refresh subscribers list
                          currentPage = 1;
                          fetchSubscribers();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to create subscribers"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText:
                              "Search by User ID / Name / Phone / Category / Service / Shop",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (value) {
                          searchQuery = value;
                          currentPage = 1;
                          fetchSubscribers();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: sortBy.isEmpty ? null : sortBy,
                      hint: const Text("Sort"),
                      items: const [
                        DropdownMenuItem(
                            value: "recent", child: Text("Recent")),
                        DropdownMenuItem(value: "type", child: Text("Type")),
                        DropdownMenuItem(value: "cat", child: Text("Category")),
                        DropdownMenuItem(
                            value: "service", child: Text("Service")),
                        DropdownMenuItem(value: "shop", child: Text("Shop")),
                      ],
                      onChanged: (value) {
                        sortBy = value ?? "";
                        currentPage = 1;
                        fetchSubscribers();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: DataTable2(
              headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
              columnSpacing: 30,
              horizontalMargin: 10,
              dataRowHeight: 85,
              minWidth: 1400,
              columns: const [
                DataColumn(
                    label: Text("User ID",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Name",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Phone",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Category",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Service ID",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Shop ID",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Type",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Last Pay",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Location",
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: List<DataRow>.generate(
                subscribers.length,
                (index) {
                  final s = subscribers[index];
                  final subscriberColor = (s['type']?.toLowerCase() == "paid")
                      ? Colors.green
                      : Colors.red;

                  return DataRow(
                    color: MaterialStateProperty.all(
                        rowColors[index % rowColors.length]),
                    cells: [
                      DataCell(_buildCellText(s['user_id'].toString())),
                      DataCell(_buildCellText(s['user_name'] ?? "")),
                      DataCell(_buildCellText(s['phone'] ?? "")),
                      DataCell(_buildCellText(s['category'] ?? "")),
                      DataCell(_buildCellText(s['service_id'].toString())),
                      DataCell(_buildCellText(s['shop_id'].toString())),
                      DataCell(Text(
                        s['type'] ?? "",
                        style: TextStyle(
                            color: subscriberColor,
                            fontWeight: FontWeight.bold),
                      )),
                      DataCell(_buildCellText(s['last_pay'] ?? "")),
                      DataCell(_buildCellText(s['location_address'] ?? "")),
                    ],
                  );
                },
              ),
            ),
          ),

          // Pagination controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: currentPage > 1
                    ? () {
                        setState(() {
                          currentPage--;
                        });
                        fetchSubscribers();
                      }
                    : null,
                child: const Text("Prev"),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: hasMore
                    ? () {
                        setState(() {
                          currentPage++;
                        });
                        fetchSubscribers();
                      }
                    : null,
                child: const Text("Next"),
              ),
            ],
          ),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

Widget _buildCellText(String text) {
  return Text(
    text,
    style: GoogleFonts.notoSansBengali(
      fontSize: 14,
    ),
    maxLines: 5,
    textAlign: TextAlign.center,
  );
}
