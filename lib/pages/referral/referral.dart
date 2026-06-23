import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/constants/style.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  bool loading = false;
  List<dynamic> results = [];
  Map<String, dynamic> summary = {};
  String currentSort = "most_recent";
  String currentSearchType = "name";
  final _searchController = TextEditingController();

  static const _sortOptions = [
    ('most_recent',    'Most Recent'),
    ('highest_points', 'Highest Points'),
    ('paid',           'Paid'),
    ('unpaid',         'Unpaid'),
  ];

  static const _searchTypes = [
    ('name',    'Name'),
    ('user_id', 'User ID'),
    ('phone',   'Phone'),
  ];

  Future<void> _load({String? sort, String? search, String? searchType}) async {
    setState(() => loading = true);
    try {
      final response = await http.get(Uri.parse(
          "$host/api/referrals/?sort=${sort ?? currentSort}&${searchType ?? currentSearchType}=${search ?? ''}"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          summary = data['summary'];
          results = data['results'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _updateReferral(int id,
      {String? verification, String? paymentStatus}) async {
    final body = {};
    if (verification != null) body['verification'] = verification;
    if (paymentStatus != null) body['payment_status'] = paymentStatus;

    final response = await http.patch(
      Uri.parse("$host/api/referrals/$id/update/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      _load();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Update failed")));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
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
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
          child: Row(
            children: [
              const Icon(Icons.group_add_rounded, size: 22, color: accentColor),
              const SizedBox(width: 10),
              const Text('Referrals',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
              const Spacer(),
              if (summary.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${summary['total'] ?? 0} total',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: accentColor)),
                ),
            ],
          ),
        ),

        // Summary cards
        if (summary.isNotEmpty) ...[
          _SummaryRow(summary: summary),
          const SizedBox(height: 12),
        ],

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
            children: [
              // Search row
              Row(
                children: [
                  // Search type dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentSearchType,
                        icon: const Icon(Icons.unfold_more_rounded,
                            size: 16, color: textSecondary),
                        style: const TextStyle(fontSize: 13, color: textPrimary),
                        items: _searchTypes.map((t) => DropdownMenuItem(
                              value: t.$1,
                              child: Text(t.$2),
                            )).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => currentSearchType = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Search field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search by $currentSearchType...',
                        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: textMuted, size: 20),
                        filled: true,
                        fillColor: background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: accentColor, width: 1.5)),
                      ),
                      onSubmitted: (v) => _load(
                          search: v, searchType: currentSearchType),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _load(
                        search: _searchController.text,
                        searchType: currentSearchType),
                    icon: const Icon(Icons.search_rounded,
                        size: 16, color: Colors.white),
                    label: const Text('Search',
                        style: TextStyle(fontSize: 13, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                  final isSelected = currentSort == opt.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => currentSort = opt.$1);
                        _load(sort: opt.$1);
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

        // Results list
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: accentColor))
              : results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group_off_rounded, size: 48, color: textMuted),
                          const SizedBox(height: 8),
                          const Text('No referrals found',
                              style:
                                  TextStyle(color: textSecondary, fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, i) =>
                          _ReferralCard(
                            data: results[i],
                            onUpdateReferral: _updateReferral,
                          ),
                    ),
        ),
      ],
    );
  }
}

// ── Summary row ────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SumChip(label: 'Total',      value: summary['total'] ?? 0,      color: textPrimary),
        const SizedBox(width: 8),
        _SumChip(label: 'Verified',   value: summary['verified'] ?? 0,   color: successColor),
        const SizedBox(width: 8),
        _SumChip(label: 'Unverified', value: summary['unverified'] ?? 0, color: errorColor),
        const SizedBox(width: 8),
        _SumChip(label: 'Waiting',    value: summary['waiting'] ?? 0,    color: warningColor),
        const SizedBox(width: 8),
        _SumChip(label: 'Paid',       value: summary['paid'] ?? 0,       color: accentColor),
        const SizedBox(width: 8),
        _SumChip(label: 'Unpaid',     value: summary['unpaid'] ?? 0,     color: textSecondary),
      ],
    );
  }
}

class _SumChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _SumChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Referral card ──────────────────────────────────────────────────────────

class _ReferralCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<void> Function(int id,
      {String? verification, String? paymentStatus}) onUpdateReferral;

  const _ReferralCard({required this.data, required this.onUpdateReferral});

  @override
  Widget build(BuildContext context) {
    final referrer  = data['referrer'];
    final referred  = data['referred'];
    final isPaid    = data['paid_at'] != null;
    final isPaymentPaid = data['payment_status'] == 'paid';
    final verification = data['verification'] as String;

    final verificationColor = verification == 'verified'
        ? successColor
        : verification == 'unverified'
            ? errorColor
            : warningColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          // Top bar with ID + verification status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: background,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Text('Referral #${data['id']}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textSecondary)),
                const SizedBox(width: 8),
                Text('· ${data['points']} pts',
                    style: const TextStyle(
                        fontSize: 12, color: accentColor, fontWeight: FontWeight.w600)),
                const Spacer(),
                // Verification dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: verificationColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: verificationColor.withValues(alpha: 0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: verification,
                      isDense: true,
                      icon: Icon(Icons.expand_more_rounded,
                          size: 14, color: verificationColor),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: verificationColor),
                      items: const [
                        DropdownMenuItem(value: 'waiting',    child: Text('Waiting')),
                        DropdownMenuItem(value: 'verified',   child: Text('Verified')),
                        DropdownMenuItem(value: 'unverified', child: Text('Unverified')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          onUpdateReferral(data['id'], verification: val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body: referrer + referred
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Referrer
                Expanded(
                  child: _UserInfoBlock(
                    label: 'Referrer',
                    labelColor: accentColor,
                    user: referrer,
                  ),
                ),
                // Arrow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            size: 16, color: accentColor),
                      ),
                    ],
                  ),
                ),
                // Referred
                Expanded(
                  child: _UserInfoBlock(
                    label: 'Referred',
                    labelColor: successColor,
                    user: referred,
                  ),
                ),
              ],
            ),
          ),

          // Footer: dates + payment button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DateRow(
                        icon: Icons.schedule_rounded,
                        label: 'Created',
                        value: _fmt(data['created_at'])),
                    const SizedBox(height: 4),
                    _DateRow(
                      icon: isPaid
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      label: 'Payment',
                      value: isPaid ? _fmt(data['paid_at']) : 'Unpaid',
                      color: isPaid ? successColor : errorColor,
                    ),
                  ],
                ),
                const Spacer(),
                // Payment toggle button
                GestureDetector(
                  onTap: () {
                    final newStatus = isPaymentPaid ? 'unpaid' : 'paid';
                    onUpdateReferral(data['id'], paymentStatus: newStatus);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isPaymentPaid
                          ? successColor.withValues(alpha: 0.1)
                          : errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isPaymentPaid
                              ? successColor.withValues(alpha: 0.4)
                              : errorColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPaymentPaid
                              ? Icons.payment_rounded
                              : Icons.money_off_rounded,
                          size: 16,
                          color: isPaymentPaid ? successColor : errorColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPaymentPaid ? 'PAID' : 'UNPAID',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isPaymentPaid ? successColor : errorColor,
                              letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }
}

class _UserInfoBlock extends StatelessWidget {
  final String label;
  final Color labelColor;
  final Map<String, dynamic> user;

  const _UserInfoBlock({
    required this.label,
    required this.labelColor,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final location = user['location_info'];
    final address  = location?['address'] ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4, height: 14,
              decoration: BoxDecoration(
                  color: labelColor,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                    letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 8),
        Text(user['name'] ?? '—',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
        const SizedBox(height: 2),
        Text(user['cat_name'] ?? '—',
            style: const TextStyle(fontSize: 12, color: accentColor)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.badge_rounded, size: 12, color: textMuted),
          const SizedBox(width: 4),
          Text('ID: ${user['user_id']}',
              style: const TextStyle(fontSize: 12, color: textSecondary)),
        ]),
        const SizedBox(height: 2),
        Row(children: [
          const Icon(Icons.phone_rounded, size: 12, color: textMuted),
          const SizedBox(width: 4),
          Text(user['phone'] ?? '—',
              style: const TextStyle(fontSize: 12, color: textSecondary)),
        ]),
        const SizedBox(height: 2),
        Row(children: [
          const Icon(Icons.location_on_rounded, size: 12, color: textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(address,
                style: const TextStyle(fontSize: 12, color: textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DateRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color = textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text('$label: ',
            style: const TextStyle(fontSize: 11, color: textMuted)),
        Text(value,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
