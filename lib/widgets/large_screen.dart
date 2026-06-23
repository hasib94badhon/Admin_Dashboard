import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/helpers/local_navigator.dart';
import 'package:flutter_web_dashboard/helpers/reponsiveness.dart';
import 'package:flutter_web_dashboard/widgets/side_menu.dart';

class LargeScreen extends StatelessWidget {
  const LargeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Compact mode (768–1100 px): icon-only sidebar at 72 px
    // Full mode (>1100 px): sidebar with icon + label at 240 px
    final sidebarWidth = ResponsiveWidget.isCustomSize(context) ? 72.0 : 240.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: sidebarWidth, child: const SideMenu()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: localNavigator(),
          ),
        ),
      ],
    );
  }
}
