import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/service_api/auth_headers.dart';

/// Business Summary — the health of AaramBD's lead business in one page.
///
/// Data: GET $host/api/summary-stats/ (Django, page key 'summary').
///   supply   -> profiles + service/shop listings
///   leads    -> calls & views received by providers
///   revenue  -> providers crossing the call/view threshold become
///               subscribers; paid ones x category subscription fee
///   growth   -> data-collector referrals
class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

// Chart series colours (on top of the panel's style.dart palette).
const Color _cCalls = accentColor; // indigo
const Color _cViews = Color(0xFF0EA5E9); // sky
const Color _cRegs = Color(0xFF22C55E); // green
const Color _cListings = Color(0xFFF59E0B); // amber

final NumberFormat _bdNum = NumberFormat('#,##,##0');
String _n(num v) => _bdNum.format(v);
String _tk(num v) => '৳${_bdNum.format(v)}';

int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

class _SummaryPageState extends State<SummaryPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool fresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('$host/api/summary-stats/${fresh ? '?fresh=1' : ''}');
      final res = await http
          .get(uri, headers: authHeaders())
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _data = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          _loading = false;
        });
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        setState(() {
          _error = 'You do not have access to the Business Summary.';
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Server returned ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          if (_loading && _data == null)
            const _Card(
              child: SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: accentColor)),
              ),
            )
          else if (_error != null && _data == null)
            _errorCard()
          else
            _body(_data!),
        ],
      ),
    );
  }

  Widget _header() {
    final generated = _data?['generated_at'] as String?;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, size: 22, color: accentColor),
          const SizedBox(width: 10),
          const Text('Business Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(width: 12),
          if (generated != null)
            Flexible(
              child: Text('Updated $generated',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: textMuted)),
            ),
          const Spacer(),
          if (_loading && _data != null)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: accentColor)),
            ),
          OutlinedButton.icon(
            onPressed: _loading ? null : () => _fetch(fresh: true),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: accentColor,
              side: const BorderSide(color: borderColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() => _Card(
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: errorColor, size: 32),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: textSecondary)),
            const SizedBox(height: 12),
            TextButton(onPressed: _fetch, child: const Text('Retry')),
          ],
        ),
      );

  Widget _body(Map<String, dynamic> d) {
    final kpis = (d['kpis'] as Map?)?.cast<String, dynamic>();
    final funnel = (d['funnel'] as List?) ?? const [];
    final trend = (d['trend'] as List?) ?? const [];
    final cats = (d['categories'] as List?) ?? const [];
    final dq = (d['data_quality'] as Map?)?.cast<String, dynamic>();
    final col = (d['collectors'] as Map?)?.cast<String, dynamic>();
    final errors = (d['errors'] as Map?)?.cast<String, dynamic>();

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 1100;
      Widget pair(Widget a, Widget b) => wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: a),
              const SizedBox(width: 16),
              Expanded(child: b),
            ])
          : Column(children: [a, const SizedBox(height: 16), b]);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errors != null && errors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _Card(
                color: const Color(0xFFFFFBEB),
                child: Text(
                  'Some sections could not be calculated: ${errors.keys.join(', ')}',
                  style: const TextStyle(color: Color(0xFF92400E), fontSize: 13),
                ),
              ),
            ),
          if (kpis != null) ...[
            _Insights(kpis: kpis, cats: cats, dq: dq, col: col),
            const SizedBox(height: 16),
            _KpiGrid(k: kpis),
            const SizedBox(height: 16),
          ],
          pair(
            _Section(
              icon: Icons.filter_alt_rounded,
              title: 'Lead → Revenue funnel',
              subtitle: kpis == null
                  ? null
                  : 'Threshold: more than ${kpis['call_threshold']} calls or ${kpis['view_threshold']} views',
              child: _Funnel(stages: funnel),
            ),
            _Section(
              icon: Icons.show_chart_rounded,
              title: 'Last 30 days',
              subtitle: 'Calls & views = customer–provider pairs last active that day',
              child: _TrendChart(rows: trend),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            icon: Icons.category_rounded,
            title: 'Categories: demand and money on the table',
            subtitle: 'Top categories by calls received. "Uncollected" = providers past the '
                'threshold who are not paying × category fee.',
            child: _CategorySection(cats: cats),
          ),
          const SizedBox(height: 16),
          pair(
            _Section(
              icon: Icons.health_and_safety_rounded,
              title: 'Data health',
              subtitle: 'Weak profiles get fewer calls — these are the fixes with most impact',
              child: _DataHealth(dq: dq),
            ),
            _Section(
              icon: Icons.group_add_rounded,
              title: 'Data collectors',
              subtitle: 'Referral onboarding, verification and payouts',
              child: _Collectors(col: col),
            ),
          ),
        ],
      );
    });
  }
}

// ── Building blocks ─────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final Color color;
  const _Card({required this.child, this.color = surface});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: child,
      );
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  const _Section({required this.icon, required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
              ),
            ]),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: const TextStyle(fontSize: 12, color: textSecondary)),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      );
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty([this.text = 'No data yet']);
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 80,
        child: Center(child: Text(text, style: const TextStyle(color: textMuted))),
      );
}

// ── Auto insights ───────────────────────────────────────────────────────────

class _Insights extends StatelessWidget {
  final Map<String, dynamic> kpis;
  final List cats;
  final Map<String, dynamic>? dq;
  final Map<String, dynamic>? col;
  const _Insights({required this.kpis, required this.cats, this.dq, this.col});

  List<String> _lines() {
    final out = <String>[];
    final unpaid = _i(kpis['unpaid_qualified']);
    final uncollected = _i(kpis['uncollected_value']);
    if (unpaid > 0) {
      out.add('$unpaid providers have crossed the lead threshold but are not paying '
          '— ${_tk(uncollected)} in subscription fees to follow up.');
    }
    if (cats.isNotEmpty) {
      final byUncollected = [...cats]
        ..sort((a, b) => _i(b['uncollected_value']).compareTo(_i(a['uncollected_value'])));
      final top = byUncollected.first;
      if (_i(top['uncollected_value']) > 0) {
        out.add('Biggest follow-up opportunity: ${top['name']} '
            '(${_tk(_i(top['uncollected_value']))} uncollected).');
      }
      final byDemand = [...cats]
        ..sort((a, b) => _d(b['calls_per_user']).compareTo(_d(a['calls_per_user'])));
      final hot = byDemand.first;
      out.add('Highest demand per provider: ${hot['name']} '
          '(${hot['calls_per_user']} calls per profile) — recruit more providers here.');
    }
    final cur = _i(kpis['call_leads_30d']);
    final prev = _i(kpis['call_leads_prev30']);
    if (prev > 0) {
      final ch = ((cur - prev) / prev * 100).round();
      out.add('Call leads are ${ch >= 0 ? 'up' : 'down'} ${ch.abs()}% vs the previous 30 days.');
    }
    final issues = (dq?['issues'] as List?) ?? const [];
    final noPhoto = issues.cast<Map>().where((e) => e['key'] == 'no_photo').toList();
    if (noPhoto.isNotEmpty && _d(noPhoto.first['pct']) >= 30) {
      out.add('${noPhoto.first['pct']}% of profiles have no photo — '
          'give your data collectors this as a target.');
    }
    final due = _i(col?['points_due']);
    if (due > 0) out.add('$due referral points are verified but not yet paid to data collectors.');
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final lines = _lines();
    if (lines.isEmpty) return const SizedBox.shrink();
    return _Card(
      color: accentLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.lightbulb_rounded, size: 18, color: accentColor),
            SizedBox(width: 8),
            Text('What needs attention',
                style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
          ]),
          const SizedBox(height: 10),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: 8),
                  child: Icon(Icons.circle, size: 6, color: accentColor),
                ),
                Expanded(
                    child: Text(l,
                        style: const TextStyle(fontSize: 13, color: textPrimary, height: 1.4))),
              ]),
            ),
        ],
      ),
    );
  }
}

// ── KPI grid ────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final Map<String, dynamic> k;
  const _KpiGrid({required this.k});

  String? _delta(int cur, int prev) {
    if (prev <= 0) return null;
    final p = ((cur - prev) / prev * 100).round();
    return '${p >= 0 ? '+' : ''}$p% vs prev 30d';
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <_Kpi>[
      _Kpi('Active users', _n(_i(k['active_users'])),
          'of ${_n(_i(k['total_users']))} · ${_n(_i(k['monthly_active']))} opened app in 30d',
          Icons.people_alt_rounded),
      _Kpi('New users (30d)', _n(_i(k['new_users_30d'])),
          _delta(_i(k['new_users_30d']), _i(k['new_users_prev30'])) ?? 'registrations',
          Icons.person_add_alt_1_rounded,
          positive: _i(k['new_users_30d']) >= _i(k['new_users_prev30'])),
      _Kpi('Listings', _n(_i(k['service_listings']) + _i(k['shop_listings'])),
          '${_n(_i(k['service_listings']))} services · ${_n(_i(k['shop_listings']))} shops · '
          '+${_n(_i(k['new_listings_30d']))} in 30d',
          Icons.storefront_rounded),
      _Kpi('Call leads (30d)', _n(_i(k['call_leads_30d'])),
          _delta(_i(k['call_leads_30d']), _i(k['call_leads_prev30'])) ??
              '${_n(_i(k['customers_called_30d']))} customers called',
          Icons.call_rounded,
          positive: _i(k['call_leads_30d']) >= _i(k['call_leads_prev30'])),
      _Kpi('View leads (30d)', _n(_i(k['view_leads_30d'])),
          '${k['call_leads_per_active_profile_30d']} call leads per active profile',
          Icons.visibility_rounded),
      _Kpi('Paid subscribers', _n(_i(k['paid_subscribers'])),
          '${_tk(_i(k['paid_subscription_value']))} subscription value',
          Icons.verified_rounded,
          accent: successColor),
      _Kpi('Uncollected', _tk(_i(k['uncollected_value'])),
          '${_n(_i(k['unpaid_qualified']))} providers past threshold, not paying',
          Icons.savings_rounded,
          accent: warningColor),
      _Kpi('Threshold → paid', '${k['qualified_to_paid_pct']}%',
          '${_n(_i(k['paid_subscribers']))} of ${_n(_i(k['qualified_providers']))} qualified providers',
          Icons.trending_up_rounded),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 1200 ? 4 : c.maxWidth >= 700 ? 2 : 1;
      final w = (c.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final t in tiles) SizedBox(width: w, child: t)],
      );
    });
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color accent;
  final bool? positive;
  const _Kpi(this.label, this.value, this.sub, this.icon,
      {this.accent = accentColor, this.positive});

  @override
  Widget build(BuildContext context) {
    final subColor = positive == null
        ? textSecondary
        : positive!
            ? const Color(0xFF15803D)
            : errorColor;
    return Container(
      height: 112,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: textSecondary)),
            ),
          ]),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 2),
          Text(sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: subColor)),
        ],
      ),
    );
  }
}

// ── Funnel ──────────────────────────────────────────────────────────────────

class _Funnel extends StatelessWidget {
  final List stages;
  const _Funnel({required this.stages});

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) return const _Empty();
    final top = math.max(1, _i(stages.first['count']));
    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _funnelRow(
              stages[i]['stage'] as String,
              _i(stages[i]['count']),
              top,
              i == 0 ? null : _i(stages[i - 1]['count']),
              i,
            ),
          ),
      ],
    );
  }

  Widget _funnelRow(String label, int count, int top, int? prev, int index) {
    final frac = count / top;
    final conv = (prev == null || prev == 0) ? null : (count / prev * 100);
    final shade = Color.lerp(accentColor, const Color(0xFF22C55E), index / 4)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: Text(label, style: const TextStyle(fontSize: 13, color: textPrimary))),
          Text(_n(count),
              style: const TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
          if (conv != null)
            SizedBox(
              width: 70,
              child: Text('${conv.toStringAsFixed(conv < 10 ? 1 : 0)}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, color: textSecondary)),
            )
          else
            const SizedBox(width: 70),
        ]),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, c) => Stack(children: [
            Container(
                height: 12,
                width: c.maxWidth,
                decoration: BoxDecoration(
                    color: background, borderRadius: BorderRadius.circular(6))),
            Container(
                height: 12,
                width: math.max(4, c.maxWidth * frac),
                decoration:
                    BoxDecoration(color: shade, borderRadius: BorderRadius.circular(6))),
          ]),
        ),
      ],
    );
  }
}

// ── 30-day trend ────────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  final List rows;
  const _TrendChart({required this.rows});

  static const _series = [
    ('call_leads', 'Call leads', _cCalls),
    ('view_leads', 'View leads', _cViews),
    ('registrations', 'New users', _cRegs),
    ('new_listings', 'New listings', _cListings),
  ];

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const _Empty();
    double maxY = 1;
    for (final r in rows) {
      for (final s in _series) {
        maxY = math.max(maxY, _d(r[s.$1]));
      }
    }
    final yStep = _niceStep(maxY / 4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: ((maxY / yStep).ceil() * yStep).toDouble(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yStep,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: borderColor, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: yStep,
                    getTitlesWidget: (v, meta) => Text(_n(v.round()),
                        style: const TextStyle(fontSize: 10, color: textMuted)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 7,
                    getTitlesWidget: (v, meta) {
                      final i = v.round();
                      if (i < 0 || i >= rows.length) return const SizedBox.shrink();
                      final dt = DateTime.tryParse('${rows[i]['date']}');
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(dt == null ? '' : DateFormat('d MMM').format(dt),
                            style: const TextStyle(fontSize: 10, color: textMuted)),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => sidebarBg,
                  getTooltipItems: (spots) => spots.map((s) {
                    final series = _series[s.barIndex];
                    final dt = DateTime.tryParse('${rows[s.x.round()]['date']}');
                    final head = s == spots.first && dt != null
                        ? '${DateFormat('d MMM').format(dt)}\n'
                        : '';
                    return LineTooltipItem(
                      '$head${series.$2}: ${s.y.round()}',
                      TextStyle(color: series.$3, fontSize: 11, fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                for (final s in _series)
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < rows.length; i++) FlSpot(i.toDouble(), _d(rows[i][s.$1]))
                    ],
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: s.$3,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 6, children: [
          for (final s in _series) _Legend(color: s.$3, label: s.$2),
        ]),
      ],
    );
  }
}

double _niceStep(double raw) {
  if (raw <= 1) return 1;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final n = raw / mag;
  final nice = n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10;
  return (nice * mag).toDouble();
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: textSecondary)),
      ]);
}

// ── Categories ──────────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final List cats;
  const _CategorySection({required this.cats});

  @override
  Widget build(BuildContext context) {
    if (cats.isEmpty) return const _Empty('No calls or views recorded yet');
    final chartCats = cats.take(10).toList();
    final maxCalls = chartCats.map((c) => _d(c['calls'])).fold<double>(1, (a, b) => math.max(a, b));
    final step = _niceStep(maxCalls / 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: ((maxCalls / step).ceil() * step).toDouble(),
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: step,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: borderColor, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: step,
                    getTitlesWidget: (v, meta) => Text(_n(v.round()),
                        style: const TextStyle(fontSize: 10, color: textMuted)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (v, meta) {
                      final i = v.round();
                      if (i < 0 || i >= chartCats.length) return const SizedBox.shrink();
                      final name = '${chartCats[i]['name']}';
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SizedBox(
                          width: 72,
                          child: Text(name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: textSecondary)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => sidebarBg,
                  getTooltipItem: (group, gi, rod, ri) {
                    final c = chartCats[group.x];
                    return BarTooltipItem(
                      '${c['name']}\n${_n(_i(c['calls']))} calls · ${_n(_i(c['views']))} views',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  },
                ),
              ),
              barGroups: [
                for (var i = 0; i < chartCats.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: _d(chartCats[i]['calls']),
                      width: 18,
                      color: _i(chartCats[i]['uncollected_value']) > 0 ? warningColor : _cCalls,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Wrap(spacing: 16, children: [
          _Legend(color: _cCalls, label: 'Calls received'),
          _Legend(color: warningColor, label: 'Has uncollected subscription fees'),
        ]),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 36,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 40,
            columnSpacing: 22,
            headingTextStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
            dataTextStyle: const TextStyle(fontSize: 12.5, color: textPrimary),
            columns: const [
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Profiles'), numeric: true),
              DataColumn(label: Text('Listings'), numeric: true),
              DataColumn(label: Text('Calls'), numeric: true),
              DataColumn(label: Text('Views'), numeric: true),
              DataColumn(label: Text('Calls / profile'), numeric: true),
              DataColumn(label: Text('Past threshold'), numeric: true),
              DataColumn(label: Text('Paid'), numeric: true),
              DataColumn(label: Text('Fee'), numeric: true),
              DataColumn(label: Text('Uncollected'), numeric: true),
            ],
            rows: [
              for (final c in cats)
                DataRow(cells: [
                  DataCell(Text('${c['name']}')),
                  DataCell(Text(_n(_i(c['users'])))),
                  DataCell(Text(_n(_i(c['listings'])))),
                  DataCell(Text(_n(_i(c['calls'])))),
                  DataCell(Text(_n(_i(c['views'])))),
                  DataCell(Text('${c['calls_per_user']}')),
                  DataCell(Text(_n(_i(c['qualified'])))),
                  DataCell(Text(_n(_i(c['paid'])))),
                  DataCell(Text(_i(c['fee']) == 0 ? 'Free' : _tk(_i(c['fee'])))),
                  DataCell(Text(
                    _i(c['uncollected_value']) == 0 ? '—' : _tk(_i(c['uncollected_value'])),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _i(c['uncollected_value']) > 0
                          ? const Color(0xFFB45309)
                          : textMuted,
                    ),
                  )),
                ]),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Data health ─────────────────────────────────────────────────────────────

class _DataHealth extends StatelessWidget {
  final Map<String, dynamic>? dq;
  const _DataHealth({this.dq});

  @override
  Widget build(BuildContext context) {
    final issues = (dq?['issues'] as List?) ?? const [];
    if (issues.isEmpty) return const _Empty();
    return Column(
      children: [
        for (final it in issues)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _bar('${it['label']}', _i(it['count']), _d(it['pct'])),
          ),
      ],
    );
  }

  Widget _bar(String label, int count, double pct) {
    final color = pct >= 40
        ? errorColor
        : pct >= 15
            ? warningColor
            : successColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: textPrimary))),
          Text('${_n(count)}  ·  $pct%',
              style: const TextStyle(fontSize: 12, color: textSecondary)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: background,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ── Data collectors ─────────────────────────────────────────────────────────

class _Collectors extends StatelessWidget {
  final Map<String, dynamic>? col;
  const _Collectors({this.col});

  @override
  Widget build(BuildContext context) {
    if (col == null) return const _Empty();
    final c = col!;
    final verified = _i(c['verified']);
    final waiting = _i(c['waiting']);
    final unverified = _i(c['unverified']);
    final total = verified + waiting + unverified;
    final top = (c['top_collectors_90d'] as List?) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 10, runSpacing: 10, children: [
          _chip('Referrals', _n(_i(c['total']))),
          _chip('Last 30 days', _n(_i(c['last_30d']))),
          _chip('Verified', '${c['verified_pct']}%'),
          _chip('Points due', _n(_i(c['points_due'])), warn: _i(c['points_due']) > 0),
          _chip('Points paid', _n(_i(c['points_paid']))),
        ]),
        const SizedBox(height: 16),
        if (total > 0) ...[
          SizedBox(
            height: 140,
            child: Row(children: [
              SizedBox(
                width: 140,
                child: PieChart(PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 34,
                  sections: [
                    _slice(verified, successColor),
                    _slice(waiting, warningColor),
                    _slice(unverified, errorColor),
                  ],
                )),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Legend(color: successColor, label: 'Verified  ${_n(verified)}'),
                  const SizedBox(height: 6),
                  _Legend(color: warningColor, label: 'Waiting  ${_n(waiting)}'),
                  const SizedBox(height: 6),
                  _Legend(color: errorColor, label: 'Unverified  ${_n(unverified)}'),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 16),
        ],
        const Text('Top collectors (90 days)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 8),
        if (top.isEmpty)
          const _Empty('No referrals in the last 90 days')
        else
          for (final t in top)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Expanded(
                    child: Text('${t['name']}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: textPrimary))),
                SizedBox(
                    width: 90,
                    child: Text('${_n(_i(t['referrals']))} referred',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12, color: textSecondary))),
                SizedBox(
                    width: 80,
                    child: Text('${_n(_i(t['verified']))} verified',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12, color: textSecondary))),
                SizedBox(
                    width: 70,
                    child: Text(_i(t['points_due']) > 0 ? '${_n(_i(t['points_due']))} due' : '—',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _i(t['points_due']) > 0
                                ? const Color(0xFFB45309)
                                : textMuted))),
              ]),
            ),
      ],
    );
  }

  PieChartSectionData _slice(int v, Color color) => PieChartSectionData(
        value: v.toDouble(),
        color: color,
        radius: 22,
        showTitle: false,
      );

  Widget _chip(String label, String value, {bool warn = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: warn ? const Color(0xFFFFFBEB) : background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: warn ? const Color(0xFFFDE68A) : borderColor),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
        ]),
      );
}
