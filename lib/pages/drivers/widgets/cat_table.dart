import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CatTable extends StatelessWidget {
  const CatTable({Key? key}) : super(key: key);

  Future<List<dynamic>> fetchData() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:1200/api/cat'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
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
                    DataCell(Container(
                      decoration: BoxDecoration(
                        color: cat['cat_used'] > 50
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Text(
                        cat['cat_used'] > 50 ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color:
                              cat['cat_used'] > 50 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
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
