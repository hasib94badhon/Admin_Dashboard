import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/constants/style.dart';

class CatTable extends StatefulWidget {
  const CatTable({Key? key}) : super(key: key);

  @override
  State<CatTable> createState() => _CatTableState();
}

class _CatTableState extends State<CatTable> {
  String searchQuery = "";
  String sortBy = "cat_used";
  final TextEditingController _searchController = TextEditingController();

  static const _sortOptions = [
    ('cat_used', 'Most Used'),
    ('user_count', 'User Count'),
    ('status', 'Status'),
    ('yes_service', 'Service'),
    ('yes_shop', 'Shop'),
  ];

  Future<List<dynamic>> fetchData() async {
    final response = await http
        .get(Uri.parse('$host/api/cat?search=$searchQuery&sort=$sortBy'));
    if (response.statusCode == 200) {
      final body = response.body;
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
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page header
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
          child: Row(
            children: [
              const Icon(Icons.category_rounded, size: 22, color: accentColor),
              const SizedBox(width: 10),
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Search + Sort card
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              // Search
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    hintStyle:
                        const TextStyle(color: textMuted, fontSize: 14),
                    prefixIcon:
                        const Icon(Icons.search, color: textMuted, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => searchQuery = "");
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: background,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: accentColor, width: 1.5),
                    ),
                  ),
                  onChanged: (v) => setState(() => searchQuery = v),
                  onSubmitted: (v) => setState(() => searchQuery = v),
                ),
              ),
              const SizedBox(width: 12),
              // Sort dropdown
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: sortBy,
                    icon: const Icon(Icons.unfold_more_rounded,
                        size: 18, color: textSecondary),
                    style: const TextStyle(
                        fontSize: 13, color: textPrimary),
                    items: _sortOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt.$1,
                        child: Text(opt.$2),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => sortBy = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Table card
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
                    offset: const Offset(0, 2)),
              ],
            ),
            child: FutureBuilder<List<dynamic>>(
              future: fetchData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: accentColor));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: errorColor, size: 40),
                        const SizedBox(height: 8),
                        Text('Failed to load categories',
                            style: const TextStyle(
                                color: textSecondary, fontSize: 14)),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry'),
                          style: TextButton.styleFrom(
                              foregroundColor: accentColor),
                        ),
                      ],
                    ),
                  );
                }

                final data = snapshot.data ?? [];

                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category_outlined,
                            size: 48, color: textMuted),
                        const SizedBox(height: 8),
                        const Text('No categories found',
                            style: TextStyle(
                                color: textSecondary, fontSize: 14)),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Table header summary
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Text(
                            '${data.length} categories',
                            style: const TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Divider(height: 1, color: borderColor),
                    // Scrollable table
                    Expanded(
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: math.max(
                                    600,
                                    MediaQuery.of(context).size.width - 120),
                              ),
                              child: DataTable(
                                columnSpacing: 24,
                                dataRowMinHeight: 56,
                                dataRowMaxHeight: 64,
                                headingRowHeight: 44,
                                horizontalMargin: 16,
                                headingRowColor: WidgetStateProperty.all(
                                    background),
                                dividerThickness: 1,
                                columns: const [
                                  DataColumn(
                                    label: Text('Category',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary,
                                            letterSpacing: 0.5)),
                                  ),
                                  DataColumn(
                                    label: Text('Times Used',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary,
                                            letterSpacing: 0.5)),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text('Users',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary,
                                            letterSpacing: 0.5)),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text('Status',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary,
                                            letterSpacing: 0.5)),
                                  ),
                                ],
                                rows: data.map<DataRow>((raw) {
                                  final cat = raw ?? {};
                                  final catName =
                                      (cat['cat_name'] ?? '') as String;
                                  final catLogo =
                                      (cat['cat_logo'] ?? '') as String;
                                  final catId =
                                      (cat['cat_id'] ?? 0) as int;
                                  final catUsed = cat['cat_used'] ?? 0;
                                  final userCount =
                                      cat['user_count'] ?? 0;
                                  final isActive =
                                      (cat['status'] ?? false) as bool;

                                  return DataRow(cells: [
                                    // Category name + logo
                                    DataCell(Row(children: [
                                      _CatAvatar(
                                          logoName: catLogo,
                                          catName: catName),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          catName,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ])),
                                    // Times used
                                    DataCell(Text(
                                      NumberFormatter.formatNumber(
                                          catUsed),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: textPrimary),
                                    )),
                                    // User count
                                    DataCell(Text(
                                      NumberFormatter.formatNumber(
                                          userCount),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: textPrimary),
                                    )),
                                    // Status toggle badge
                                    DataCell(
                                      GestureDetector(
                                        onTap: () =>
                                            toggleStatus(catId),
                                        child: _StatusBadge(
                                            isActive: isActive),
                                      ),
                                    ),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CatAvatar extends StatefulWidget {
  final String logoName;
  final String catName;
  const _CatAvatar({required this.logoName, required this.catName});

  @override
  State<_CatAvatar> createState() => _CatAvatarState();
}

class _CatAvatarState extends State<_CatAvatar> {
  bool _error = false;

  @override
  Widget build(BuildContext context) {
    final hasLogo = widget.logoName.isNotEmpty && !_error;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accentLight,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? Image.network(
              Uri.encodeFull(
                  'https://aarambd.com/cat%20logo/${widget.logoName}'),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) {
                  if (mounted) setState(() => _error = true);
                });
                return _fallback();
              },
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    final initial = widget.catName.isNotEmpty
        ? widget.catName[0].toUpperCase()
        : '?';
    return Center(
      child: Text(initial,
          style: const TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w700,
              fontSize: 14)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? successColor.withValues(alpha: 0.1)
            : errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? successColor.withValues(alpha: 0.3)
              : errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? successColor : errorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? successColor : errorColor,
            ),
          ),
        ],
      ),
    );
  }
}
