import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/controllers.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/helpers/reponsiveness.dart';
import 'package:flutter_web_dashboard/routing/routes.dart';
import 'package:flutter_web_dashboard/service_api/auth_state.dart';
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
              children: [
                for (final item in sideMenuItemRoutes)
                  if (AuthState.canAccessPageKey(pageKeyForRoute[item.route]!))
                    _menuTile(context, item.name, item.route),
                // Managing other admins is superadmin-only, always -- never
                // toggle-able like the pages above.
                if (AuthState.isSuperAdmin)
                  _menuTile(context, staffAdminPageDisplayName,
                      staffAdminPageRoute),
              ],
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

  Widget _menuTile(BuildContext context, String itemName, String route) {
    return SideMenuItem(
      itemName: itemName,
      onTap: () {
        if (route == authenticationPageRoute) {
          Get.offAllNamed(authenticationPageRoute);
          menuController.changeActiveItemTo(overviewPageDisplayName);
        } else if (!menuController.isActive(itemName)) {
          menuController.changeActiveItemTo(itemName);
          if (ResponsiveWidget.isSmallScreen(context)) {
            Get.back();
          }
          navigationController.navigateTo(route);
        }
      },
    );
  }
}
