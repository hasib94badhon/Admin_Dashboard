import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/pages/overview/widgets/bar_chart.dart';
import 'package:flutter_web_dashboard/service_api/api_service.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await DashboardService.fetchOverviewStats();
      if (mounted) setState(() { _stats = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _loading = true);
          await _load();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const _LoadingBody()
              : _error != null
                  ? _ErrorBody(error: _error!, onRetry: () {
                      setState(() { _loading = true; _error = null; });
                      _load();
                    })
                  : _Body(stats: _stats!),
        ),
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: const Center(
        child: CircularProgressIndicator(color: accentColor),
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBody({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: textMuted),
            const SizedBox(height: 16),
            const Text("Could not load dashboard data",
                style: TextStyle(color: textSecondary, fontSize: 15)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _Body({required this.stats});

  @override
  Widget build(BuildContext context) {
    final desCatList = (stats['des_cat_counts'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section: Summary stat cards ──────────────────────────────────
        _SectionTitle(title: "Overview"),
        const SizedBox(height: 16),
        _StatCardsGrid(stats: stats),
        const SizedBox(height: 32),

        // ── Section: Registration chart + Subscribers ────────────────────
        LayoutBuilder(builder: (context, c) {
          if (c.maxWidth >= 800) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _ChartCard()),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _SubscribersCard(stats: stats)),
              ],
            );
          }
          return Column(children: [
            _ChartCard(),
            const SizedBox(height: 20),
            _SubscribersCard(stats: stats),
          ]);
        }),
        const SizedBox(height: 32),

        // ── Section: DesCat breakdown ────────────────────────────────────
        _SectionTitle(
          title: "Designation Categories",
          subtitle: "${desCatList.length} categories",
        ),
        const SizedBox(height: 16),
        _DesCatGrid(items: desCatList),
      ],
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            )),
        if (subtitle != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: accentLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(subtitle!,
                style: const TextStyle(
                    color: accentColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }
}

// ── Stat cards grid ───────────────────────────────────────────────────────────

class _StatCardsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatCardsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CardData("Total Users",        stats['total_users'],         Icons.people_rounded,               const Color(0xFF6366F1)),
      _CardData("Registrations",      stats['total_registrations'], Icons.person_add_rounded,            const Color(0xFF0EA5E9)),
      _CardData("Services",           stats['total_services'],      Icons.miscellaneous_services_rounded, const Color(0xFF10B981)),
      _CardData("Shops",              stats['total_shops'],         Icons.storefront_rounded,             const Color(0xFFF59E0B)),
      _CardData("FB Pages",           stats['total_fb_pages'],      Icons.public_rounded,                const Color(0xFF3B82F6)),
      _CardData("Paid Subscribers",   stats['paid_subscribers'],    Icons.verified_rounded,              const Color(0xFF8B5CF6)),
      _CardData("Unpaid Subscribers", stats['unpaid_subscribers'],  Icons.subscriptions_rounded,         const Color(0xFFEF4444)),
      _CardData("Referrals",          stats['total_referrals'],     Icons.group_add_rounded,             const Color(0xFFEC4899)),
    ];

    return LayoutBuilder(builder: (context, c) {
      int cols = c.maxWidth >= 1000 ? 4 : c.maxWidth >= 600 ? 3 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
        ),
        itemCount: cards.length,
        itemBuilder: (_, i) => _StatCard(data: cards[i]),
      );
    });
  }
}

class _CardData {
  final String label;
  final dynamic value;
  final IconData icon;
  final Color color;
  const _CardData(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _CardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, size: 20, color: data.color),
              ),
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (data.value ?? 0).toString(),
                style: TextStyle(
                  color: data.color,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(data.label,
                  style: const TextStyle(
                      color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Registration chart card ───────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Registrations",
              style: TextStyle(
                  color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text("Daily & monthly registration trends",
              style: TextStyle(color: textSecondary, fontSize: 12)),
          const SizedBox(height: 20),
          const SizedBox(height: 280, child: RegistrationChart()),
        ],
      ),
    );
  }
}

// ── Subscribers summary card ──────────────────────────────────────────────────

class _SubscribersCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _SubscribersCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = (stats['total_subscribers'] ?? 0) as int;
    final paid = (stats['paid_subscribers'] ?? 0) as int;
    final unpaid = (stats['unpaid_subscribers'] ?? 0) as int;
    final paidPct = total > 0 ? (paid / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Subscribers",
              style: TextStyle(
                  color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text("Paid vs unpaid breakdown",
              style: TextStyle(color: textSecondary, fontSize: 12)),
          const SizedBox(height: 24),

          // Total badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(total.toString(),
                    style: const TextStyle(
                        color: accentColor,
                        fontSize: 36,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                const Text("Total Subscribers",
                    style: TextStyle(color: accentColor, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: paidPct.toDouble(),
              minHeight: 8,
              backgroundColor: errorColor.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(successColor),
            ),
          ),
          const SizedBox(height: 16),

          // Paid / Unpaid rows
          _SubRow(label: "Paid", value: paid, color: successColor),
          const SizedBox(height: 10),
          _SubRow(label: "Unpaid", value: unpaid, color: errorColor),

          const SizedBox(height: 20),
          const Divider(color: borderColor),
          const SizedBox(height: 12),

          // Other summary numbers
          Row(
            children: [
              Expanded(
                  child: _MiniStat(
                      label: "Services",
                      value: stats['total_services'])),
              Expanded(
                  child: _MiniStat(
                      label: "Shops",
                      value: stats['total_shops'])),
              Expanded(
                  child: _MiniStat(
                      label: "Referrals",
                      value: stats['total_referrals'])),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _SubRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value.toString(),
            style: TextStyle(
                color: color, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final dynamic value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text((value ?? 0).toString(),
          style: const TextStyle(
              color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: textMuted, fontSize: 11)),
    ]);
  }
}

// ── DesCat breakdown grid ─────────────────────────────────────────────────────

class _DesCatGrid extends StatelessWidget {
  final List items;
  const _DesCatGrid({required this.items});

  static const List<Color> _palette = [
    Color(0xFF6366F1), Color(0xFF0EA5E9), Color(0xFF10B981),
    Color(0xFFF59E0B), Color(0xFF8B5CF6), Color(0xFFEF4444),
    Color(0xFFEC4899), Color(0xFF3B82F6), Color(0xFF14B8A6),
    Color(0xFFF97316),
  ];

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: const Center(
          child: Text("No designation categories found",
              style: TextStyle(color: textMuted)),
        ),
      );
    }

    return LayoutBuilder(builder: (context, c) {
      int cols = c.maxWidth >= 900 ? 4 : c.maxWidth >= 600 ? 3 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.0,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i] as Map<String, dynamic>;
          final color = _palette[i % _palette.length];
          return _DesCatCard(
            name: item['des_cat_name'] ?? '—',
            count: item['count'] ?? 0,
            isActive: (item['des_cat_status'] ?? 0) == 1,
            color: color,
          );
        },
      );
    });
  }
}

class _DesCatCard extends StatelessWidget {
  final String name;
  final int count;
  final bool isActive;
  final Color color;
  const _DesCatCard(
      {required this.name,
      required this.count,
      required this.isActive,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Color dot
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (!isActive)
                  const Text("Inactive",
                      style: TextStyle(color: textMuted, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
