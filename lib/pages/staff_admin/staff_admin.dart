import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/style.dart';

class StaffAdminPage extends StatelessWidget {
  const StaffAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, size: 22, color: accentColor),
              SizedBox(width: 10),
              Text('Staff & Admin',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 24),

          // Coming soon card
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: accentLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          size: 36, color: accentColor),
                    ),
                    const SizedBox(height: 20),
                    const Text('Staff Management',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
                    const SizedBox(height: 8),
                    const Text(
                      'Staff and admin account management will be available here. Coming soon.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: const Text('Coming Soon',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
