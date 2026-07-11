import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:http/http.dart' as http;
import 'package:data_table_2/data_table_2.dart';
import 'package:google_fonts/google_fonts.dart';

class SubscriberPage extends StatefulWidget {
  const SubscriberPage({super.key});

  @override
  State<SubscriberPage> createState() => _SubscriberPageState();
}

class _SubscriberPageState extends State<SubscriberPage> {
  List<dynamic> subscribers = [];
  Map<String, dynamic> summary = {};
  int currentPage = 1;
  bool hasMore = true;
  bool isLoading = false;

  String searchQuery = "";
  String sortBy = "";
  String panelView = "all";

  final TextEditingController _searchController = TextEditingController();

  static const _sortOptions = [
    ('', 'All'),
    ('recent', 'Recent'),
    ('type', 'Type'),
    ('cat', 'Category'),
    ('service', 'Service'),
    ('shop', 'Shop'),
  ];

  static const _viewOptions = [
    ('all', 'All'),
    ('requesting', 'Requesting'),
    ('eligible_pay', 'Eligible to Pay'),
    ('eligible_notify', 'Notify-eligible'),
  ];

  Future<void> fetchSubscribers() async {
    setState(() => isLoading = true);
    final url = Uri.parse(
        "$host/api/subscriber-users/?page=$currentPage&search=$searchQuery&sort=$sortBy&view=$panelView");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        summary = data['results']['summary'] ?? {};
        subscribers = data['results']['results'] ?? [];
        hasMore = data['next'] != null;
      });
    }
    setState(() => isLoading = false);
  }

  Future<void> toggleSubscriber(int subId, String currentType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Action',
            style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
        content: Text(
          currentType == "paid"
              ? "Mark this subscriber as Unpaid?"
              : "Mark this subscriber as Paid?",
          style: const TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final url = Uri.parse("$host/api/toggle-subscriber/$subId/");
    final response = await http.post(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Subscriber ${data['sub_id']} is now ${data['type']}"),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
      ));
      fetchSubscribers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to toggle subscriber"),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> approveSubscriber(int subId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Approval',
            style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
        content: const Text(
          "Approve this subscriber and mark them as Paid/Verified?",
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: successColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final url = Uri.parse("$host/api/approve-subscriber/$subId/");
    final response = await http.post(url);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Subscriber approved and marked Paid"),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
      ));
      fetchSubscribers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to approve subscriber"),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> rejectSubscriber(int subId) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final canReject = reasonController.text.trim().isNotEmpty;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Reject Request',
                style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "This sends the user a notification quoting your reason. "
                  "The request moves back to Unpaid.",
                  style: TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Reason for rejection...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel',
                    style: TextStyle(color: textSecondary)),
              ),
              ElevatedButton(
                onPressed: canReject ? () => Navigator.of(ctx).pop(true) : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0),
                child: const Text('Reject'),
              ),
            ],
          );
        },
      ),
    );

    if (confirm != true) return;
    final reason = reasonController.text.trim();
    if (reason.isEmpty) return;

    final url = Uri.parse("$host/api/reject-subscriber/$subId/");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'reason': reason}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Request rejected and user notified"),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
      ));
      fetchSubscribers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to reject subscriber"),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> notifySubscriberUsage(int subId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Send Usage Notification',
            style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
        content: const Text(
          "Notify this user about their profile usage this month?",
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final url = Uri.parse("$host/api/subscriber/$subId/notify-usage/");
    final response = await http.post(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['success'] == true
            ? "Notification sent"
            : "Failed: ${data['message'] ?? 'unknown error'}"),
        backgroundColor: data['success'] == true ? successColor : errorColor,
        behavior: SnackBarBehavior.floating,
      ));
      fetchSubscribers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to send notification"),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> toggleUserActiveStatus(int userId, bool currentlyActive) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Action',
            style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
        content: Text(
          currentlyActive
              ? "Deactivate this user's account? Their shop/service will be hidden from the app."
              : "Reactivate this user's account?",
          style: const TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: currentlyActive ? errorColor : successColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0),
            child: Text(currentlyActive ? 'Deactivate' : 'Reactivate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final url = Uri.parse("$host/api/user_toggle_status/$userId/");
    final response = await http.post(url);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            currentlyActive ? "User deactivated" : "User reactivated"),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
      ));
      fetchSubscribers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to update user status"),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _copyRowData(Map<String, dynamic> row) {
    final buffer = StringBuffer();
    row.forEach((key, value) => buffer.writeln("$key: ${value ?? ''}"));
    Clipboard.setData(ClipboardData(text: buffer.toString()));
  }

  @override
  void initState() {
    super.initState();
    fetchSubscribers();
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
              const Icon(Icons.card_membership_rounded,
                  size: 22, color: accentColor),
              const SizedBox(width: 10),
              const Text('Subscribers',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
              const Spacer(),
              if (summary.isNotEmpty) ...[
                _SummaryChip(
                    label: 'Total',
                    value: summary['total_subscribers']?.toString() ?? '0',
                    color: accentColor),
                const SizedBox(width: 6),
                _SummaryChip(
                    label: 'Svc Paid',
                    value: summary['service_paid']?.toString() ?? '0',
                    color: successColor),
                const SizedBox(width: 6),
                _SummaryChip(
                    label: 'Svc Unpaid',
                    value: summary['service_unpaid']?.toString() ?? '0',
                    color: errorColor),
                const SizedBox(width: 6),
                _SummaryChip(
                    label: 'Shop Paid',
                    value: summary['shop_paid']?.toString() ?? '0',
                    color: successColor),
                const SizedBox(width: 6),
                _SummaryChip(
                    label: 'Shop Unpaid',
                    value: summary['shop_unpaid']?.toString() ?? '0',
                    color: errorColor),
                const SizedBox(width: 6),
                _SummaryChip(
                    label: 'Cats',
                    value: summary['total_categories']?.toString() ?? '0',
                    color: warningColor),
                const SizedBox(width: 6),
                _SummaryChip(
                    label: 'Requesting',
                    value: summary['requesting_count']?.toString() ?? '0',
                    color: warningColor),
                const SizedBox(width: 6),
                _SummaryChip(
                    label: 'Notify-eligible',
                    value: summary['eligible_notify_count']?.toString() ?? '0',
                    color: accentColor),
              ],
            ],
          ),
        ),

        // Panel view filter pills
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: _viewOptions.map((opt) {
              final isSelected = panelView == opt.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => panelView = opt.$1);
                    currentPage = 1;
                    fetchSubscribers();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isSelected ? accentColor : borderColor),
                    ),
                    child: Text(opt.$2,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : textSecondary)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Controls card
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
              // Add button + search row
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      setState(() => isLoading = true);
                      final url =
                          Uri.parse("$host/api/create-subscribers/");
                      final messenger = ScaffoldMessenger.of(context);
                      final response = await http.post(url);
                      setState(() => isLoading = false);
                      if (response.statusCode == 201) {
                        final data = json.decode(response.body);
                        final s = data['summary'];
                        messenger.showSnackBar(SnackBar(
                          content: Text(
                              "Added ${s['total_new']} (Service: ${s['service_new']}, Shop: ${s['shop_new']})"),
                          backgroundColor: successColor,
                          behavior: SnackBarBehavior.floating,
                        ));
                        currentPage = 1;
                        fetchSubscribers();
                      } else {
                        messenger.showSnackBar(const SnackBar(
                            content: Text("Failed to create subscribers"),
                            backgroundColor: errorColor,
                            behavior: SnackBarBehavior.floating));
                      }
                    },
                    icon: const Icon(Icons.add_rounded,
                        size: 16, color: Colors.white),
                    label: const Text('Add Eligible Subscribers',
                        style:
                            TextStyle(fontSize: 13, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                          fontSize: 13, color: textPrimary),
                      onSubmitted: (value) {
                        searchQuery = value;
                        currentPage = 1;
                        fetchSubscribers();
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Search by User ID / Name / Phone / Category / Service / Shop',
                        hintStyle: const TextStyle(
                            color: textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 16, color: textMuted),
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
                      fetchSubscribers();
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
              // Sort pills
              Row(
                children: _sortOptions.map((opt) {
                  final isSelected = sortBy == opt.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => sortBy = opt.$1);
                        currentPage = 1;
                        fetchSubscribers();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor : background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSelected
                                  ? accentColor
                                  : borderColor),
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
                : subscribers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.card_membership_outlined,
                                size: 48, color: textMuted),
                            const SizedBox(height: 8),
                            const Text('No subscribers found',
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
                          dataRowHeight: 60,
                          headingRowHeight: 44,
                          minWidth: 1900,
                          dividerThickness: 1,
                          columns: const [
                            DataColumn2(
                                label: Text('User ID', style: _hStyle),
                                fixedWidth: 80),
                            DataColumn2(
                                label: Text('Name', style: _hStyle),
                                size: ColumnSize.L),
                            DataColumn2(
                                label: Text('Phone', style: _hStyle),
                                fixedWidth: 120),
                            DataColumn2(
                                label:
                                    Text('Category', style: _hStyle),
                                size: ColumnSize.M),
                            DataColumn2(
                                label:
                                    Text('Service ID', style: _hStyle),
                                fixedWidth: 90),
                            DataColumn2(
                                label: Text('Shop ID', style: _hStyle),
                                fixedWidth: 80),
                            DataColumn2(
                                label: Text('Type', style: _hStyle),
                                fixedWidth: 90),
                            DataColumn2(
                                label: Text('This Month', style: _hStyle),
                                fixedWidth: 130),
                            DataColumn2(
                                label: Text('Requested', style: _hStyle),
                                size: ColumnSize.M),
                            DataColumn2(
                                label: Text('Notified', style: _hStyle),
                                size: ColumnSize.M),
                            DataColumn2(
                                label: Text('Last Pay', style: _hStyle),
                                size: ColumnSize.M),
                            DataColumn2(
                                label:
                                    Text('Location', style: _hStyle),
                                size: ColumnSize.L),
                            DataColumn2(
                                label: Text('Active', style: _hStyle),
                                fixedWidth: 70),
                            DataColumn2(
                                label: Text('Action', style: _hStyle),
                                fixedWidth: 240),
                            DataColumn2(
                                label: Text('Notify', style: _hStyle),
                                fixedWidth: 60),
                            DataColumn2(
                                label: Text('Copy', style: _hStyle),
                                fixedWidth: 60),
                          ],
                          rows: List<DataRow2>.generate(
                            subscribers.length,
                            (index) {
                              final s = subscribers[index];
                              final subType =
                                  (s['type'] ?? '').toString().toLowerCase();
                              final isPaid = subType == 'paid';
                              final isActive = s['user_status'] == true;
                              final eligibleForNotify =
                                  s['eligible_for_notification'] == true;
                              return DataRow2(
                                cells: [
                                  DataCell(Text(
                                      '${s['user_id']}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textSecondary))),
                                  DataCell(Text(
                                      s['user_name'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.notoSansBengali(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
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
                                  DataCell(Text(
                                      s['category'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: textPrimary))),
                                  DataCell(Text(
                                      '${s['service_id']}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: textSecondary))),
                                  DataCell(Text(
                                      '${s['shop_id']}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: textSecondary))),
                                  DataCell(_SubTypeBadge(type: subType)),
                                  DataCell(Text(
                                      'C:${s['monthly_calls'] ?? 0}  V:${s['monthly_views'] ?? 0}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: textSecondary))),
                                  DataCell(Text(
                                      TimeFormatter.formatBdTime(
                                          s['requested_at'] ?? ''),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: textSecondary))),
                                  DataCell(Text(
                                      TimeFormatter.formatBdTime(
                                          s['last_notified_at'] ?? ''),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: textSecondary))),
                                  DataCell(Text(
                                      TimeFormatter.formatBdTime(
                                          s['last_pay'] ?? ''),
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
                                  DataCell(Switch(
                                    value: isActive,
                                    activeThumbColor: successColor,
                                    onChanged: (_) => toggleUserActiveStatus(
                                        s['user_id'], isActive),
                                  )),
                                  DataCell(isPaid
                                      ? _ActionPill(
                                          label: 'Revoke to Unpaid',
                                          color: errorColor,
                                          onTap: () => toggleSubscriber(
                                              s['sub_id'], s['type']),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _ActionPill(
                                              label: 'Approve & Mark Paid',
                                              color: successColor,
                                              onTap: () => approveSubscriber(
                                                  s['sub_id']),
                                            ),
                                            if (subType == 'waiting') ...[
                                              const SizedBox(width: 6),
                                              _ActionPill(
                                                label: 'Reject',
                                                color: errorColor,
                                                onTap: () => rejectSubscriber(
                                                    s['sub_id']),
                                              ),
                                            ],
                                          ],
                                        )),
                                  DataCell(IconButton(
                                    icon: Icon(
                                      Icons.notifications_rounded,
                                      size: 18,
                                      color: eligibleForNotify
                                          ? warningColor
                                          : textMuted.withValues(alpha: 0.4),
                                    ),
                                    tooltip: eligibleForNotify
                                        ? 'Send usage notification'
                                        : 'Not eligible this month',
                                    onPressed: eligibleForNotify
                                        ? () =>
                                            notifySubscriberUsage(s['sub_id'])
                                        : null,
                                  )),
                                  DataCell(IconButton(
                                    icon: const Icon(Icons.copy_rounded,
                                        size: 16, color: accentColor),
                                    tooltip: 'Copy row data',
                                    onPressed: () => _copyRowData(s),
                                  )),
                                ],
                              );
                            },
                          ),
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
                  fetchSubscribers();
                },
              ),
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16),
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
                  fetchSubscribers();
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

class _ActionPill extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionPill({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}

class _SubTypeBadge extends StatelessWidget {
  final String type;
  const _SubTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (type) {
      case 'paid':
        color = successColor;
        label = 'PAID';
        break;
      case 'waiting':
        color = warningColor;
        label = 'WAITING';
        break;
      default:
        color = errorColor;
        label = 'UNPAID';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
