import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import'package:flutter_web_dashboard/config.dart';

// CustomText widget is assumed to be defined elsewhere in your project.

class AvailableDriversTable extends StatelessWidget {
  const AvailableDriversTable({Key? key}) : super(key: key);

  // Fetch data from the API
  Future<List<dynamic>> fetchData() async {
    final response =
        await http.get(Uri.parse('$host/api/users'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange[100]!,
        border: Border.all(color: Colors.grey.withOpacity(.4), width: .5),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 6),
            color: Colors.grey.withOpacity(.1),
            blurRadius: 12,
          )
        ],
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              SizedBox(width: 10),
              Text(
                "Available Users",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<dynamic>>(
            future: fetchData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text("Error: ${snapshot.error}"),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text("No data available"),
                );
              } else {
                // Use the API data to generate table rows
                final data = snapshot.data!;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context)
                          .size
                          .width, // Minimum width equal to the screen width
                    ),
                    child: DataTable(
                      columnSpacing:
                          12, // Reduced column spacing for tighter columns
                      dataRowHeight: 40, // Adjusted row height
                      headingRowHeight: 50, // Adjusted header row height
                      border: TableBorder.all(
                          color: Colors.grey.shade300,
                          width: 1), // Added table border
                      columns: const [
                        DataColumn(
                          label: Text(
                            "User ID",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Name",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Mobile Number",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Category",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "User Address",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Status",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: data.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(Text(item['user_id'].toString())),
                            DataCell(Text(item['name'].toString())),
                            DataCell(Text(item['phone'].toString())),
                            DataCell(Text(item['cat'].toString())),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.deepOrange, size: 18),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      item['location'] ?? 'Unknown',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.orange, width: .5),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: const Text(
                                  "Play / Pause / Delete",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
