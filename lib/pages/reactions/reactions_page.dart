import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/constants/style.dart';

class ReactionsPage extends StatefulWidget {
  const ReactionsPage({super.key});

  @override
  State<ReactionsPage> createState() => _ReactionsPageState();
}

class _ReactionsPageState extends State<ReactionsPage> {
  // Tab: 'views' | 'calls'
  String _tab = 'views';
  String _sort = 'recent';
  int _page = 1;
  bool _loading = false;

  int _total = 0;
  int _totalInteractions = 0;
  bool _hasMore = false;
  List<dynamic> _results = [];

  final _searchCtrl = TextEditingController();

  static const _sortOptions = [
    ('recent', 'Most Recent'),
    ('most_count', 'Most Interactions'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) _page = 1;
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
          '$host/api/reactions/?tab=$_tab&page=$_page&sort=$_sort&search=${Uri.encodeQueryComponent(_searchCtrl.text.trim())}');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _total              = data['total'] ?? 0;
          _totalInteractions  = data['total_interactions'] ?? 0;
          _hasMore            = data['has_more'] ?? false;
          _results            = data['results'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: errorColor));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _switchTab(String tab) {
    if (_tab == tab) return;
    setState(() {
      _tab  = tab;
      _page = 1;
      _results = [];
      _searchCtrl.clear();
    });
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final isViews = _tab == 'views';
    final tabColor = isViews ? const Color(0xFF8B5CF6) : const Color(0xFF06B6D4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 22, color: accentColor),
              const SizedBox(width: 10),
              const Text('Reactions',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tabColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: tabColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  isViews ? 'View Activity' : 'Call Activity',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tabColor),
                ),
              ),
              const Spacer(),
              if (_total > 0) ...[
                _StatChip(
                  icon: isViews
                      ? Icons.visibility_rounded
                      : Icons.phone_rounded,
                  label: 'Unique Pairs',
                  value: NumberFormatter.formatNumber(_total),
                  color: tabColor,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.repeat_rounded,
                  label: 'Total Interactions',
                  value: NumberFormatter.formatNumber(_totalInteractions),
                  color: accentColor,
                ),
              ],
            ],
          ),
        ),

        // ── Tab switcher ──────────────────────────────────────────────────
        Row(
          children: [
            _TabButton(
              label: 'Views',
              icon: Icons.visibility_rounded,
              selected: isViews,
              color: const Color(0xFF8B5CF6),
              onTap: () => _switchTab('views'),
            ),
            const SizedBox(width: 10),
            _TabButton(
              label: 'Calls',
              icon: Icons.phone_rounded,
              selected: !isViews,
              color: const Color(0xFF06B6D4),
              onTap: () => _switchTab('calls'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Search + sort card ─────────────────────────────────────────────
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
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(fontSize: 13, color: textPrimary),
                      onSubmitted: (_) => _load(reset: true),
                      decoration: InputDecoration(
                        hintText: 'Search by name or user ID...',
                        hintStyle:
                            const TextStyle(color: textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 16, color: textMuted),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    size: 16, color: textMuted),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _load(reset: true);
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
                            borderSide: const BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: accentColor, width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _load(reset: true),
                    icon: const Icon(Icons.search_rounded,
                        size: 16, color: Colors.white),
                    label: const Text('Search',
                        style: TextStyle(fontSize: 13, color: Colors.white)),
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
              const SizedBox(height: 10),
              Row(
                children: _sortOptions.map((opt) {
                  final selected = _sort == opt.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _sort = opt.$1);
                        _load(reset: true);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? accentColor : background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: selected ? accentColor : borderColor),
                        ),
                        child: Text(opt.$2,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : textSecondary)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // ── Activity list ─────────────────────────────────────────────────
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
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: accentColor))
                : _results.isEmpty
                    ? _EmptyState(isViews: isViews)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: borderColor, indent: 16, endIndent: 16),
                          itemBuilder: (ctx, i) => _ActivityRow(
                            item: _results[i],
                            isViews: isViews,
                            tabColor: tabColor,
                          ),
                        ),
                      ),
          ),
        ),

        // ── Pagination ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PageBtn(
                label: 'Prev',
                icon: Icons.chevron_left_rounded,
                enabled: _page > 1,
                onTap: () {
                  setState(() => _page--);
                  _load();
                },
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: accentLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Page $_page  ·  $_total results',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor)),
              ),
              _PageBtn(
                label: 'Next',
                icon: Icons.chevron_right_rounded,
                iconAfter: true,
                enabled: _hasMore,
                onTap: () {
                  setState(() => _page++);
                  _load();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tab button ──────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? color : borderColor, width: 1.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18, color: selected ? Colors.white : textSecondary),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Stat chip ───────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ── Single activity row ─────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isViews;
  final Color tabColor;

  const _ActivityRow({
    required this.item,
    required this.isViews,
    required this.tabColor,
  });

  @override
  Widget build(BuildContext context) {
    final count = item['count'] ?? 0;
    final time  = DateTimeFormatter.formatBdTime(item['time']?.toString() ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Actor
          Expanded(
            child: _UserBlock(
              id:    '${item['actor_id']}',
              name:  item['actor_name'] ?? '—',
              phone: item['actor_phone'] ?? '',
              label: isViews ? 'Viewer' : 'Caller',
              color: tabColor,
            ),
          ),

          // Arrow + count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: tabColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: tabColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isViews
                            ? Icons.visibility_rounded
                            : Icons.phone_rounded,
                        size: 12,
                        color: tabColor,
                      ),
                      const SizedBox(width: 4),
                      Text('$count×',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: tabColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.arrow_forward_rounded,
                    size: 18, color: tabColor.withValues(alpha: 0.6)),
              ],
            ),
          ),

          // Target
          Expanded(
            child: _UserBlock(
              id:    '${item['target_id']}',
              name:  item['target_name'] ?? '—',
              phone: item['target_phone'] ?? '',
              label: isViews ? 'Profile Viewed' : 'Was Called',
              color: textSecondary,
              alignRight: true,
            ),
          ),

          // Timestamp
          const SizedBox(width: 16),
          SizedBox(
            width: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Last Activity',
                    style: TextStyle(fontSize: 10, color: textMuted)),
                const SizedBox(height: 2),
                Text(time,
                    style: const TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.right),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── User info block (actor / target) ────────────────────────────────────────

class _UserBlock extends StatelessWidget {
  final String id;
  final String name;
  final String phone;
  final String label;
  final Color color;
  final bool alignRight;

  const _UserBlock({
    required this.id,
    required this.name,
    required this.phone,
    required this.label,
    required this.color,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final cross   = alignRight
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: alignRight
          ? [
              Flexible(
                child: Column(
                  crossAxisAlignment: cross,
                  children: _textContent(cross),
                ),
              ),
              const SizedBox(width: 10),
              _avatar(initial, color),
            ]
          : [
              _avatar(initial, color),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: cross,
                  children: _textContent(cross),
                ),
              ),
            ],
    );
    return alignRight
        ? Align(alignment: Alignment.centerRight, child: row)
        : row;
  }

  Widget _avatar(String initial, Color c) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(initial,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: c)),
      ),
    );
  }

  List<Widget> _textContent(CrossAxisAlignment cross) => [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                  letterSpacing: 0.5)),
        ),
        const SizedBox(height: 3),
        Text(name,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tag_rounded, size: 10, color: textMuted),
            Text(id,
                style: const TextStyle(fontSize: 11, color: textMuted)),
            if (phone.isNotEmpty) ...[
              const SizedBox(width: 6),
              const Icon(Icons.phone_rounded,
                  size: 10, color: successColor),
              Text(phone,
                  style: const TextStyle(
                      fontSize: 11, color: successColor)),
            ],
          ],
        ),
      ];
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isViews;
  const _EmptyState({required this.isViews});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isViews
                ? Icons.visibility_off_rounded
                : Icons.phone_disabled_rounded,
            size: 48,
            color: textMuted,
          ),
          const SizedBox(height: 10),
          Text('No ${isViews ? 'view' : 'call'} activity found',
              style: const TextStyle(color: textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Pagination button ────────────────────────────────────────────────────────

class _PageBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool iconAfter;
  final VoidCallback onTap;

  const _PageBtn({
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
