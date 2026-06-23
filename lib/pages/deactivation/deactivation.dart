import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/service_api/api_service.dart';
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/constants/style.dart';

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
  final _nameController   = TextEditingController();
  final _phoneController  = TextEditingController();

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController   = ScrollController();

  static const _sortOptions = [
    ('most_recent', 'Most Recent'),
    ('most_called', 'Most Called'),
    ('most_viewed', 'Most Viewed'),
  ];

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await DeactivationService.fetchDeactivatedUsers(
        sort:     sort,
        userId:   _userIdController.text.trim(),
        name:     _nameController.text.trim(),
        mobile:   _phoneController.text.trim(),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
          child: Row(
            children: [
              const Icon(Icons.person_off_rounded, size: 22, color: errorColor),
              const SizedBox(width: 10),
              const Text('Deactivated Users',
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: errorColor, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('${NumberFormatter.formatNumber(total)} deactivated',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: errorColor)),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Search + sort card
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
              // Search fields row
              Row(
                children: [
                  Expanded(
                    child: _SearchField(
                      controller: _userIdController,
                      hint: 'User ID',
                      icon: Icons.badge_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
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
              // Sort chips
              Row(
                children: _sortOptions.map((opt) {
                  final isSelected = sort == opt.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => sort = opt.$1);
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
                            Icon(Icons.person_off_outlined,
                                size: 48, color: textMuted),
                            const SizedBox(height: 8),
                            const Text('No deactivated users found',
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
                                      const BoxConstraints(minWidth: 1300),
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
                                      DataColumn(label: Text('User ID',   style: _hStyle)),
                                      DataColumn(label: Text('Name',      style: _hStyle)),
                                      DataColumn(label: Text('Phone',     style: _hStyle)),
                                      DataColumn(label: Text('Category',  style: _hStyle)),
                                      DataColumn(label: Text('Type',      style: _hStyle)),
                                      DataColumn(label: Text('Called',    style: _hStyle), numeric: true),
                                      DataColumn(label: Text('Viewed',    style: _hStyle), numeric: true),
                                      DataColumn(label: Text('Posts',     style: _hStyle), numeric: true),
                                      DataColumn(label: Text('Service ID',style: _hStyle)),
                                      DataColumn(label: Text('Shop ID',   style: _hStyle)),
                                      DataColumn(label: Text('Deactivated At', style: _hStyle)),
                                      DataColumn(label: Text('Reason',    style: _hStyle)),
                                      DataColumn(label: Text('Email',     style: _hStyle)),
                                    ],
                                    rows: results.map((u) {
                                      final isPaid = u['user_type'] == true ||
                                          u['user_type'] == 'true' ||
                                          u['user_type'] == 'PAID';
                                      return DataRow(cells: [
                                        DataCell(Text('${u['user_id']}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: textSecondary))),
                                        DataCell(Text('${u['name']}',
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
                                            Text('${u['phone']}',
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: successColor)),
                                          ],
                                        )),
                                        DataCell(Text('${u['category_name']}',
                                            style: const TextStyle(
                                                fontSize: 13, color: textPrimary))),
                                        DataCell(_TypeBadge(isPaid: isPaid)),
                                        DataCell(Text(
                                            NumberFormatter.formatNumber(
                                                u['user_called'] ?? 0),
                                            style: const TextStyle(
                                                fontSize: 13, color: textPrimary))),
                                        DataCell(Text(
                                            NumberFormatter.formatNumber(
                                                u['user_viewed'] ?? 0),
                                            style: const TextStyle(
                                                fontSize: 13, color: textPrimary))),
                                        DataCell(Text(
                                            NumberFormatter.formatNumber(
                                                u['user_total_post'] ?? 0),
                                            style: const TextStyle(
                                                fontSize: 13, color: textPrimary))),
                                        DataCell(Text('${u['service_id']}',
                                            style: const TextStyle(
                                                fontSize: 12, color: textSecondary))),
                                        DataCell(Text('${u['shop_id']}',
                                            style: const TextStyle(
                                                fontSize: 12, color: textSecondary))),
                                        DataCell(Text(
                                            DateTimeFormatter.formatBdTime(
                                                u['deactivated_at'] ?? ''),
                                            style: const TextStyle(
                                                fontSize: 12, color: errorColor))),
                                        DataCell(
                                          Tooltip(
                                            message: '${u['deactivation_reason']}',
                                            child: SizedBox(
                                              width: 140,
                                              child: Text('${u['deactivation_reason']}',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: textSecondary),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text('${u['email']}',
                                            style: const TextStyle(
                                                fontSize: 12, color: textSecondary))),
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

class _TypeBadge extends StatelessWidget {
  final bool isPaid;
  const _TypeBadge({required this.isPaid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPaid
            ? accentColor.withValues(alpha: 0.1)
            : textMuted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPaid
              ? accentColor.withValues(alpha: 0.3)
              : textMuted.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        isPaid ? 'PAID' : 'FREE',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isPaid ? accentColor : textSecondary,
            letterSpacing: 0.5),
      ),
    );
  }
}
