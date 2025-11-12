import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/service_api/api_service.dart';
import 'package:flutter_web_dashboard/config.dart';

class DeactivationPage extends StatefulWidget {
  const DeactivationPage({super.key});

  @override
  State<DeactivationPage> createState() => _DeactivationPageState();
}

class _DeactivationPageState extends State<DeactivationPage> {
  String sort = 'most_recent';
  bool loading = false;
  int total = 0;
  List<dynamic> results = [];

  final _userIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // ✅ Add scroll controllers
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await DeactivationService.fetchDeactivatedUsers(
        sort: sort,
        userId: _userIdController.text.trim(),
        name: _nameController.text.trim(),
        mobile: _phoneController.text.trim(),
      );
      setState(() {
        total = data['total'] ?? 0;
        results = data['results'] ?? [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Total count
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12, top: 55),
          decoration: BoxDecoration(
            color: Colors.blueGrey[50],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Total Deactivated Users: ${NumberFormatter.formatNumber(total)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(221, 128, 53, 3),
              ),
            ),
          ),
        ),

        // Sorting buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Most Recent'),
              selected: sort == 'most_recent',
              onSelected: (_) {
                setState(() => sort = 'most_recent');
                _load();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Most Called'),
              selected: sort == 'most_called',
              onSelected: (_) {
                setState(() => sort = 'most_called');
                _load();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Most Viewed'),
              selected: sort == 'most_viewed',
              onSelected: (_) {
                setState(() => sort = 'most_viewed');
                _load();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.search),
                label: const Text('Search'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ✅ Scrollable table section
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : results.isEmpty
                  ? const Center(child: Text('No deactivations found'))
                  : Scrollbar(
                      controller: _horizontalController,
                      thumbVisibility: true,
                      thickness: 10,
                      radius: const Radius.circular(10),
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Scrollbar(
                          controller: _verticalController,
                          thumbVisibility: true,
                          thickness: 10,
                          radius: const Radius.circular(10),
                          child: SingleChildScrollView(
                            controller: _verticalController,
                            scrollDirection: Axis.vertical,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 1200, // 👈 ensures horizontal scroll
                              ),
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(
                                  Colors.blueGrey[100],
                                ),
                                columns: const [
                                  DataColumn(label: Text('User ID')),
                                  DataColumn(label: Text('Service ID')),
                                  DataColumn(label: Text('Shop ID')),
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Phone')),
                                  DataColumn(label: Text('Category')),
                                  DataColumn(label: Text('Type')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Called')),
                                  DataColumn(label: Text('Viewed')),
                                  DataColumn(label: Text('Posts')),
                                  DataColumn(label: Text('Deactivated At')),
                                  DataColumn(label: Text('Reason')),
                                  DataColumn(label: Text('Email')),
                                ],
                                rows: results.map((u) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text('${u['user_id']}')),
                                      DataCell(Text('${u['service_id']}')),
                                      DataCell(Text('${u['shop_id']}')),
                                      DataCell(Text(
                                        '${u['name']}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                      DataCell(Text('${u['phone']}')),
                                      DataCell(Text('${u['category_name']}')),
                                      DataCell(Text('${u['user_type']}')),
                                      DataCell(Text('${u['status']}')),
                                      DataCell(Text(
                                        NumberFormatter.formatNumber(
                                            u['user_called'] ?? 0),
                                      )),
                                      DataCell(Text(
                                        NumberFormatter.formatNumber(
                                            u['user_viewed'] ?? 0),
                                      )),
                                      DataCell(Text(
                                        NumberFormatter.formatNumber(
                                            u['user_total_post'] ?? 0),
                                      )),
                                      DataCell(Text(
                                        DateTimeFormatter.formatBdTime(
                                            u['deactivated_at'] ?? ''),
                                      )),
                                      DataCell(Text(
                                        '${u['deactivation_reason']}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                      DataCell(Text('${u['email']}')),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
        )
      ],
    );
  }
}
