import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/constants/style.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  List<Map<String, dynamic>> shops = [];
  Map<String, dynamic> summary = {};
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  String searchQuery = "";
  String sortBy = "";

  final TextEditingController _searchController = TextEditingController();

  static const _sortOptions = [
    ('', 'All'),
    ('recent', 'Recent'),
    ('cat', 'Category'),
    ('subscriber', 'Subscriber'),
    ('location', 'Location'),
  ];

  @override
  void initState() {
    super.initState();
    fetchShops();
  }

  Future<void> fetchShops() async {
    setState(() => isLoading = true);
    final url = Uri.parse(
        "$host/api/shop-users/?page=$currentPage&search=$searchQuery&sort=$sortBy");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final resultBlock = data['results'];
      final newSummary = resultBlock['summary'];
      final newResults =
          List<Map<String, dynamic>>.from(resultBlock['results']);
      setState(() {
        summary = newSummary;
        shops = newResults;
        hasMore = newResults.isNotEmpty;
      });
    }
    setState(() => isLoading = false);
  }

  void _copyRowData(Map<String, dynamic> row) {
    final buffer = StringBuffer();
    row.forEach((key, value) => buffer.writeln("$key: ${value ?? ''}"));
    Clipboard.setData(ClipboardData(text: buffer.toString()));
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
              const Icon(Icons.storefront_rounded,
                  size: 22, color: accentColor),
              const SizedBox(width: 10),
              const Text('Shop Users',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
              const Spacer(),
              if (summary.isNotEmpty) ...[
                _SummaryChip(
                    label: 'Total',
                    value: summary['total_shops']?.toString() ?? '0',
                    color: accentColor),
                const SizedBox(width: 8),
                _SummaryChip(
                    label: 'Paid',
                    value: summary['total_paid']?.toString() ?? '0',
                    color: successColor),
                const SizedBox(width: 8),
                _SummaryChip(
                    label: 'Unpaid',
                    value: summary['total_unpaid']?.toString() ?? '0',
                    color: errorColor),
                const SizedBox(width: 8),
                _SummaryChip(
                    label: 'Categories',
                    value: summary['total_cat']?.toString() ?? '0',
                    color: warningColor),
              ],
            ],
          ),
        ),

        // Search + Sort card
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
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
                    child: TextField(
                      controller: _searchController,
                      style:
                          const TextStyle(fontSize: 13, color: textPrimary),
                      onSubmitted: (value) {
                        searchQuery = value;
                        currentPage = 1;
                        fetchShops();
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Search by Shop ID / Name / Phone / Category / Location',
                        hintStyle:
                            const TextStyle(color: textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 16, color: textMuted),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    size: 16, color: textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  searchQuery = '';
                                  currentPage = 1;
                                  fetchShops();
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 11),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: accentColor, width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      searchQuery = _searchController.text.trim();
                      currentPage = 1;
                      fetchShops();
                    },
                    icon: const Icon(Icons.search_rounded,
                        size: 16, color: Colors.white),
                    label: const Text('Search',
                        style:
                            TextStyle(fontSize: 13, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: _sortOptions.map((opt) {
                  final isSelected = sortBy == opt.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => sortBy = opt.$1);
                        currentPage = 1;
                        fetchShops();
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
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: accentColor))
                : shops.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storefront_outlined,
                                size: 48, color: textMuted),
                            const SizedBox(height: 8),
                            const Text('No shop users found',
                                style: TextStyle(
                                    color: textSecondary, fontSize: 14)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DataTable2(
                          headingRowColor:
                              WidgetStateProperty.all(background),
                          columnSpacing: 20,
                          horizontalMargin: 16,
                          dataRowHeight: 56,
                          headingRowHeight: 44,
                          minWidth: 1400,
                          dividerThickness: 1,
                          columns: const [
                            DataColumn2(
                                label: Text('Shop ID', style: _hStyle),
                                fixedWidth: 80),
                            DataColumn2(
                                label: Text('Name', style: _hStyle),
                                size: ColumnSize.L),
                            DataColumn2(
                                label: Text('Category', style: _hStyle),
                                size: ColumnSize.M),
                            DataColumn2(
                                label: Text('Phone', style: _hStyle),
                                fixedWidth: 120),
                            DataColumn2(
                                label:
                                    Text('Subscriber', style: _hStyle),
                                fixedWidth: 100),
                            DataColumn2(
                                label: Text('Last Pay', style: _hStyle),
                                size: ColumnSize.M),
                            DataColumn2(
                                label:
                                    Text('Created At', style: _hStyle),
                                size: ColumnSize.M),
                            DataColumn2(
                                label: Text('Location', style: _hStyle),
                                size: ColumnSize.L),
                            DataColumn2(
                                label: Text('Loc. Updated', style: _hStyle),
                                size: ColumnSize.M),
                            DataColumn2(
                                label: Text('User ID', style: _hStyle),
                                fixedWidth: 80),
                            DataColumn2(
                                label: Text('Copy', style: _hStyle),
                                fixedWidth: 60),
                          ],
                          rows: shops.map((s) {
                            final subType = s['subscriber_type'] ?? '';
                            final isPaid =
                                subType.toLowerCase() == 'paid';
                            return DataRow2(
                              cells: [
                                DataCell(Text(
                                    '${s['shop_id']}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary))),
                                DataCell(Text('${s['user_name']}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: textPrimary))),
                                DataCell(Text(s['cat_name'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: textPrimary))),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone_rounded,
                                        size: 12, color: successColor),
                                    const SizedBox(width: 4),
                                    Text(s['phone'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: successColor)),
                                  ],
                                )),
                                DataCell(_SubBadge(isPaid: isPaid)),
                                DataCell(Text(
                                    ServiceShopDateTimeFormatter
                                        .formatDateTime(s['last_pay'] ?? ''),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: textSecondary))),
                                DataCell(Text(
                                    ServiceShopDateTimeFormatter
                                        .formatDateTime(
                                            s['date_time'] ?? ''),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: textSecondary))),
                                DataCell(Text(
                                    s['location_address'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: textSecondary))),
                                DataCell(Text(
                                    ServiceShopDateTimeFormatter
                                        .formatDateTime(
                                            s['location_updated_at'] ?? ''),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: textSecondary))),
                                DataCell(Text('${s['user_id']}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: textSecondary))),
                                DataCell(IconButton(
                                  icon: const Icon(Icons.copy_rounded,
                                      size: 16, color: accentColor),
                                  tooltip: 'Copy row data',
                                  onPressed: () {
                                    _copyRowData(s);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Copied to clipboard')));
                                  },
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ),

        // Pagination
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PageButton(
                label: 'Prev',
                icon: Icons.chevron_left_rounded,
                enabled: currentPage > 1,
                onTap: () {
                  setState(() => currentPage--);
                  fetchShops();
                },
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: accentLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Page $currentPage',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentColor)),
              ),
              _PageButton(
                label: 'Next',
                icon: Icons.chevron_right_rounded,
                iconAfter: true,
                enabled: hasMore,
                onTap: () {
                  setState(() => currentPage++);
                  fetchShops();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

const _hStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: textSecondary,
  letterSpacing: 0.4,
);

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

class _SubBadge extends StatelessWidget {
  final bool isPaid;
  const _SubBadge({required this.isPaid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPaid
            ? successColor.withValues(alpha: 0.1)
            : errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPaid
              ? successColor.withValues(alpha: 0.3)
              : errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        isPaid ? 'PAID' : 'UNPAID',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isPaid ? successColor : errorColor,
            letterSpacing: 0.4),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool iconAfter;
  final VoidCallback onTap;

  const _PageButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.iconAfter = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? surface : background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: enabled
                  ? borderColor
                  : borderColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconAfter
              ? [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: enabled ? textPrimary : textMuted)),
                  const SizedBox(width: 4),
                  Icon(icon,
                      size: 18,
                      color: enabled ? textPrimary : textMuted),
                ]
              : [
                  Icon(icon,
                      size: 18,
                      color: enabled ? textPrimary : textMuted),
                  const SizedBox(width: 4),
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: enabled ? textPrimary : textMuted)),
                ],
        ),
      ),
    );
  }
}
