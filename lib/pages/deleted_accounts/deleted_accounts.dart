import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/service_api/api_service.dart';
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/constants/style.dart';

class DeletedAccountsPage extends StatefulWidget {
  const DeletedAccountsPage({super.key});

  @override
  State<DeletedAccountsPage> createState() => _DeletedAccountsPageState();
}

class _DeletedAccountsPageState extends State<DeletedAccountsPage> {
  String deletedByFilter = '';
  bool loading = false;
  int total = 0;
  List<dynamic> results = [];

  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController   = ScrollController();

  static const _filterOptions = [
    ('', 'All'),
    ('self', 'Self-deleted'),
    ('admin', 'Deleted by Admin'),
  ];

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await DeletedAccountsService.fetchDeletedAccounts(
        deletedBy: deletedByFilter,
        name:      _nameController.text.trim(),
        phone:     _phoneController.text.trim(),
      );
      setState(() {
        total   = data['total'] ?? 0;
        results = data['results'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
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
    _nameController.dispose();
    _phoneController.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
          child: Row(
            children: [
              const Icon(Icons.no_accounts_rounded, size: 22, color: errorColor),
              const SizedBox(width: 10),
              const Text('Deleted Accounts',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
              const Spacer(),
              if (total > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: errorColor.withValues(alpha: 0.3)),
                  ),
                  child: Text('${NumberFormatter.formatNumber(total)} deleted',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: errorColor)),
                ),
            ],
          ),
        ),

        // Search + filter card
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SearchField(
                      controller: _nameController,
                      hint: 'Name',
                      icon: Icons.person_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SearchField(
                      controller: _phoneController,
                      hint: 'Phone',
                      icon: Icons.phone_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.search_rounded,
                        size: 16, color: Colors.white),
                    label: const Text('Search',
                        style: TextStyle(fontSize: 13, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: _filterOptions.map((opt) {
                  final isSelected = deletedByFilter == opt.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => deletedByFilter = opt.$1);
                        _load();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor : background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSelected ? accentColor : borderColor),
                        ),
                        child: Text(opt.$2,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : textSecondary)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: accentColor))
                : results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.no_accounts_outlined,
                                size: 48, color: textMuted),
                            const SizedBox(height: 8),
                            const Text('No deleted accounts',
                                style: TextStyle(
                                    color: textSecondary, fontSize: 14)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Scrollbar(
                          controller: _horizontalController,
                          thumbVisibility: true,
                          thickness: 6,
                          radius: const Radius.circular(6),
                          child: SingleChildScrollView(
                            controller: _horizontalController,
                            scrollDirection: Axis.horizontal,
                            child: Scrollbar(
                              controller: _verticalController,
                              thumbVisibility: true,
                              thickness: 6,
                              radius: const Radius.circular(6),
                              child: SingleChildScrollView(
                                controller: _verticalController,
                                scrollDirection: Axis.vertical,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(minWidth: 1000),
                                  child: DataTable(
                                    columnSpacing: 20,
                                    dataRowMinHeight: 52,
                                    dataRowMaxHeight: 60,
                                    headingRowHeight: 44,
                                    horizontalMargin: 16,
                                    headingRowColor: WidgetStateProperty.all(
                                        background),
                                    dividerThickness: 1,
                                    columns: const [
                                      DataColumn(label: Text('User ID',    style: _hStyle)),
                                      DataColumn(label: Text('Name',       style: _hStyle)),
                                      DataColumn(label: Text('Phone',      style: _hStyle)),
                                      DataColumn(label: Text('Category',   style: _hStyle)),
                                      DataColumn(label: Text('Deleted By', style: _hStyle)),
                                      DataColumn(label: Text('Reason / Note', style: _hStyle)),
                                      DataColumn(label: Text('Delete Time',style: _hStyle)),
                                    ],
                                    rows: results.map((a) {
                                      final isSelf = a['deleted_by'] == 'self';
                                      return DataRow(cells: [
                                        DataCell(Text('${a['original_user_id']}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: textSecondary))),
                                        DataCell(Text('${a['name']}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: textPrimary),
                                            overflow: TextOverflow.ellipsis)),
                                        DataCell(Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.phone_rounded,
                                                size: 12, color: successColor),
                                            const SizedBox(width: 4),
                                            Text('${a['phone']}',
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: successColor)),
                                          ],
                                        )),
                                        DataCell(Text('${a['category_name']}',
                                            style: const TextStyle(
                                                fontSize: 13, color: textPrimary))),
                                        DataCell(_DeletedByBadge(isSelf: isSelf)),
                                        DataCell(
                                          Tooltip(
                                            message: '${a['reason']}',
                                            child: SizedBox(
                                              width: 220,
                                              child: Text('${a['reason']}',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: textSecondary),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(
                                            DateTimeFormatter.formatBdTime(
                                                a['delete_time'] ?? ''),
                                            style: const TextStyle(
                                                fontSize: 12, color: errorColor))),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ),
      ],
    );
  }
}

const _hStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: textSecondary,
  letterSpacing: 0.5,
);

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 13, color: textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        prefixIcon: Icon(icon, size: 16, color: textMuted),
        isDense: true,
        filled: true,
        fillColor: background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accentColor, width: 1.5)),
      ),
    );
  }
}

class _DeletedByBadge extends StatelessWidget {
  final bool isSelf;
  const _DeletedByBadge({required this.isSelf});

  @override
  Widget build(BuildContext context) {
    final color = isSelf ? warningColor : errorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isSelf ? 'SELF' : 'ADMIN',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5),
      ),
    );
  }
}
