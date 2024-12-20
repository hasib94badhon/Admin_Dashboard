import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CatTable extends StatefulWidget {
  const CatTable({Key? key}) : super(key: key);

  @override
  State<CatTable> createState() => _CatTableState();
}

class _CatTableState extends State<CatTable> {
  Future<List<dynamic>> fetchData() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:1200/api/cat'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> toggleStatus(int categoryId) async {
    final url = Uri.parse('http://127.0.0.1:1200/toggle-status/$categoryId/');

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
    return FutureBuilder<List<dynamic>>(
      future: fetchData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data ?? [];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 800), // Adds constraints
            child: DataTable(
              columnSpacing: 12,
              dataRowHeight: 60,
              headingRowHeight: 40,
              horizontalMargin: 12,
              columns: const [
                DataColumn(
                  label: Text("Cat Name",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Cat Used',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('User Count',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Status',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
              rows: List<DataRow>.generate(
                data.length,
                (index) {
                  final cat = data[index];
                  return DataRow(cells: [
                    DataCell(Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            'https://aarambd.com/cat logo/${cat['cat_logo']}',
                          ),
                          radius: 20,
                          onBackgroundImageError: (_, __) {
                            // Placeholder for missing images
                          },
                        ),
                        const SizedBox(width: 10),
                        Text(cat['cat_name']),
                      ],
                    )),
                    DataCell(Text('${cat['cat_used']}',
                        style: const TextStyle(color: Colors.black))),
                    DataCell(Text('${cat['user_count']}',
                        style: const TextStyle(color: Colors.black))),
                    DataCell(
                      GestureDetector(
                        onTap: () async {
                          int categoryId = cat[
                              'cat_id']; // Assuming 'id' is present in your data
                          await toggleStatus(categoryId); // Call the API
                          // Reload or refresh the UI after the API call
                          setState(() {
                            cat['status'] =
                                !cat['status']; // Toggle status locally
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: cat['status'] == true
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Text(
                            cat['status'] == true ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: cat['status'] == true
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
