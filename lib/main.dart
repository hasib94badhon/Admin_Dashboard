import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/controllers/menu_controller.dart'
    as menu_controller;
import 'package:flutter_web_dashboard/controllers/navigation_controller.dart';
import 'package:flutter_web_dashboard/layout.dart';
import 'package:flutter_web_dashboard/pages/404/error.dart';
import 'package:flutter_web_dashboard/pages/authentication/authentication.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routing/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  Get.put(menu_controller.MenuController());
  Get.put(NavigationController()); // ✅ register here

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = GetStorage();
    final isLoggedIn = storage.read('isLoggedIn') ?? false;
    return GetMaterialApp(
      // 1) Start on authentication
      initialRoute: isLoggedIn ? rootRoute : authenticationPageRoute,

      // 2) Define all pages
      getPages: [
        GetPage(
          name: authenticationPageRoute,
          page: () => const AuthenticationPage(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: rootRoute, // "/" → SiteLayout (dashboard shell)
          page: () => SiteLayout(),
          transition: Transition.fadeIn,
        ),
        // Optional: map overview route if you also navigate by name directly
        // GetPage(
        //   name: overviewPageRoute,
        //   page: () => const OverviewPage(),
        // ),
      ],

      // 3) Fallback for unknown routes
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const PageNotFound(),
        transition: Transition.fadeIn,
      ),

      // 4) Theme
      debugShowCheckedModeBanner: false,
      title: 'Dashboard',
      theme: ThemeData(
        scaffoldBackgroundColor: light,
        textTheme: GoogleFonts.mulishTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: Colors.black),
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        }),
        primarySwatch: Colors.blue,
      ),

      // 5) Do NOT provide a navigatorKey here.
      //    Your local content Navigator inside SiteLayout should own its own key.
      // navigatorKey: NavigationController.instance.navigatorKey, // ❌ remove
    );
  }
}
