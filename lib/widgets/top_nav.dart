import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/controllers.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/helpers/reponsiveness.dart';
import 'package:flutter_web_dashboard/routing/routes.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

AppBar topNavigationBar(BuildContext context, GlobalKey<ScaffoldState> key) {
  final storage = GetStorage();
  final adminName = storage.read<String>('admin_username') ?? 'Admin';
  final initial = adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A';
  final isSmall = ResponsiveWidget.isSmallScreen(context);

  return AppBar(
    backgroundColor: surface,
    elevation: 0,
    titleSpacing: 0,
    leading: isSmall
        ? IconButton(
            icon: const Icon(Icons.menu_rounded, color: textPrimary),
            onPressed: () => key.currentState?.openDrawer(),
          )
        : const SizedBox.shrink(),
    leadingWidth: isSmall ? 56 : 0,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(color: borderColor, height: 1),
    ),
    title: Padding(
      padding: EdgeInsets.only(left: isSmall ? 0 : 24),
      child: isSmall
          ? Obx(() => Text(
                menuController.activeItem.value,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ))
          : Obx(() => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home_rounded,
                      size: 14, color: textMuted),
                  const SizedBox(width: 6),
                  const Text("/",
                      style: TextStyle(color: textMuted, fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    menuController.activeItem.value,
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              )),
    ),
    actions: [
      // Notification bell
      IconButton(
        icon: const Icon(Icons.notifications_outlined, color: textSecondary),
        tooltip: 'Notifications',
        onPressed: () {},
      ),
      // Vertical divider
      Container(
        width: 1,
        height: 24,
        color: borderColor,
        margin: const EdgeInsets.symmetric(vertical: 16),
      ),
      const SizedBox(width: 4),
      // User avatar + name + logout dropdown
      PopupMenuButton<String>(
        offset: const Offset(0, 52),
        tooltip: '',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: accentLight,
                radius: 16,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!isSmall) ...[
                const SizedBox(width: 10),
                Text(
                  adminName,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: textSecondary),
              ],
            ],
          ),
        ),
        onSelected: (value) {
          if (value == 'logout') {
            storage.write('isLoggedIn', false);
            storage.remove('admin_username');
            storage.remove('auth_token');
            storage.remove('is_superadmin');
            storage.remove('allowed_pages');
            Get.offAllNamed(authenticationPageRoute);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: const [
                Icon(Icons.logout_rounded, size: 16, color: errorColor),
                SizedBox(width: 10),
                Text('Logout',
                    style: TextStyle(
                        color: errorColor, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(width: 8),
    ],
    iconTheme: const IconThemeData(color: textPrimary),
  );
}
