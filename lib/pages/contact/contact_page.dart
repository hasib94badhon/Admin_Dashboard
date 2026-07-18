import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/service_api/auth_headers.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  bool isLoading = true;
  bool isSaving  = false;

  final _phoneCtrl    = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _websiteCtrl  = TextEditingController();
  final _facebookCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    _facebookCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('$host/api/contact-info/'),
          headers: authHeaders());
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        _phoneCtrl.text    = data['phone']    ?? '';
        _emailCtrl.text    = data['email']    ?? '';
        _addressCtrl.text  = data['address']  ?? '';
        _websiteCtrl.text  = data['website']  ?? '';
        _facebookCtrl.text = data['facebook'] ?? '';
      }
    } catch (_) {}
    setState(() => isLoading = false);
  }

  Future<void> _save() async {
    setState(() => isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await http.post(
        Uri.parse('$host/api/contact-info/'),
        headers: authHeaders(),
        body: json.encode({
          'phone':    _phoneCtrl.text.trim(),
          'email':    _emailCtrl.text.trim(),
          'address':  _addressCtrl.text.trim(),
          'website':  _websiteCtrl.text.trim(),
          'facebook': _facebookCtrl.text.trim(),
        }),
      );
      if (res.statusCode == 200) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Contact info updated successfully'),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text('Failed: ${res.body}'),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
          child: Row(
            children: [
              const Icon(Icons.contact_phone_rounded,
                  size: 22, color: accentColor),
              const SizedBox(width: 10),
              const Text(
                'Contact Information',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: accentLight,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'App-wide settings',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentColor),
                ),
              ),
            ],
          ),
        ),

        if (isLoading)
          const Expanded(
            child: Center(
                child: CircularProgressIndicator(color: accentColor)),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info banner ──────────────────────────────────────────
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accentLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 18,
                            color: accentColor.withValues(alpha: 0.8)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'This information is shown in the AaramBD app '
                            'on the Data Collector page and other contact sections. '
                            'Update any field and press Save.',
                            style: TextStyle(
                                fontSize: 13, color: textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Form grid ────────────────────────────────────────────
                  LayoutBuilder(builder: (context, constraints) {
                    final wide = constraints.maxWidth > 700;
                    final fields = [
                      _FieldDef(
                        controller: _phoneCtrl,
                        label: 'Phone Number',
                        hint: 'e.g. 01679-374433',
                        icon: Icons.phone_rounded,
                      ),
                      _FieldDef(
                        controller: _emailCtrl,
                        label: 'Email Address',
                        hint: 'e.g. support@aarambd.com',
                        icon: Icons.email_rounded,
                      ),
                      _FieldDef(
                        controller: _addressCtrl,
                        label: 'Office Address',
                        hint: 'e.g. Uttara, Dhaka',
                        icon: Icons.location_on_rounded,
                        maxLines: 2,
                      ),
                      _FieldDef(
                        controller: _websiteCtrl,
                        label: 'Website',
                        hint: 'e.g. https://aarambd.com',
                        icon: Icons.language_rounded,
                      ),
                      _FieldDef(
                        controller: _facebookCtrl,
                        label: 'Facebook Page',
                        hint: 'e.g. https://facebook.com/aarambd',
                        icon: Icons.facebook_rounded,
                      ),
                    ];

                    if (wide) {
                      // Two-column layout on wide screens
                      final rows = <Widget>[];
                      for (int i = 0; i < fields.length; i += 2) {
                        rows.add(
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildField(fields[i])),
                              const SizedBox(width: 16),
                              if (i + 1 < fields.length)
                                Expanded(
                                    child: _buildField(fields[i + 1]))
                              else
                                const Expanded(child: SizedBox()),
                            ],
                          ),
                        );
                        if (i + 2 < fields.length) {
                          rows.add(const SizedBox(height: 16));
                        }
                      }
                      return Column(children: rows);
                    } else {
                      return Column(
                        children: fields
                            .expand((f) =>
                                [_buildField(f), const SizedBox(height: 16)])
                            .toList(),
                      );
                    }
                  }),

                  const SizedBox(height: 28),

                  // ── Preview card ─────────────────────────────────────────
                  _PreviewCard(
                    phone:    _phoneCtrl.text,
                    email:    _emailCtrl.text,
                    address:  _addressCtrl.text,
                    website:  _websiteCtrl.text,
                    facebook: _facebookCtrl.text,
                  ),

                  const SizedBox(height: 24),

                  // ── Save button ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: isSaving ? null : _fetch,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Reset',
                            style: TextStyle(fontSize: 14)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: isSaving ? null : _save,
                        icon: isSaving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Icon(Icons.save_rounded,
                                size: 16, color: Colors.white),
                        label: Text(
                          isSaving ? 'Saving...' : 'Save Changes',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          disabledBackgroundColor:
                              accentColor.withValues(alpha: 0.6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildField(_FieldDef f) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Icon(f.icon, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  f.label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: TextField(
              controller: f.controller,
              maxLines: f.maxLines,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, color: textPrimary),
              decoration: InputDecoration(
                hintText: f.hint,
                hintStyle:
                    const TextStyle(color: textMuted, fontSize: 13),
                filled: true,
                fillColor: surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: accentColor, width: 1.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field definition helper ──────────────────────────────────────────────────

class _FieldDef {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _FieldDef({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });
}

// ── Live preview card ────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final String phone;
  final String email;
  final String address;
  final String website;
  final String facebook;

  const _PreviewCard({
    required this.phone,
    required this.email,
    required this.address,
    required this.website,
    required this.facebook,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_Row>[];
    if (phone.isNotEmpty)
      rows.add(_Row(Icons.phone_rounded, phone));
    if (email.isNotEmpty)
      rows.add(_Row(Icons.email_rounded, email));
    if (address.isNotEmpty)
      rows.add(_Row(Icons.location_on_rounded, address));
    if (website.isNotEmpty)
      rows.add(_Row(Icons.language_rounded, website));
    if (facebook.isNotEmpty)
      rows.add(_Row(Icons.facebook_rounded, facebook));

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                const Icon(Icons.preview_rounded,
                    size: 16, color: accentColor),
                const SizedBox(width: 8),
                const Text(
                  'App Preview',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary),
                ),
                const Spacer(),
                const Text(
                  'Live — updates as you type',
                  style:
                      TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: rows.isEmpty
                ? const Text('Fill in the fields above to see a preview.',
                    style: TextStyle(color: textMuted, fontSize: 13))
                : Column(
                    children: rows
                        .map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: accentLight,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Icon(r.icon,
                                        size: 16, color: accentColor),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(r.text,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: textPrimary)),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Row {
  final IconData icon;
  final String   text;
  const _Row(this.icon, this.text);
}
