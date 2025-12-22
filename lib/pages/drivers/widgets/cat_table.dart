import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_web_dashboard/config.dart';

class CatTable extends StatefulWidget {
  const CatTable({Key? key}) : super(key: key);

  @override
  State<CatTable> createState() => _CatTableState();
}

class _CatTableState extends State<CatTable> {
  String searchQuery = "";
  String sortBy = "cat_used"; // default sort
  List<String> sortOptions = [
    'user_count',
    'cat_used',
    'status',
    'yes_service',
    'yes_shop'
  ];

  Future<List<dynamic>> fetchData() async {
    final response = await http
        .get(Uri.parse('$host/api/cat?search=$searchQuery&sort=$sortBy'));
    if (response.statusCode == 200) {
      final body = response.body;
      // guard: sometimes API returns null/empty body
      if (body.isEmpty) return [];
      return json.decode(body) as List<dynamic>;
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  Future<void> toggleStatus(int categoryId) async {
    final url = Uri.parse('$host/api/toggle-status/$categoryId/');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Status updated: ${data['status']}');
      } else {
        print('Failed to toggle status: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // If ancestor gives finite height -> use it. Otherwise fallback to screen height.
      final screenHeight = MediaQuery.of(context).size.height;
      final availableHeight =
          constraints.maxHeight.isFinite ? constraints.maxHeight : screenHeight;

      // Reserve space for search+sort + padding. Ensure a reasonable min / max height.
      double tableHeight = math.max(300.0, availableHeight - 160.0);
      // Don't exceed available height
      if (tableHeight > availableHeight) tableHeight = availableHeight;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search + Sort Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
            child: Row(
              children: [
                // Search Field
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      // Small debounce could be added later to reduce API calls
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    onSubmitted: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Sort Dropdown
                DropdownButton<String>(
                  value: sortBy,
                  items: sortOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option[0] + option.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        sortBy = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Table area with constrained height
          SizedBox(
            height: tableHeight,
            child: FutureBuilder<List<dynamic>>(
              future: fetchData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red)));
                }

                final data = snapshot.data ?? [];

                if (data.isEmpty) {
                  return const Center(child: Text('No Categories Found'));
                }

                // Build DataTable rows safely (guarding nulls)
                final rows = data.map<DataRow>((raw) {
                  final cat = raw ?? {};
                  final catName = (cat['cat_name'] ?? '') as String;
                  final catLogo = (cat['cat_logo'] ?? '') as String;
                  final catId = (cat['cat_id'] ?? 0) as int;
                  final catUsed = cat['cat_used'] ?? 0;
                  final userCount = cat['user_count'] ?? 0;
                  final status = (cat['status'] ?? false) as bool;

                  return DataRow(cells: [
                    DataCell(Row(children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: catLogo.isNotEmpty
                            ? NetworkImage(
                                Uri.encodeFull(
                                    'https://aarambd.com/cat%20logo/$catLogo'),
                              )
                            : null,
                        child:
                            catLogo.isEmpty ? const Icon(Icons.category) : null,
                        onBackgroundImageError: (_, __) {
                          // show default icon if load fails
                        },
                      ),
                      const SizedBox(width: 10),
                      Text(catName),
                    ])),
                    DataCell(Text(NumberFormatter.formatNumber(catUsed),
                        style: const TextStyle(color: Colors.black))),
                    DataCell(Text(NumberFormatter.formatNumber(userCount),
                        style: const TextStyle(color: Colors.black))),
                    DataCell(
                      GestureDetector(
                        onTap: () async {
                          await toggleStatus(catId);
                          // After toggling server-side, refresh the table:
                          setState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: status
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Text(
                            status ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: status ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]);
                }).toList();

                return Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 800),
                        child: DataTable(
                          columnSpacing: 12,
                          dataRowHeight: 60,
                          headingRowHeight: 40,
                          horizontalMargin: 12,
                          columns: const [
                            DataColumn(
                              label: Text("Cat Name",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Cat Used',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('User Count',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Status',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                          rows: rows,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}
