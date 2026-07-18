import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/style.dart';

class NotAuthorizedPage extends StatelessWidget {
  const NotAuthorizedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.lock_outline_rounded,
                size: 40, color: errorColor),
          ),
          const SizedBox(height: 20),
          const Text('403',
              style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -1)),
          const SizedBox(height: 8),
          const Text('Not authorized',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: textSecondary)),
          const SizedBox(height: 6),
          const Text("Your account doesn't have access to this page.",
              style: TextStyle(fontSize: 14, color: textMuted)),
        ],
      ),
    );
  }
}
