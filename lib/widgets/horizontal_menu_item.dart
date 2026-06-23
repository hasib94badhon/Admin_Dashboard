import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/controllers.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:get/get.dart';

class HorizontalMenuItem extends StatelessWidget {
  final String itemName;
  final Function()? onTap;
  const HorizontalMenuItem({super.key, required this.itemName, this.onTap});

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
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                // Left accent bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive ? accentColor : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Icon
                Icon(
                  menuController.returnIconDataFor(itemName),
                  size: 20,
                  color: isActive
                      ? accentColor
                      : isHover
                          ? textOnDark
                          : textOnDarkMuted,
                ),
                const SizedBox(width: 12),
                // Label
                Flexible(
                  child: Text(
                    itemName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? Colors.white
                          : isHover
                              ? textOnDark
                              : textOnDarkMuted,
                      letterSpacing: 0.1,
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
