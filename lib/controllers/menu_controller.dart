import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/routing/routes.dart';
import 'package:get/get.dart';

class MenuController extends GetxController {
  static MenuController instance = Get.find();
  var activeItem = overviewPageDisplayName.obs;
  var hoverItem = "".obs;

  changeActiveItemTo(String itemName) {
    activeItem.value = itemName;
  }

  onHover(String itemName) {
    if (!isActive(itemName)) hoverItem.value = itemName;
  }

  isHovering(String itemName) => hoverItem.value == itemName;
  isActive(String itemName) => activeItem.value == itemName;

  IconData returnIconDataFor(String itemName) {
    switch (itemName) {
      case overviewPageDisplayName:       return Icons.dashboard_rounded;
      case driversPageDisplayName:        return Icons.category_rounded;
      case clientsPageDisplayName:        return Icons.people_rounded;
      case InsertPageDisplayName:         return Icons.upload_file_rounded;
      case AppstatusPageDisplayName:      return Icons.bar_chart_rounded;
      case staffAdminPageDisplayName:     return Icons.admin_panel_settings_rounded;
      case referralPageDisplayName:       return Icons.group_add_rounded;
      case deactivationPageDisplayName:   return Icons.person_off_rounded;
      case servicePageDisplayName:        return Icons.miscellaneous_services_rounded;
      case shopPageDisplayName:           return Icons.storefront_rounded;
      case subscriberPageDisplayName:     return Icons.subscriptions_rounded;
      case authenticationPageDisplayName: return Icons.logout_rounded;
      case termsPageDisplayName:          return Icons.description_rounded;
      default:                            return Icons.circle_outlined;
    }
  }

  // Kept for backward compatibility with existing pages
  Widget returnIconFor(String itemName) {
    return Icon(
      returnIconDataFor(itemName),
      size: 20,
      color: isActive(itemName) ? accentColor : isHovering(itemName) ? textOnDark : textOnDarkMuted,
    );
  }
}
