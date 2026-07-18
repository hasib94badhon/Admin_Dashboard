import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/routing/routes.dart';
import 'package:flutter_web_dashboard/service_api/admin_management_service.dart';

class StaffAdminPage extends StatefulWidget {
  const StaffAdminPage({super.key});

  @override
  State<StaffAdminPage> createState() => _StaffAdminPageState();
}

class _StaffAdminPageState extends State<StaffAdminPage> {
  List<dynamic> _admins = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final admins = await AdminManagementService.fetchAdmins();
      if (!mounted) return;
      setState(() {
        _admins = admins;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _snack(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: success ? successColor : errorColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _openCreateDialog() async {
    await showDialog(
      context: context,
      builder: (_) => _AdminFormDialog(
        onSubmit: (username, password, allowedPages) async {
          await AdminManagementService.createAdmin(
            username: username,
            password: password,
            allowedPages: allowedPages,
          );
        },
      ),
    );
    _load();
  }

  Future<void> _openPermissionsDialog(Map<String, dynamic> admin) async {
    final current = List<String>.from(admin['allowed_pages'] ?? []);
    await showDialog(
      context: context,
      builder: (_) => _PermissionsDialog(
        username: admin['username'],
        initialAllowedPages: current,
        onSubmit: (allowedPages) async {
          await AdminManagementService.updatePermissions(admin['id'], allowedPages);
        },
      ),
    );
    _load();
  }

  Future<void> _openResetPasswordDialog(Map<String, dynamic> admin) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Reset password — ${admin['username']}'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(
              labelText: 'New password', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      await AdminManagementService.resetPassword(admin['id'], result);
      _snack('Password reset for ${admin['username']}', success: true);
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> admin) async {
    try {
      final isActive = await AdminManagementService.toggleActive(admin['id']);
      _snack(
          isActive
              ? '${admin['username']} can log in again'
              : '${admin['username']} is restricted from logging in',
          success: true);
      _load();
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _deleteAdmin(Map<String, dynamic> admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete admin account'),
        content: Text(
            "Permanently delete '${admin['username']}'? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorColor),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AdminManagementService.deleteAdmin(admin['id']);
      _snack('${admin['username']} deleted', success: true);
      _load();
    } catch (e) {
      _snack(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, size: 22, color: accentColor),
              const SizedBox(width: 10),
              const Text('Staff & Admin',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: Colors.white),
                label: const Text('Add Admin', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: accentColor));
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error', style: const TextStyle(color: errorColor)));
    }
    if (_admins.isEmpty) {
      return const Center(
        child: Text('No admin accounts yet. Add one to get started.',
            style: TextStyle(color: textMuted)),
      );
    }
    return ListView.separated(
      itemCount: _admins.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _AdminCard(
        admin: _admins[i],
        onEditPermissions: () => _openPermissionsDialog(_admins[i]),
        onToggleActive: () => _toggleActive(_admins[i]),
        onResetPassword: () => _openResetPasswordDialog(_admins[i]),
        onDelete: () => _deleteAdmin(_admins[i]),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final Map<String, dynamic> admin;
  final VoidCallback onEditPermissions;
  final VoidCallback onToggleActive;
  final VoidCallback onResetPassword;
  final VoidCallback onDelete;

  const _AdminCard({
    required this.admin,
    required this.onEditPermissions,
    required this.onToggleActive,
    required this.onResetPassword,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = admin['is_active'] == true;
    final allowedPages = List<String>.from(admin['allowed_pages'] ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: accentLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_rounded, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(admin['username'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
                    if ((admin['email'] ?? '').toString().isNotEmpty)
                      Text(admin['email'], style: const TextStyle(fontSize: 12, color: textMuted)),
                  ],
                ),
              ),
              _StatusPill(isActive: isActive),
              const SizedBox(width: 8),
              Switch(
                value: isActive,
                activeThumbColor: successColor,
                onChanged: (_) => onToggleActive(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: allowedPages.isEmpty
                ? [const Text('No pages granted yet', style: TextStyle(fontSize: 12, color: textMuted))]
                : allowedPages
                    .map((k) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(pageKeyLabels[k] ?? k,
                              style: const TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEditPermissions,
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Permissions'),
              ),
              TextButton.icon(
                onPressed: onResetPassword,
                icon: const Icon(Icons.lock_reset_rounded, size: 16),
                label: const Text('Reset password'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: errorColor),
                label: const Text('Delete', style: TextStyle(color: errorColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? successColor : errorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(isActive ? 'Active' : 'Restricted',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Add Admin dialog ─────────────────────────────────────────────────────────

class _AdminFormDialog extends StatefulWidget {
  final Future<void> Function(String username, String password, List<String> allowedPages) onSubmit;
  const _AdminFormDialog({required this.onSubmit});

  @override
  State<_AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends State<_AdminFormDialog> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final Set<String> _selected = {};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Username and password are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
          _usernameCtrl.text.trim(), _passwordCtrl.text, _selected.toList());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Add Admin'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Page access', style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(height: 4),
              _PageChecklist(selected: _selected),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: errorColor, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: accentColor),
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Create', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ── Edit permissions dialog ──────────────────────────────────────────────────

class _PermissionsDialog extends StatefulWidget {
  final String username;
  final List<String> initialAllowedPages;
  final Future<void> Function(List<String> allowedPages) onSubmit;

  const _PermissionsDialog({
    required this.username,
    required this.initialAllowedPages,
    required this.onSubmit,
  });

  @override
  State<_PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<_PermissionsDialog> {
  late final Set<String> _selected = Set.from(widget.initialAllowedPages);
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_selected.toList());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('Page access — ${widget.username}'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageChecklist(selected: _selected),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: errorColor, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: accentColor),
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ── Shared checkbox list ─────────────────────────────────────────────────────

class _PageChecklist extends StatefulWidget {
  final Set<String> selected;
  const _PageChecklist({required this.selected});

  @override
  State<_PageChecklist> createState() => _PageChecklistState();
}

class _PageChecklistState extends State<_PageChecklist> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: allPageKeys.map((key) {
        final checked = widget.selected.contains(key);
        return CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(pageKeyLabels[key] ?? key, style: const TextStyle(fontSize: 14)),
          value: checked,
          activeColor: accentColor,
          onChanged: (v) {
            setState(() {
              if (v == true) {
                widget.selected.add(key);
              } else {
                widget.selected.remove(key);
              }
            });
          },
        );
      }).toList(),
    );
  }
}
