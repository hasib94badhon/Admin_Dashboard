import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/pages/clients/clients.dart';
import 'package:flutter_web_dashboard/pages/drivers/drivers.dart';
import 'package:flutter_web_dashboard/pages/overview/overview.dart';
import 'package:flutter_web_dashboard/routing/routes.dart';
import 'package:flutter_web_dashboard/pages/insert/insert_page.dart';
import 'package:flutter_web_dashboard/pages/appstatus/app_status_page.dart';
import 'package:flutter_web_dashboard/pages/staff_admin/staff_admin.dart';
import 'package:flutter_web_dashboard/pages/subscriber/subscriber.dart';
import 'package:flutter_web_dashboard/pages/referral/referral.dart';
import 'package:flutter_web_dashboard/pages/deactivation/deactivation.dart';
import 'package:flutter_web_dashboard/pages/service/service.dart';
import 'package:flutter_web_dashboard/pages/shop/shop.dart';
import 'package:flutter_web_dashboard/pages/location/location.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case overviewPageRoute:
      return _getPageRoute(const OverviewPage());
    case driversPageRoute:
      return _getPageRoute(const DriversPage());
    case clientsPageRoute:
      return _getPageRoute(const ClientsPage());
    case InsertPageRoute:
      return _getPageRoute(const InsertPage());
    case AppstatusPageRoute:
      return _getPageRoute(const AppStatusPage());
    case staffAdminPageRoute:
      return _getPageRoute(const StaffAdminPage());
    case subscriberPageRoute:
      return _getPageRoute(const SubscriberPage());
    case referralPageRoute:
      return _getPageRoute(const ReferralPage());
    case deactivationPageRoute:
      return _getPageRoute(const DeactivationPage());
    case servicePageRoute:
      return _getPageRoute(const ServicePage());
    case shopPageRoute:
      return _getPageRoute(const ShopPage());
    case locationPageRoute:
      return _getPageRoute(const LocationPage());
    default:
      return _getPageRoute(const OverviewPage());
  }
}

PageRoute _getPageRoute(Widget child) {
  return MaterialPageRoute(builder: (context) => child);
}
