import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/service_api/auth_headers.dart';

class Clientstable extends StatefulWidget {
  const Clientstable({super.key});

  @override
  State<Clientstable> createState() => _ClientstableState();
}

class _ClientstableState extends State<Clientstable> {
  String selectedSort = 'recent';
  String? searchUserId;
  List<dynamic> userData = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  static const _sortOptions = [
    ('recent', 'Most Recent'),
    ('Category', 'By Category'),
    ('paid', 'Paid Users'),
    ('free', 'Free Users'),
    ('User_Called', 'Most Called'),
  ];

  Future<void> fetchData({String? userId}) async {
    setState(() => isLoading = true);
    try {
      String apiUrl = '$host/api/get-users/';
      if (userId != null && userId.isNotEmpty) {
        apiUrl += '?search=$userId';
      } else {
        apiUrl += '?sort=${selectedSort.toLowerCase()}';
      }
      final response = await http.get(Uri.parse(apiUrl), headers: authHeaders());
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('users')) {
          List users = responseData['users'];
          if (selectedSort.toLowerCase() == 'paid') {
            setState(() {
              userData = users.where((u) => u['user_type'] == true).toList();
            });
          } else if (selectedSort.toLowerCase() == 'free') {
            setState(() {
              userData = users.where((u) => u['user_type'] == false).toList();
            });
          } else {
            setState(() => userData = users);
          }
        } else {
          setState(() => userData = []);
        }
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      setState(() => userData = []);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> downloadUserData(BuildContext context, String? userId) async {
    try {
      String apiUrl = '$host/api/download-user/?user_id=$userId';
      final response = await http.get(Uri.parse(apiUrl), headers: authHeaders());
      if (response.statusCode == 200) {
        final contentDisposition = response.headers['Content-Disposition'];
        final fileName = contentDisposition != null
            ? RegExp(r'filename="(.+)"').firstMatch(contentDisposition)?.group(1)
            : 'user_data.pdf';
        final blob = html.Blob([response.bodyBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..download = fileName
          ..click();
        html.Url.revokeObjectUrl(url);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download started successfully!')),
          );
        }
      } else {
        throw Exception("Failed to download PDF. Status: ${response.statusCode}");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error downloading PDF: $e")),
        );
      }
    }
  }

  Future<bool> usertoggleStatus(int userId) async {
    final url = Uri.parse('$host/api/user_toggle_status/$userId/');
    try {
      final res = await http.post(url, headers: authHeaders());
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> usertypetoggleStatus(int userId) async {
    final url = Uri.parse('$host/api/user-type-toggle-status/$userId/');
    try {
      await http.post(url, headers: authHeaders());
    } catch (_) {}
  }

  Future<bool> _confirmStatusChange(bool currentlyActive) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Action',
            style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
        content: Text(
          currentlyActive
              ? 'Make this user inactive? They will still be able to open the app, but cannot post or call, and will be hidden from everyone else.'
              : 'Reactivate this user? They will become fully visible again.',
          style: const TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: currentlyActive ? errorColor : successColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0),
            child: Text(currentlyActive ? 'Make Inactive' : 'Reactivate'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _confirmAndDeleteUser(int userId, String name, String phone) async {
    final confirmCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDlg) {
          final match = confirmCtrl.text.trim() == phone.trim();
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Permanently Delete User',
                style: TextStyle(fontWeight: FontWeight.w700, color: errorColor)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will permanently delete "$name" and everything related to them '
                  '(posts, reviews, notifications, calls, listings). This cannot be undone.',
                  style: const TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 12),
                Text('Type their phone number ($phone) to confirm:',
                    style: const TextStyle(fontSize: 12, color: textMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: confirmCtrl,
                  onChanged: (_) => setDlg(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel', style: TextStyle(color: textSecondary)),
              ),
              ElevatedButton(
                onPressed: match ? () => Navigator.pop(dialogCtx, true) : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0),
                child: const Text('Delete Permanently'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    final res = await http.post(Uri.parse('$host/api/users/$userId/delete/'),
        headers: authHeaders());
    if (!mounted) return;
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$name has been permanently deleted.'),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
      ));
      fetchData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to delete user.'),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
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
              const Icon(Icons.people_rounded, size: 22, color: accentColor),
              const SizedBox(width: 10),
              const Text(
                'Users',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary),
              ),
              const Spacer(),
              if (!isLoading && userData.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${userData.length} users',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor),
                  ),
                ),
            ],
          ),
        ),

        // Search + Actions card
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
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              // Search row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search by ID / Phone / Name / Category...',
                        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: textMuted, size: 20),
                        suffixIcon: (searchUserId?.isNotEmpty ?? false)
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: textMuted, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => searchUserId = null);
                                  fetchData();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
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
                          borderSide: const BorderSide(color: accentColor, width: 1.5),
                        ),
                      ),
                      onChanged: (v) {
                        setState(() => searchUserId = v.isEmpty ? null : v);
                        if (v.isEmpty) fetchData();
                      },
                      onSubmitted: (v) {
                        if (v.isNotEmpty) fetchData(userId: v);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ActionButton(
                    icon: Icons.search_rounded,
                    label: 'Search',
                    color: accentColor,
                    onPressed: () {
                      if (searchUserId?.isNotEmpty ?? false) {
                        fetchData(userId: searchUserId);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Sort row
              Row(
                children: [
                  const Text('Sort:',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textSecondary)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSort,
                          isExpanded: true,
                          icon: const Icon(Icons.unfold_more_rounded,
                              size: 18, color: textSecondary),
                          style: const TextStyle(fontSize: 13, color: textPrimary),
                          items: _sortOptions.map((opt) {
                            return DropdownMenuItem<String>(
                              value: opt.$1,
                              child: Text(opt.$2),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                selectedSort = v;
                                isLoading = true;
                              });
                              fetchData();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
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
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: accentColor))
                : userData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline,
                                size: 48, color: textMuted),
                            const SizedBox(height: 8),
                            const Text('No users found',
                                style: TextStyle(
                                    color: textSecondary, fontSize: 14)),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => fetchData(),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Refresh'),
                              style: TextButton.styleFrom(
                                  foregroundColor: accentColor),
                            ),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DataTable2(
                          columnSpacing: 16,
                          dataRowHeight: 60,
                          headingRowHeight: 44,
                          horizontalMargin: 16,
                          minWidth: 860,
                          headingRowColor: WidgetStateProperty.all(background),
                          dividerThickness: 1,
                          border: TableBorder(
                            horizontalInside: BorderSide(
                                color: borderColor, width: 1),
                          ),
                          columns: const [
                            DataColumn2(
                              label: Text('User ID',
                                  style: _headerStyle),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text('Category',
                                  style: _headerStyle),
                              size: ColumnSize.L,
                            ),
                            DataColumn2(
                              label: Text('Name',
                                  style: _headerStyle),
                              size: ColumnSize.L,
                            ),
                            DataColumn2(
                              label: Text('Phone',
                                  style: _headerStyle),
                              size: ColumnSize.M,
                            ),
                            DataColumn(
                              label: Text('Called',
                                  style: _headerStyle),
                            ),
                            DataColumn(
                              label: Text('Type',
                                  style: _headerStyle),
                            ),
                            DataColumn(
                              label: Text('Status',
                                  style: _headerStyle),
                            ),
                            DataColumn(
                              label: Text('Receipt',
                                  style: _headerStyle),
                            ),
                            DataColumn(
                              label: Text('Delete',
                                  style: _headerStyle),
                            ),
                          ],
                          rows: List<DataRow>.generate(
                            userData.length,
                            (index) {
                              final user = userData[index];
                              final isActive = user['status'] == true;
                              final isPaid = user['user_type'] == true;

                              return DataRow(
                                cells: [
                                  // User ID
                                  DataCell(Text(
                                    user['user_id'].toString(),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary),
                                  )),
                                  // Category
                                  DataCell(Text(
                                    user['cat__cat_name'].toString(),
                                    style: const TextStyle(
                                        fontSize: 13, color: textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  )),
                                  // Name
                                  DataCell(Text(
                                    user['name'].toString(),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  )),
                                  // Phone
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.phone_rounded,
                                          size: 13, color: successColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        user['phone'].toString(),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: successColor,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  )),
                                  // Called count
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: warningColor, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        user['user_called'].toString(),
                                        style: const TextStyle(
                                            fontSize: 13, color: textPrimary),
                                      ),
                                    ],
                                  )),
                                  // User type badge (PAID / FREE)
                                  DataCell(GestureDetector(
                                    onTap: () async {
                                      final uid = user['user_id'] as int;
                                      await usertypetoggleStatus(uid);
                                      setState(() {
                                        userData[index]['user_type'] =
                                            !userData[index]['user_type'];
                                      });
                                    },
                                    child: _TypeBadge(isPaid: isPaid),
                                  )),
                                  // Active/Inactive status badge
                                  DataCell(GestureDetector(
                                    onTap: () async {
                                      final uid = user['user_id'] as int;
                                      final confirmed =
                                          await _confirmStatusChange(isActive);
                                      if (!confirmed) return;
                                      final ok = await usertoggleStatus(uid);
                                      if (!ok) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content:
                                              Text('Failed to update status.'),
                                          backgroundColor: errorColor,
                                        ));
                                        return;
                                      }
                                      setState(() {
                                        userData[index]['status'] =
                                            !userData[index]['status'];
                                      });
                                    },
                                    child: _StatusBadge(isActive: isActive),
                                  )),
                                  // Per-row download button
                                  DataCell(
                                    Tooltip(
                                      message: 'Download Receipt',
                                      child: InkWell(
                                        onTap: () => downloadUserData(
                                            context,
                                            user['user_id'].toString()),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: accentLight,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.download_rounded,
                                            size: 16,
                                            color: accentColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Per-row permanent delete button
                                  DataCell(
                                    Tooltip(
                                      message: 'Delete permanently',
                                      child: InkWell(
                                        onTap: () => _confirmAndDeleteUser(
                                          user['user_id'] as int,
                                          user['name'].toString(),
                                          user['phone'].toString(),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: errorColor.withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.delete_forever_rounded,
                                            size: 16,
                                            color: errorColor,
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
          ),
        ),
      ],
    );
  }
}

const _headerStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: textSecondary,
  letterSpacing: 0.5,
);

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label,
          style: const TextStyle(fontSize: 13, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          letterSpacing: 0.5,
        ),
      ),
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
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? successColor : errorColor,
            ),
          ),
        ],
      ),
    );
  }
}
