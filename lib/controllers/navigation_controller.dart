import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class NavigationController extends GetxController {
  static NavigationController get instance => Get.find<NavigationController>();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState!.pushNamed(routeName);
  }

  void replaceTo(String routeName) {
    navigatorKey.currentState!.pushReplacementNamed(routeName);
  }

  void goBack() => navigatorKey.currentState?.pop();
}
