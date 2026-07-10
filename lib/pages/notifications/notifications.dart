import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/service_api/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Color palette (matches dashboard style)
// ─────────────────────────────────────────────────────────────────────────────
const _blue   = Color(0xFF6366F1);
const _green  = Color(0xFF22C55E);
const _red    = Color(0xFFEF4444);
const _amber  = Color(0xFFF59E0B);
const _bg     = Color(0xFFF8FAFC);
const _card   = Colors.white;
const _border = Color(0xFFE2E8F0);
const _textH  = Color(0xFF0F172A);
const _textM  = Color(0xFF475569);
const _textL  = Color(0xFF94A3B8);

// ─────────────────────────────────────────────────────────────────────────────

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Container(
            color: _card,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Push Notifications',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _textH)),
                const SizedBox(height: 4),
                const Text(
                    'Manage notification routing rules, send broadcasts, and view send history.',
                    style: TextStyle(fontSize: 13, color: _textM)),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabs,
                  labelColor: _blue,
                  unselectedLabelColor: _textM,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  indicatorColor: _blue,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: '📋  Rules'),
                    Tab(text: '📢  Broadcast'),
                    Tab(text: '📊  Send Log'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),

          // ── Tab views ────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _RulesTab(),
                _BroadcastTab(),
                _LogTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Tab 1 — Notification Rules
// ═════════════════════════════════════════════════════════════════════════════

class _RulesTab extends StatefulWidget {
  const _RulesTab();

  @override
  State<_RulesTab> createState() => _RulesTabState();
}

class _RulesTabState extends State<_RulesTab> {
  List<dynamic> _rules     = [];
  bool          _loading   = true;
  String?       _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rules = await NotificationAdminService.fetchRules();
      if (mounted) setState(() { _rules = rules; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggle(Map rule) async {
    final newVal = !(rule['is_active'] as bool);
    try {
      await NotificationAdminService.toggleRule(rule['rule_id'] as int, newVal);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update rule: $e')));
      }
    }
  }

  Future<void> _delete(Map rule) async {
    final confirmed = await _confirm(
        context, 'Delete rule "${rule['rule_name']}"?');
    if (!confirmed) return;
    try {
      final ok = await NotificationAdminService.deleteRule(rule['rule_id'] as int);
      if (!mounted) return;
      if (ok) {
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete rule')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete rule: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              const Text('Routing Rules',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textH)),
              const Spacer(),
              _OutlineButton(
                  label: 'Refresh',
                  icon: Icons.refresh_rounded,
                  onTap: _load),
              const SizedBox(width: 10),
              _PrimaryButton(
                  label: 'Add Rule',
                  icon: Icons.add_rounded,
                  onTap: () => _showAddDialog()),
            ],
          ),
        ),
        const Divider(height: 1, color: _border),

        // Content
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _blue));
    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: _red)));
    }
    if (_rules.isEmpty) {
      return const Center(
          child: Text('No rules yet. Add one to get started.',
              style: TextStyle(color: _textM)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _rules.length,
      itemBuilder: (_, i) => _RuleCard(
        rule: _rules[i],
        onToggle: () => _toggle(_rules[i]),
        onDelete: () => _delete(_rules[i]),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => _AddRuleDialog(onSaved: _load),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final dynamic rule;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _RuleCard(
      {required this.rule, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final active  = rule['is_active'] as bool;
    final catIds  = (rule['target_cat_ids'] as List?) ?? [];
    final catNames = (rule['target_cat_names'] as List?) ?? [];
    final subName = (rule['des_sub_cat_name'] as String?) ?? '';
    final catName = (rule['des_cat_name'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? _blue.withValues(alpha: 0.25) : _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: active ? _green : _textL,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(rule['rule_name'] ?? '',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textH)),
                    const SizedBox(width: 8),
                    _StatusChip(active: active),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  _InfoChip(
                      icon: Icons.category_rounded,
                      label: catName.isEmpty ? 'Cat ${rule['des_cat_id']}' : catName,
                      color: _blue),
                  if (subName.isNotEmpty)
                    _InfoChip(
                        icon: Icons.subdirectory_arrow_right_rounded,
                        label: subName,
                        color: const Color(0xFF8B5CF6)),
                  if (catIds.isEmpty)
                    const _InfoChip(
                        icon: Icons.people_rounded,
                        label: 'All users',
                        color: _amber)
                  else
                    ...catNames.take(3).map((n) => _InfoChip(
                        icon: Icons.person_rounded,
                        label: n.toString(),
                        color: _green)),
                  if (catIds.length > 3)
                    _InfoChip(
                        icon: Icons.more_horiz_rounded,
                        label: '+${catIds.length - 3} more',
                        color: _textL),
                ]),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: active,
                onChanged: (_) => onToggle(),
                activeThumbColor: _blue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: _red),
                onPressed: onDelete,
                tooltip: 'Delete rule',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddRuleDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddRuleDialog({required this.onSaved});

  @override
  State<_AddRuleDialog> createState() => _AddRuleDialogState();
}

class _AddRuleDialogState extends State<_AddRuleDialog> {
  final _nameCtrl   = TextEditingController();
  final _searchCtrl = TextEditingController();

  List<dynamic>  _desCats      = [];
  List<dynamic>  _desSubs      = [];
  List<dynamic>  _userCats     = [];
  List<dynamic>  _filteredCats = [];
  int?           _selDesCat;
  int            _selDesSub    = 0;
  final Set<int> _selUserCats  = {};
  bool           _saving       = false;
  bool           _subsLoading  = false;
  String?        _err;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
    _searchCtrl.addListener(_filterCats);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    final desCats  = await NotificationAdminService.fetchDesCategories();
    final userCats = await NotificationAdminService.fetchUserCategories();
    if (mounted) {
      setState(() {
        _desCats      = desCats;
        _userCats     = userCats;
        _filteredCats = userCats;
      });
    }
  }

  void _filterCats() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredCats = q.isEmpty
          ? _userCats
          : _userCats.where((c) =>
              (c['cat_name'] as String).toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _onDesCatChanged(int? id) async {
    setState(() { _selDesCat = id; _desSubs = []; _selDesSub = 0; _subsLoading = true; });
    if (id != null) {
      final subs = await NotificationAdminService.fetchDesSubCategories(id);
      if (mounted) setState(() { _desSubs = subs; _subsLoading = false; });
    } else {
      setState(() => _subsLoading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selDesCat == null) {
      setState(() => _err = 'Rule name and post category are required.');
      return;
    }
    setState(() { _saving = true; _err = null; });
    try {
      await NotificationAdminService.createRule(
        ruleName:     name,
        desCatId:     _selDesCat!,
        desSubCatId:  _selDesSub,
        targetCatIds: _selUserCats.toList(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      setState(() { _err = e.toString(); _saving = false; });
    }
  }

  String get _selDesCatName {
    if (_selDesCat == null) return '';
    final c = _desCats.firstWhere(
        (c) => c['des_cat_id'] == _selDesCat, orElse: () => null);
    return c?['des_cat_name'] ?? '';
  }

  String get _selDesSubName {
    if (_selDesSub == 0) return 'সব সাব-ক্যাটাগরি';
    final s = _desSubs.firstWhere(
        (s) => s['des_sub_cat_id'] == _selDesSub, orElse: () => null);
    if (s == null) return '';
    return '${s['emoji'] ?? ''} ${s['name'] ?? ''}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final selCatNames = _userCats
        .where((c) => _selUserCats.contains(c['cat_id'] as int))
        .map((c) => c['cat_name'] as String)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 720,
        height: 620,
        child: Row(
          children: [
            // ── Left panel: rule config ──────────────────────────────────
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.rule_rounded,
                            color: _blue, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('নতুন নোটিফিকেশন রুল',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _textH)),
                          Text('কখন কাকে নোটিফিকেশন যাবে',
                              style: TextStyle(
                                  fontSize: 11, color: _textM)),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 20),
                    const Divider(color: _border),
                    const SizedBox(height: 16),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Rule Name
                            _FieldLabel('রুলের নাম'),
                            TextField(
                              controller: _nameCtrl,
                              decoration: _inputDeco(
                                  'e.g. বিক্রয় পোস্ট → সার্ভিস প্রোভাইডার'),
                            ),
                            const SizedBox(height: 16),

                            // Post Category
                            _FieldLabel('পোস্ট ক্যাটাগরি (des_cat)'),
                            DropdownButtonFormField<int>(
                              // ignore: deprecated_member_use
                              value: _selDesCat,
                              hint: const Text('ক্যাটাগরি বেছে নিন',
                                  style: TextStyle(fontSize: 13)),
                              decoration: _inputDeco(null),
                              isExpanded: true,
                              items: _desCats.map<DropdownMenuItem<int>>((c) {
                                return DropdownMenuItem(
                                  value: c['des_cat_id'] as int,
                                  child: Text(c['des_cat_name'] as String,
                                      style:
                                          const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: _onDesCatChanged,
                            ),
                            const SizedBox(height: 16),

                            // Sub-category — key forces rebuild when cat changes
                            _FieldLabel('সাব-ক্যাটাগরি'),
                            if (_subsLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: LinearProgressIndicator(color: _blue),
                              )
                            else
                              DropdownButtonFormField<int>(
                                key: ValueKey('sub_$_selDesCat'),
                                // ignore: deprecated_member_use
                                value: _selDesSub,
                                decoration: _inputDeco(null),
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem(
                                    value: 0,
                                    child: Text('🔁  সব সাব-ক্যাটাগরি',
                                        style: TextStyle(fontSize: 13)),
                                  ),
                                  ..._desSubs
                                      .map<DropdownMenuItem<int>>((s) {
                                    return DropdownMenuItem(
                                      value: s['des_sub_cat_id'] as int,
                                      child: Text(
                                        '${s['emoji'] ?? ''}  ${s['name'] ?? ''}',
                                        style:
                                            const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (v) =>
                                    setState(() => _selDesSub = v ?? 0),
                              ),
                            const SizedBox(height: 20),

                            // Preview summary
                            if (_selDesCat != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _blue.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: _blue.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('রুল সারসংক্ষেপ',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: _blue)),
                                    const SizedBox(height: 6),
                                    Text(
                                      '"$_selDesCatName" → "$_selDesSubName" পোস্ট হলে '
                                      '${_selUserCats.isEmpty ? "সব ইউজার" : "${_selUserCats.length}টি ক্যাটাগরি"}কে নোটিফাই করবে।',
                                      style: const TextStyle(
                                          fontSize: 12, color: _textH),
                                    ),
                                  ],
                                ),
                              ),

                            if (_err != null) ...[
                              const SizedBox(height: 10),
                              Text(_err!,
                                  style: const TextStyle(
                                      color: _red, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _border),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('বাতিল',
                              style: TextStyle(color: _textM)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Text('সেভ করুন',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            // Divider
            Container(width: 1, color: _border),

            // ── Right panel: category selector ───────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('টার্গেট ইউজার ক্যাটাগরি',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _textH)),
                            Text('ফাঁকা রাখলে সবাই পাবে',
                                style:
                                    TextStyle(fontSize: 11, color: _textM)),
                          ],
                        ),
                      ),
                      if (_selUserCats.isNotEmpty)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selUserCats.clear()),
                          child: const Text('Clear all',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _red,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ]),
                    const SizedBox(height: 10),

                    // Selected chips
                    if (selCatNames.isNotEmpty) ...[
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: selCatNames.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 6),
                          itemBuilder: (_, i) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(selCatNames[i],
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      final id = _userCats.firstWhere(
                                              (c) =>
                                                  c['cat_name'] ==
                                                  selCatNames[i])[
                                          'cat_id'] as int;
                                      setState(
                                          () => _selUserCats.remove(id));
                                    },
                                    child: const Icon(Icons.close_rounded,
                                        size: 12, color: Colors.white70),
                                  ),
                                ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Search box
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'ক্যাটাগরি খুঁজুন...',
                        hintStyle: const TextStyle(
                            fontSize: 12, color: _textL),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 16, color: _textL),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    size: 14),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _filterCats();
                                })
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: _border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: _border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: _blue, width: 1.5)),
                        filled: true,
                        fillColor: _bg,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Count + select-all row
                    Row(children: [
                      Text(
                        '${_filteredCats.length} ক্যাটাগরি',
                        style: const TextStyle(
                            fontSize: 11, color: _textL),
                      ),
                      const Spacer(),
                      TextButton(
                        style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4)),
                        onPressed: () => setState(() {
                          for (final c in _filteredCats) {
                            _selUserCats.add(c['cat_id'] as int);
                          }
                        }),
                        child: const Text('সব সিলেক্ট',
                            style: TextStyle(
                                fontSize: 11, color: _blue)),
                      ),
                    ]),

                    // List
                    Expanded(
                      child: _userCats.isEmpty
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: _blue))
                          : _filteredCats.isEmpty
                              ? const Center(
                                  child: Text('কিছু পাওয়া যায়নি',
                                      style: TextStyle(
                                          color: _textL,
                                          fontSize: 12)))
                              : ListView.builder(
                                  itemCount: _filteredCats.length,
                                  itemBuilder: (_, i) {
                                    final c = _filteredCats[i];
                                    final id = c['cat_id'] as int;
                                    final selected =
                                        _selUserCats.contains(id);
                                    return InkWell(
                                      onTap: () => setState(() => selected
                                          ? _selUserCats.remove(id)
                                          : _selUserCats.add(id)),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                            bottom: 2),
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 8),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? _blue.withValues(alpha: 0.08)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: selected
                                              ? Border.all(
                                                  color: _blue
                                                      .withValues(alpha: 0.3))
                                              : null,
                                        ),
                                        child: Row(children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 150),
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? _blue
                                                  : Colors.transparent,
                                              border: Border.all(
                                                  color: selected
                                                      ? _blue
                                                      : _border,
                                                  width: 1.5),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      5),
                                            ),
                                            child: selected
                                                ? const Icon(
                                                    Icons.check_rounded,
                                                    size: 12,
                                                    color: Colors.white)
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              c['cat_name'] as String,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: selected
                                                      ? _blue
                                                      : _textH,
                                                  fontWeight: selected
                                                      ? FontWeight.w600
                                                      : FontWeight.normal),
                                            ),
                                          ),
                                        ]),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Tab 2 — Broadcast
// ═════════════════════════════════════════════════════════════════════════════

class _BroadcastTab extends StatefulWidget {
  const _BroadcastTab();

  @override
  State<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends State<_BroadcastTab> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();

  List<dynamic> _userCats     = [];
  final Set<int> _selCats     = {};
  bool           _allUsers    = true;
  bool           _sending     = false;
  String?        _result;
  bool           _resultOk    = false;
  List<dynamic>  _history     = [];
  bool           _histLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCats();
    _loadHistory();
  }

  Future<void> _loadCats() async {
    final cats = await NotificationAdminService.fetchUserCategories();
    if (mounted) setState(() => _userCats = cats);
  }

  Future<void> _loadHistory() async {
    setState(() => _histLoading = true);
    try {
      final list = await NotificationAdminService.fetchBroadcasts();
      if (mounted) setState(() { _history = list; _histLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _histLoading = false);
    }
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final body  = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      setState(() { _result = 'Title and body are required.'; _resultOk = false; });
      return;
    }
    final confirmed = await _confirm(
        context,
        _allUsers
            ? 'Send to ALL users?'
            : 'Send to ${_selCats.length} selected category(s)?');
    if (!confirmed) return;

    setState(() { _sending = true; _result = null; });
    try {
      final res = await NotificationAdminService.createAndSendBroadcast(
        title:         title,
        body:          body,
        targetCatIds:  _allUsers ? [] : _selCats.toList(),
      );
      final sent   = res['sent_count']   ?? 0;
      final failed = res['failed_count'] ?? 0;
      if (mounted) {
        setState(() {
          _sending   = false;
          _result    = 'Sent: $sent  |  Failed: $failed';
          _resultOk  = true;
        });
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _selCats.clear();
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending  = false;
          _result   = 'Error: $e';
          _resultOk = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Compose panel ──────────────────────────────────────────────────
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Compose Broadcast',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textH)),
                const SizedBox(height: 16),

                // Notification preview card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_blue.withValues(alpha: 0.08), _blue.withValues(alpha: 0.03)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleCtrl.text.isEmpty ? 'Notification Title' : _titleCtrl.text,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _titleCtrl.text.isEmpty ? _textL : _textH),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _bodyCtrl.text.isEmpty ? 'Notification body text...' : _bodyCtrl.text,
                            style: TextStyle(
                                fontSize: 12,
                                color: _bodyCtrl.text.isEmpty ? _textL : _textM),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _FieldLabel('Notification Title'),
                TextField(
                  controller: _titleCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: _inputDeco('e.g. নতুন অফার আসছে!'),
                ),
                const SizedBox(height: 16),
                _FieldLabel('Notification Body'),
                TextField(
                  controller: _bodyCtrl,
                  onChanged: (_) => setState(() {}),
                  maxLines: 4,
                  decoration: _inputDeco('Write your message here...'),
                ),
                const SizedBox(height: 20),

                _FieldLabel('Target Audience'),
                Row(children: [
                  Checkbox(
                    value: _allUsers,
                    onChanged: (v) => setState(() => _allUsers = v!),
                    activeColor: _blue,
                  ),
                  const Text('All registered users',
                      style: TextStyle(fontSize: 13, color: _textH)),
                ]),
                if (!_allUsers) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(8)),
                    child: ListView(
                      shrinkWrap: true,
                      children: _userCats.map((c) {
                        final id = c['cat_id'] as int;
                        return CheckboxListTile(
                          dense: true,
                          value: _selCats.contains(id),
                          title: Text(c['cat_name'] as String,
                              style: const TextStyle(fontSize: 13)),
                          activeColor: _blue,
                          onChanged: (v) {
                            setState(() {
                              v! ? _selCats.add(id) : _selCats.remove(id);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                    label: Text(
                      _sending ? 'Sending...' : 'Send Notification',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                  ),
                ),

                if (_result != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_resultOk ? _green : _red).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: (_resultOk ? _green : _red).withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Icon(_resultOk ? Icons.check_circle_rounded : Icons.error_rounded,
                          size: 16,
                          color: _resultOk ? _green : _red),
                      const SizedBox(width: 8),
                      Text(_result!,
                          style: TextStyle(
                              fontSize: 13,
                              color: _resultOk ? _green : _red,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── History panel ──────────────────────────────────────────────────
        Container(width: 1, color: _border),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    const Text('Broadcast History',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _textH)),
                    const Spacer(),
                    _OutlineButton(
                        label: 'Refresh',
                        icon: Icons.refresh_rounded,
                        onTap: _loadHistory),
                  ],
                ),
              ),
              const Divider(height: 1, color: _border),
              Expanded(
                child: _histLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _blue))
                    : _history.isEmpty
                        ? const Center(
                            child: Text('No broadcasts yet.',
                                style: TextStyle(color: _textM)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _history.length,
                            itemBuilder: (_, i) =>
                                _BroadcastHistoryCard(bc: _history[i]),
                          ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BroadcastHistoryCard extends StatelessWidget {
  final dynamic bc;
  const _BroadcastHistoryCard({required this.bc});

  @override
  Widget build(BuildContext context) {
    final status = bc['status'] as String;
    final Color statusColor;
    switch (status) {
      case 'sent':    statusColor = _green; break;
      case 'sending': statusColor = _amber; break;
      case 'failed':  statusColor = _red;   break;
      default:        statusColor = _textL;
    }
    final catNames = (bc['target_cat_names'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(bc['title'] as String,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textH),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(bc['body'] as String,
              style: const TextStyle(fontSize: 12, color: _textM),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.send_rounded, size: 11, color: _green),
            const SizedBox(width: 4),
            Text('${bc['sent_count']} sent',
                style: const TextStyle(fontSize: 11, color: _green)),
            if ((bc['failed_count'] as int) > 0) ...[
              const SizedBox(width: 10),
              Icon(Icons.error_outline_rounded, size: 11, color: _red),
              const SizedBox(width: 4),
              Text('${bc['failed_count']} failed',
                  style: const TextStyle(fontSize: 11, color: _red)),
            ],
            const Spacer(),
            if (catNames.isEmpty)
              const Text('All users',
                  style: TextStyle(fontSize: 11, color: _textL))
            else
              Text('${catNames.length} cat(s)',
                  style: const TextStyle(fontSize: 11, color: _textL)),
          ]),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Tab 3 — Send Log
// ═════════════════════════════════════════════════════════════════════════════

class _LogTab extends StatefulWidget {
  const _LogTab();

  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  List<dynamic> _logs    = [];
  bool          _loading = true;
  int           _page    = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 1}) async {
    setState(() { _loading = true; });
    try {
      final logs = await NotificationAdminService.fetchLogs(page: page);
      if (mounted) setState(() { _logs = logs; _loading = false; _page = page; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              Text('Page $_page',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: _textM)),
              const Spacer(),
              if (_page > 1)
                _OutlineButton(
                    label: 'Prev',
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _load(page: _page - 1)),
              const SizedBox(width: 8),
              _OutlineButton(
                  label: 'Next',
                  icon: Icons.chevron_right_rounded,
                  onTap: () => _load(page: _page + 1)),
              const SizedBox(width: 8),
              _OutlineButton(
                  label: 'Refresh',
                  icon: Icons.refresh_rounded,
                  onTap: () => _load(page: _page)),
            ],
          ),
        ),
        const Divider(height: 1, color: _border),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _blue))
              : _logs.isEmpty
                  ? const Center(
                      child: Text('No logs yet.',
                          style: TextStyle(color: _textM)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _logs.length,
                      itemBuilder: (_, i) => _LogRow(log: _logs[i]),
                    ),
        ),
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  final dynamic log;
  const _LogRow({required this.log});

  @override
  Widget build(BuildContext context) {
    final type  = log['trigger_type'] as String;
    final sent  = log['sent_count']   as int;
    final failed = log['failed_count'] as int;
    final Color typeColor = type == 'broadcast' ? _blue : _green;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(type.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: typeColor)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(log['title'] as String,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _textH),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(log['body'] as String,
                  style: const TextStyle(fontSize: 11, color: _textM),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(children: [
              Text('$sent', style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _green)),
              const Text(' sent',
                  style: TextStyle(fontSize: 11, color: _textL)),
              if (failed > 0) ...[
                const Text('  '),
                Text('$failed',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: _red)),
                const Text(' failed',
                    style: TextStyle(fontSize: 11, color: _textL)),
              ],
            ]),
            Text(
              _formatDate(log['sent_at'] as String),
              style: const TextStyle(fontSize: 10, color: _textL),
            ),
          ],
        ),
      ]),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Shared small widgets
// ═════════════════════════════════════════════════════════════════════════════

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: _blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: _textM),
      label: Text(label,
          style: const TextStyle(fontSize: 13, color: _textM)),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: _textM)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? _green.withValues(alpha: 0.12)
            : _textL.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(active ? 'Active' : 'Paused',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? _green : _textL)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

InputDecoration _inputDeco(String? hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: _textL),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _border)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _border)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _blue, width: 1.5)),
  );
}

Future<bool> _confirm(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Confirm', style: TextStyle(fontSize: 15)),
      content: Text(message, style: const TextStyle(fontSize: 13)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _blue),
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          child:
              const Text('Confirm', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  return result ?? false;
}
