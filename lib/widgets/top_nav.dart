import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/helpers/reponsiveness.dart';
import 'package:flutter_web_dashboard/routing/routes.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'custom_text.dart';
import 'package:get_storage/get_storage.dart';

AppBar topNavigationBar(BuildContext context, GlobalKey<ScaffoldState> key) {
  final storage = GetStorage();
  final adminName = storage.read('admin_username') ?? 'Admin';

  return AppBar(
    leading: !ResponsiveWidget.isSmallScreen(context)
        ? Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Image.asset(
                  "assets/icons/logo.png",
                  width: 28,
                ),
              ),
            ],
          )
        : IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              key.currentState?.openDrawer();
            }),
    title: Container(
      color: Colors.black26,
      child: Row(
        children: [
          Visibility(
              visible: !ResponsiveWidget.isSmallScreen(context),
              child: const CustomText(
                text: "Dashboard",
                color: lightGrey,
                size: 25,
                weight: FontWeight.bold,
              )),
          Expanded(
              child: Container(
            color: Colors.red,
            width: 20,
          )),
          IconButton(
              icon: const Icon(
                Icons.settings,
                color: dark,
              ),
              onPressed: () {}),
          Stack(
            children: [
              IconButton(
                  icon: Icon(
                    Icons.notifications,
                    color: dark.withOpacity(.7),
                  ),
                  onPressed: () {}),
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 12,
                  height: 12,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: active,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: light, width: 2)),
                ),
              )
            ],
          ),
          Container(
            width: 1,
            height: 22,
            color: lightGrey,
          ),
          const SizedBox(width: 24),
          CustomText(
            text: "Welcome, $adminName",
            color: Colors.black,
          ),
          const SizedBox(width: 16),
          Container(
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
                color: active.withOpacity(.5),
                borderRadius: BorderRadius.circular(30)),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.all(2),
              margin: const EdgeInsets.all(2),
              child: PopupMenuButton<String>(
                icon: const CircleAvatar(
                  backgroundColor: light,
                  radius: 15,
                  child: Icon(Icons.person_outline, color: dark),
                ),
                onSelected: (value) {
                  if (value == 'logout') {
                    final storage = GetStorage();
                    storage.write('isLoggedIn', false);
                    storage.remove('admin_username');
                    Get.offAllNamed(authenticationPageRoute); // ✅ Go to login
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    ),
    iconTheme: const IconThemeData(color: dark),
    elevation: 0,
    backgroundColor: Colors.transparent,
  );
}
