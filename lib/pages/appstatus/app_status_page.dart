import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/service_api/auth_headers.dart';

class AppStatusPage extends StatefulWidget {
  const AppStatusPage({super.key});

  @override
  State<AppStatusPage> createState() => _AppStatusPageState();
}

class _AppStatusPageState extends State<AppStatusPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  // API health state
  final List<_EndpointStatus> _endpoints = [
    _EndpointStatus('Overview Stats',   '/api/overview-stats/'),
    _EndpointStatus('Categories',       '/api/cat'),
    _EndpointStatus('Users',            '/api/get-users/'),
    _EndpointStatus('Services',         '/api/service-users/'),
    _EndpointStatus('Shops',            '/api/shop-users/'),
    _EndpointStatus('App Status',       '/api/app-status/'),
  ];
  bool _healthChecking = false;
  bool _healthDone = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse('$host/api/app-status/'), headers: authHeaders())
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        setState(() { _data = json.decode(res.body); _loading = false; });
      } else {
        setState(() { _error = 'Server returned ${res.statusCode}'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _runHealthCheck() async {
    if (_healthChecking) return;
    setState(() { _healthChecking = true; _healthDone = false; });
    for (final ep in _endpoints) {
      ep.reset();
    }
    await Future.wait(_endpoints.map((ep) => ep.ping()));
    if (mounted) setState(() { _healthChecking = false; _healthDone = true; });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded, size: 22, color: accentColor),
                const SizedBox(width: 10),
                const Text('App Status',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
                const Spacer(),
                _RefreshButton(onTap: _fetchData),
              ],
            ),
          ),

          // Section 1 — API Health
          _SectionHeader(
            icon: Icons.wifi_tethering_rounded,
            title: 'API Health Monitor',
            trailing: TextButton.icon(
              onPressed: _healthChecking ? null : _runHealthCheck,
              icon: _healthChecking
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: accentColor))
                  : const Icon(Icons.play_arrow_rounded, size: 16, color: accentColor),
              label: Text(_healthChecking ? 'Checking...' : 'Run Check',
                  style: const TextStyle(fontSize: 13, color: accentColor)),
            ),
          ),
          const SizedBox(height: 10),
          _HealthMonitorCard(
            endpoints: _endpoints,
            done: _healthDone,
            checking: _healthChecking,
          ),

          const SizedBox(height: 24),

          // Section 2 — Content Health
          const _SectionHeader(
            icon: Icons.health_and_safety_rounded,
            title: 'Content Health',
          ),
          const SizedBox(height: 10),
          _loading
              ? _LoadingCard()
              : _error != null
                  ? _ErrorCard(error: _error!, onRetry: _fetchData)
                  : _ContentHealthCard(data: _data!['content_health']),

          const SizedBox(height: 24),

          // Section 3 — Growth
          const _SectionHeader(
            icon: Icons.trending_up_rounded,
            title: 'Platform Growth',
          ),
          const SizedBox(height: 10),
          _loading
              ? _LoadingCard()
              : _error != null
                  ? _ErrorCard(error: _error!, onRetry: _fetchData)
                  : _GrowthCard(data: _data!['growth']),
        ],
      ),
    );
  }
}

// ── API Health ─────────────────────────────────────────────────────────────

class _EndpointStatus {
  final String name;
  final String path;
  bool? isUp;
  int? ms;
  bool checking = false;

  _EndpointStatus(this.name, this.path);

  void reset() { isUp = null; ms = null; checking = true; }

  Future<void> ping() async {
    final sw = Stopwatch()..start();
    try {
      final res = await http.get(Uri.parse('$host$path'), headers: authHeaders())
          .timeout(const Duration(seconds: 8));
      sw.stop();
      isUp = res.statusCode < 500;
      ms = sw.elapsedMilliseconds;
    } catch (_) {
      sw.stop();
      isUp = false;
      ms = sw.elapsedMilliseconds;
    }
    checking = false;
  }
}

class _HealthMonitorCard extends StatelessWidget {
  final List<_EndpointStatus> endpoints;
  final bool done;
  final bool checking;

  const _HealthMonitorCard({
    required this.endpoints,
    required this.done,
    required this.checking,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: !done && !checking
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 36, color: textMuted),
                    SizedBox(height: 8),
                    Text('Press "Run Check" to test all endpoints',
                        style: TextStyle(color: textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            )
          : Column(
              children: endpoints.map((ep) => _EndpointRow(ep: ep)).toList(),
            ),
    );
  }
}

class _EndpointRow extends StatelessWidget {
  final _EndpointStatus ep;
  const _EndpointRow({required this.ep});

  @override
  Widget build(BuildContext context) {
    final isUp = ep.isUp;
    final color = ep.checking
        ? warningColor
        : isUp == null
            ? textMuted
            : isUp
                ? successColor
                : errorColor;

    final label = ep.checking
        ? 'Checking...'
        : isUp == null
            ? '—'
            : isUp
                ? 'UP'
                : 'DOWN';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(ep.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
          ),
          Text(ep.path,
              style: const TextStyle(fontSize: 11, color: textMuted)),
          const SizedBox(width: 16),
          if (ep.ms != null)
            Text('${ep.ms}ms',
                style: TextStyle(
                    fontSize: 12,
                    color: ep.ms! < 300 ? successColor : ep.ms! < 800 ? warningColor : errorColor,
                    fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}

// ── Content Health ─────────────────────────────────────────────────────────

class _ContentHealthCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ContentHealthCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final activeUsers   = data['active_users']   as int;
    final inactiveUsers = data['inactive_users'] as int;
    final activeCats    = data['active_cats']    as int;
    final inactiveCats  = data['inactive_cats']  as int;
    final paidSubs      = data['paid_subs']      as int;
    final freeSubs      = data['free_subs']      as int;

    return _Card(
      child: Column(
        children: [
          _HealthBar(
            label: 'Users',
            icon: Icons.people_rounded,
            activeCount: activeUsers,
            inactiveCount: inactiveUsers,
            activeLabel: 'Active',
            inactiveLabel: 'Inactive',
            activeColor: successColor,
            inactiveColor: errorColor,
          ),
          const Divider(height: 28, color: borderColor),
          _HealthBar(
            label: 'Categories',
            icon: Icons.category_rounded,
            activeCount: activeCats,
            inactiveCount: inactiveCats,
            activeLabel: 'Active',
            inactiveLabel: 'Inactive',
            activeColor: successColor,
            inactiveColor: errorColor,
          ),
          const Divider(height: 28, color: borderColor),
          _HealthBar(
            label: 'Subscribers',
            icon: Icons.subscriptions_rounded,
            activeCount: paidSubs,
            inactiveCount: freeSubs,
            activeLabel: 'Paid',
            inactiveLabel: 'Free',
            activeColor: accentColor,
            inactiveColor: textMuted,
          ),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final int activeCount;
  final int inactiveCount;
  final String activeLabel;
  final String inactiveLabel;
  final Color activeColor;
  final Color inactiveColor;

  const _HealthBar({
    required this.label,
    required this.icon,
    required this.activeCount,
    required this.inactiveCount,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = activeCount + inactiveCount;
    final ratio = total == 0 ? 0.0 : activeCount / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: textSecondary),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
            const Spacer(),
            _LegendDot(color: activeColor, label: '$activeLabel: $activeCount'),
            const SizedBox(width: 16),
            _LegendDot(color: inactiveColor, label: '$inactiveLabel: $inactiveCount'),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: inactiveColor.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(activeColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          total == 0 ? 'No data' : '${(ratio * 100).toStringAsFixed(1)}% $activeLabel',
          style: const TextStyle(fontSize: 11, color: textSecondary),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: textSecondary)),
      ],
    );
  }
}

// ── Growth ─────────────────────────────────────────────────────────────────

class _GrowthCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _GrowthCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _GrowthRow(
            icon: Icons.app_registration_rounded,
            label: 'Registrations',
            color: accentColor,
            today: data['registrations']['today'] as int,
            week:  data['registrations']['week']  as int,
            month: data['registrations']['month'] as int,
          ),
          const Divider(height: 28, color: borderColor),
          _GrowthRow(
            icon: Icons.miscellaneous_services_rounded,
            label: 'Services',
            color: successColor,
            today: data['services']['today'] as int,
            week:  data['services']['week']  as int,
            month: data['services']['month'] as int,
          ),
          const Divider(height: 28, color: borderColor),
          _GrowthRow(
            icon: Icons.storefront_rounded,
            label: 'Shops',
            color: warningColor,
            today: data['shops']['today'] as int,
            week:  data['shops']['week']  as int,
            month: data['shops']['month'] as int,
          ),
        ],
      ),
    );
  }
}

class _GrowthRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int today;
  final int week;
  final int month;

  const _GrowthRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.today,
    required this.week,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        ),
        _GrowthStat(label: 'Today', value: today, color: color),
        const SizedBox(width: 12),
        _GrowthStat(label: '7 Days', value: week, color: color),
        const SizedBox(width: 12),
        _GrowthStat(label: '30 Days', value: month, color: color),
      ],
    );
  }
}

class _GrowthStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _GrowthStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: textSecondary)),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accentColor),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: child,
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _Card(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(color: accentColor),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: errorColor, size: 36),
              const SizedBox(height: 8),
              Text(error,
                  style: const TextStyle(color: textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: TextButton.styleFrom(foregroundColor: accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RefreshButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: accentLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 15, color: accentColor),
            SizedBox(width: 5),
            Text('Refresh', style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
