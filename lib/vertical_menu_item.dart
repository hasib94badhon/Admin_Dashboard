import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/controllers.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:get/get.dart';

class VertticalMenuItem extends StatelessWidget {
  final String itemName;
  final Function()? onTap;
  const VertticalMenuItem({super.key, required this.itemName, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => menuController.onHover(itemName),
      onExit: (_) => menuController.onHover("not hovering"),
      child: InkWell(
        onTap: onTap,
        child: Obx(() {
          final isActive = menuController.isActive(itemName);
          final isHover = menuController.isHovering(itemName);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: (isActive || isHover) ? sidebarHoverBg : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top accent bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 3,
                  width: double.infinity,
                  color: isActive ? accentColor : Colors.transparent,
                ),
                const SizedBox(height: 10),
                Icon(
                  menuController.returnIconDataFor(itemName),
                  size: 22,
                  color: isActive
                      ? accentColor
                      : isHover
                          ? textOnDark
                          : textOnDarkMuted,
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    itemName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? Colors.white
                          : isHover
                              ? textOnDark
                              : textOnDarkMuted,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
