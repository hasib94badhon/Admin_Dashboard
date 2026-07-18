import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/pages/403/not_authorized.dart';
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
import 'package:flutter_web_dashboard/pages/deleted_accounts/deleted_accounts.dart';
import 'package:flutter_web_dashboard/pages/service/service.dart';
import 'package:flutter_web_dashboard/pages/shop/shop.dart';
import 'package:flutter_web_dashboard/pages/dataterms/terms.dart';
import 'package:flutter_web_dashboard/pages/reactions/reactions_page.dart';
import 'package:flutter_web_dashboard/pages/contact/contact_page.dart';
import 'package:flutter_web_dashboard/pages/notifications/notifications.dart';
import 'package:flutter_web_dashboard/service_api/auth_state.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case overviewPageRoute:
      return _guarded(overviewPageRoute, const OverviewPage());
    case driversPageRoute:
      return _guarded(driversPageRoute, const DriversPage());
    case clientsPageRoute:
      return _guarded(clientsPageRoute, const ClientsPage());
    case InsertPageRoute:
      return _guarded(InsertPageRoute, const InsertPage());
    case AppstatusPageRoute:
      return _guarded(AppstatusPageRoute, const AppStatusPage());
    case staffAdminPageRoute:
      // Managing other admins is superuser-only, always -- not a togglable
      // page like the rest, so it isn't in pageKeyForRoute.
      return _getPageRoute(
          AuthState.isSuperAdmin ? const StaffAdminPage() : const NotAuthorizedPage());
    case referralPageRoute:
      return _guarded(referralPageRoute, const ReferralPage());
    case deactivationPageRoute:
      return _guarded(deactivationPageRoute, const DeactivationPage());
    case deletedAccountsPageRoute:
      return _guarded(deletedAccountsPageRoute, const DeletedAccountsPage());
    case servicePageRoute:
      return _guarded(servicePageRoute, const ServicePage());
    case shopPageRoute:
      return _guarded(shopPageRoute, const ShopPage());
    case subscriberPageRoute:
      return _guarded(subscriberPageRoute, const SubscriberPage());
    case termsPageRoute:
      return _guarded(termsPageRoute, const TermsPage());
    case reactionsPageRoute:
      return _guarded(reactionsPageRoute, const ReactionsPage());
    case contactPageRoute:
      return _guarded(contactPageRoute, const ContactPage());
    case notificationsPageRoute:
      return _guarded(notificationsPageRoute, const NotificationsPage());
    default:
      return _guarded(overviewPageRoute, const OverviewPage());
  }
}

/// Blocks direct navigation to a route the current admin hasn't been
/// granted -- the side menu already hides these, but a bookmarked/typed URL
/// must not bypass that.
PageRoute _guarded(String route, Widget page) {
  final pageKey = pageKeyForRoute[route];
  final allowed = pageKey == null || AuthState.canAccessPageKey(pageKey);
  return _getPageRoute(allowed ? page : const NotAuthorizedPage());
}

PageRoute _getPageRoute(Widget child) {
  return MaterialPageRoute(builder: (context) => child);
}
