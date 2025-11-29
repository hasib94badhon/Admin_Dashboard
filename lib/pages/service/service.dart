import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_web_dashboard/config.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  List<Map<String, dynamic>> services = [];
  Map<String, dynamic> summary = {};
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  String searchQuery = "";
  String sortBy = "";

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  Future<void> fetchServices() async {
    setState(() => isLoading = true);

    final url = Uri.parse(
        "$host/api/service-users/?page=$currentPage&search=$searchQuery&sort=$sortBy");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final resultBlock = data['results'];
      final newSummary = resultBlock['summary'];
      final newResults =
          List<Map<String, dynamic>>.from(resultBlock['results']);

      setState(() {
        summary = newSummary;
        services = newResults; // প্রতি পেজে নতুন ডাটা replace হবে
        hasMore = newResults.isNotEmpty;
      });
    } else {
      print("Error: ${response.statusCode}");
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Service Users")),
      body: Column(
        children: [
          // 🔎 Summary stats card
          if (summary.isNotEmpty)
            Card(
              margin: const EdgeInsets.all(8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem("Total",
                        summary['total_services'].toString(), Colors.blue),
                    _buildSummaryItem(
                        "Paid", summary['total_paid'].toString(), Colors.green),
                    _buildSummaryItem("Unpaid",
                        summary['total_unpaid'].toString(), Colors.red),
                    _buildSummaryItem("Categories",
                        summary['total_cat'].toString(), Colors.orange),
                  ],
                ),
              ),
            ),

          // 🔎 Search + Sort controls
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Search...",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (value) {
                      searchQuery = value;
                      currentPage = 1;
                      fetchServices();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: sortBy.isEmpty ? null : sortBy,
                  hint: const Text("Sort"),
                  items: const [
                    DropdownMenuItem(value: "cat", child: Text("Category")),
                    DropdownMenuItem(value: "recent", child: Text("Recent")),
                    DropdownMenuItem(
                        value: "subscriber", child: Text("Subscriber")),
                    DropdownMenuItem(
                        value: "location", child: Text("Location")),
                  ],
                  onChanged: (value) {
                    sortBy = value ?? "";
                    currentPage = 1;
                    fetchServices();
                  },
                ),
              ],
            ),
          ),

          // 🔎 DataTable2 with horizontal scroll
          Expanded(
            child: DataTable2(
              headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 1200,
              columns: const [
                DataColumn(
                    label: Text("Service ID",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Name",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Category",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Phone",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Subscriber Type",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Last Pay",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Service Created",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Location",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text("Location Updated At",
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: services.map((s) {
                final subscriberType = s['subscriber_type'] ?? "";
                final subscriberColor = subscriberType.toLowerCase() == "paid"
                    ? Colors.green
                    : Colors.red;

                return DataRow(cells: [
                  DataCell(_buildCellText(s['service_id'].toString())),
                  DataCell(_buildCellText(s['user_name'] ?? "")),
                  DataCell(_buildCellText(s['cat_name'] ?? "")),
                  DataCell(_buildCellText(s['phone'] ?? "")),
                  DataCell(Text(
                    subscriberType,
                    style: TextStyle(
                        color: subscriberColor, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )),
                  DataCell(_buildCellText(s['last_pay'] ?? "")),
                  DataCell(_buildCellText(s['date_time'] ?? "")),
                  DataCell(_buildCellText(s['location_address'] ?? "")),
                  DataCell(_buildCellText(s['location_updated_at'] ?? "")),
                ]);
              }).toList(),
            ),
          ),

          // 🔎 Pagination controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: currentPage > 1
                    ? () {
                        setState(() {
                          currentPage--;
                        });
                        fetchServices();
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
                        fetchServices();
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

  Widget _buildCellText(String text) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
    );
  }
}
