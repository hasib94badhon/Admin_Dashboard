import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/routing/routes.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_dashboard/config.dart';
import 'package:get_storage/get_storage.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final storage = GetStorage();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool rememberMe = true;
  bool isLoading = false;
  bool _obscurePassword = true;

  // ── Backend logic — unchanged ─────────────────────────────────────────────

  Future<void> loginAdmin() async {
    setState(() => isLoading = true);
    final url = Uri.parse('$host/api/login-superuser/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': usernameController.text.trim(),
        'password': passwordController.text.trim(),
      }),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final user = data['user'];
        storage.write('isLoggedIn', true);
        storage.write('admin_username', user['username']);
        storage.write('auth_token', data['token']);
        storage.write('is_superadmin', user['is_superuser'] == true);
        storage.write('allowed_pages', jsonEncode(user['allowed_pages'] ?? []));
        Get.snackbar("Success", "Login successful",
            snackPosition: SnackPosition.TOP,
            backgroundColor: successColor,
            colorText: Colors.white);
        Get.offAllNamed(rootRoute);
      } else {
        _showError(data['message'] ?? 'Login failed');
      }
    } else {
      _showError('Server error: ${response.statusCode}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: errorColor),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Row(
              children: [
                // Left branding panel
                Expanded(flex: 2, child: _buildBrandPanel()),
                // Right form panel
                Expanded(flex: 3, child: _buildFormPanel()),
              ],
            );
          }
          // Small screen: form only
          return _buildFormPanel();
        },
      ),
    );
  }

  // ── Left panel ────────────────────────────────────────────────────────────

  Widget _buildBrandPanel() {
    return Container(
      color: sidebarBg,
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset("assets/icons/logo.png", width: 64, height: 64),
          const SizedBox(height: 32),
          Text(
            "AaramBD\nAdmin Panel",
            style: GoogleFonts.mulish(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Manage your service directory,\nusers, categories and more —\nall from one place.",
            style: GoogleFonts.mulish(
              color: textOnDarkMuted,
              fontSize: 15,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 48),
          const _BrandDivider(),
          const SizedBox(height: 32),
          Row(
            children: const [
              _StatChip(label: "Users", value: "1K+"),
              SizedBox(width: 24),
              _StatChip(label: "Services", value: "100+"),
              SizedBox(width: 24),
              _StatChip(label: "Categories", value: "20+"),
            ],
          ),
        ],
      ),
    );
  }

  // ── Right form panel ──────────────────────────────────────────────────────

  Widget _buildFormPanel() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Builder(builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo — only on small screens; large screens show it on the brand panel
              if (screenWidth < 900)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Image.asset("assets/icons/logo.png",
                      width: 48, height: 48),
                ),
              Text(
                "Welcome back",
                style: GoogleFonts.mulish(
                  color: textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to your admin account",
                style: GoogleFonts.mulish(
                  color: textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 36),

              // Username
              _buildTextField(
                controller: usernameController,
                label: "Username",
                hint: "Enter your username",
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: textPrimary, fontSize: 14),
                decoration: _inputDecoration(
                  label: "Password",
                  hint: "Enter your password",
                  prefixIcon: Icons.lock_outline_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: textMuted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Remember me
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: rememberMe,
                      onChanged: (v) =>
                          setState(() => rememberMe = v ?? true),
                      activeColor: accentColor,
                      side: const BorderSide(color: borderColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Remember me",
                    style: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginAdmin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        accentColor.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Sign in",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),

              // Footer
              Center(
                child: Text(
                  "© 2025 AaramBD. All rights reserved.",
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
              ),
            ],
          );
          }),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: textPrimary, fontSize: 14),
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        prefixIcon: prefixIcon,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
      hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: textMuted, size: 20),
      filled: true,
      fillColor: surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: accentColor, width: 1.5),
      ),
    );
  }
}

// ── Small stateless helpers ───────────────────────────────────────────────────

class _BrandDivider extends StatelessWidget {
  const _BrandDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: sidebarBorderColor);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: textOnDarkMuted, fontSize: 12),
        ),
      ],
    );
  }
}
