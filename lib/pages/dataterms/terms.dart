import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_dashboard/config.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  String englishText = "";
  String banglaText = "";
  bool isLoading = true;

  final TextEditingController englishController = TextEditingController();
  final TextEditingController banglaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTerms();
  }

  /// GET request → fetch existing terms
  Future<void> fetchTerms() async {
    try {
      final response = await http.get(Uri.parse('$host/api/term-policy/'));
      if (response.statusCode == 200) {
        // ✅ UTF-8 decode
        final decoded = utf8.decode(response.bodyBytes);
        final data = json.decode(decoded);

        final description = data['description'] ?? "";

        // Split English & Bangla অংশ
        final parts = description.split("Bangla:");
        englishText = parts[0].replaceFirst("English:", "").trim();
        banglaText = parts.length > 1 ? parts[1].trim() : "";

        englishController.text = englishText;
        banglaController.text = banglaText;
      }
    } catch (e) {
      print("Error fetching terms: $e");
    }
    setState(() {
      isLoading = false;
    });
  }

  /// POST request → update terms
  Future<void> updateTerms() async {
    final newDescription =
        "English: ${englishController.text}\r\nBangla: ${banglaController.text}";

    try {
      final response = await http.post(
        Uri.parse('$host/api/term-policy/'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"description": newDescription}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terms updated successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: ${response.body}")),
        );
      }
    } catch (e) {
      print("Error updating terms: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Data Collector Instructions")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // English terms
            TextField(
              controller: englishController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: "English Terms",
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 16), // Default font
            ),
            const SizedBox(height: 20),

            // Bangla terms
            TextField(
              controller: banglaController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: "Bangla Terms",
                border: OutlineInputBorder(),
              ),
              style: GoogleFonts.notoSansBengali(fontSize: 16), // ✅ Bangla font
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: updateTerms,
              child: const Text("Update Terms"),
            ),
          ],
        ),
      ),
    );
  }
}
