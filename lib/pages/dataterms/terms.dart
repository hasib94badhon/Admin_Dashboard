import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/service_api/auth_headers.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  String englishText = "";
  String banglaText = "";
  bool isLoading = true;
  bool isSaving = false;

  final TextEditingController englishController = TextEditingController();
  final TextEditingController banglaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTerms();
  }

  Future<void> fetchTerms() async {
    try {
      final response = await http.get(Uri.parse('$host/api/term-policy/'),
          headers: authHeaders());
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = json.decode(decoded);
        final description = data['description'] ?? "";
        final parts = description.split("Bangla:");
        englishText = parts[0].replaceFirst("English:", "").trim();
        banglaText = parts.length > 1 ? parts[1].trim() : "";
        englishController.text = englishText;
        banglaController.text = banglaText;
      }
    } catch (_) {}
    setState(() => isLoading = false);
  }

  Future<void> updateTerms() async {
    setState(() => isSaving = true);
    final newDescription =
        "English: ${englishController.text}\r\nBangla: ${banglaController.text}";
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.post(
        Uri.parse('$host/api/term-policy/'),
        headers: authHeaders(),
        body: json.encode({"description": newDescription}),
      );
      if (response.statusCode == 200) {
        messenger.showSnackBar(const SnackBar(
          content: Text("Terms updated successfully"),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text("Failed to update: ${response.body}"),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text("Error: $e"),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
    setState(() => isSaving = false);
  }

  @override
  void dispose() {
    englishController.dispose();
    banglaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
          child: Row(
            children: [
              const Icon(Icons.description_rounded,
                  size: 22, color: accentColor),
              const SizedBox(width: 10),
              const Text('Data Collector Instructions',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
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
                child: const Text('Terms & Policy',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor)),
              ),
            ],
          ),
        ),

        isLoading
            ? const Expanded(
                child: Center(
                    child: CircularProgressIndicator(color: accentColor)))
            : Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // English card
                    Expanded(
                      child: _TermCard(
                        title: 'English Terms',
                        subtitle: 'Instructions in English',
                        icon: Icons.language_rounded,
                        iconColor: accentColor,
                        controller: englishController,
                        textStyle: const TextStyle(
                            fontSize: 14,
                            color: textPrimary,
                            height: 1.6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Bangla card
                    Expanded(
                      child: _TermCard(
                        title: 'বাংলা নির্দেশনা',
                        subtitle: 'Instructions in Bangla',
                        icon: Icons.translate_rounded,
                        iconColor: warningColor,
                        controller: banglaController,
                        textStyle: GoogleFonts.notoSansBengali(
                            fontSize: 14,
                            color: textPrimary,
                            height: 1.8),
                      ),
                    ),
                  ],
                ),
              ),

        // Save button
        if (!isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: isSaving ? null : updateTerms,
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded,
                          size: 16, color: Colors.white),
                  label: Text(isSaving ? 'Saving...' : 'Update Terms',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white)),
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
          ),
      ],
    );
  }
}

class _TermCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final TextEditingController controller;
  final TextStyle textStyle;

  const _TermCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.controller,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Card header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: background,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: textMuted)),
                  ],
                ),
              ],
            ),
          ),
          // Text area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                style: textStyle,
                decoration: InputDecoration(
                  hintText: 'Enter content here...',
                  hintStyle:
                      const TextStyle(color: textMuted, fontSize: 13),
                  filled: true,
                  fillColor: surface,
                  contentPadding: const EdgeInsets.all(16),
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
          ),
        ],
      ),
    );
  }
}
