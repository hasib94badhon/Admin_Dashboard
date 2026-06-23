import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/controllers.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/helpers/reponsiveness.dart';
import 'package:flutter_web_dashboard/routing/routes.dart';
import 'package:flutter_web_dashboard/widgets/side_menu_item.dart';
import 'package:get/get.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final isCompact = ResponsiveWidget.isCustomSize(context);

    return Container(
      color: sidebarBg,
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────
          SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/logo.png",
                    width: 30,
                    height: 30,
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 12),
                    const Text(
                      "AaramBD",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Divider
          Container(height: 1, color: sidebarBorderColor),

          // ── Nav items ──────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: sideMenuItemRoutes
                  .map((item) => SideMenuItem(
                        itemName: item.name,
                        onTap: () {
                          if (item.route == authenticationPageRoute) {
                            Get.offAllNamed(authenticationPageRoute);
                            menuController.changeActiveItemTo(
                                overviewPageDisplayName);
                          } else if (!menuController.isActive(item.name)) {
                            menuController.changeActiveItemTo(item.name);
                            if (ResponsiveWidget.isSmallScreen(context)) {
                              Get.back();
                            }
                            navigationController.navigateTo(item.route);
                          }
                        },
                      ))
                  .toList(),
            ),
          ),

          // ── Footer ─────────────────────────────────────────────────────
          Container(height: 1, color: sidebarBorderColor),
          if (!isCompact)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: successColor),
                  const SizedBox(width: 8),
                  const Text(
                    "Admin Panel v1.0",
                    style: TextStyle(
                      color: textOnDarkMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}
