const rootRoute = "/";

const overviewPageDisplayName = "Overview";
const overviewPageRoute = "/overview";

const driversPageDisplayName = "Categories";
const driversPageRoute = "/drivers";

const clientsPageDisplayName = "Users";
const clientsPageRoute = "/clients";

const InsertPageDisplayName = "Insert";
const InsertPageRoute = "/insert";

const AppstatusPageDisplayName = "App Status";
const AppstatusPageRoute = "/appstatus";

const staffAdminPageDisplayName = "Staff Admin";
const staffAdminPageRoute = "/staff-admin";

const referralPageDisplayName = "User Referral";
const referralPageRoute = "/referral";

const deactivationPageDisplayName = "User Deactivation";
const deactivationPageRoute = "/deactivation";

const servicePageDisplayName = "Service";
const servicePageRoute = "/service";

const shopPageDisplayName = "Shop";
const shopPageRoute = "/shop";

const subscriberPageDisplayName = "Subscribers";
const subscriberPageRoute = "/subscribers";

const authenticationPageDisplayName = "Log out";
const authenticationPageRoute = "/auth";
const termsPageDisplayName = "Data Collector Instructions";
const termsPageRoute = "/terms";

class MenuItem {
  final String name;
  final String route;

  MenuItem(this.name, this.route);
}

List<MenuItem> sideMenuItemRoutes = [
  MenuItem(overviewPageDisplayName, overviewPageRoute),
  MenuItem(driversPageDisplayName, driversPageRoute),
  MenuItem(clientsPageDisplayName, clientsPageRoute),
  MenuItem(InsertPageDisplayName, InsertPageRoute),
  MenuItem(AppstatusPageDisplayName, AppstatusPageRoute),
  // MenuItem(staffAdminPageDisplayName, staffAdminPageRoute),
  MenuItem(referralPageDisplayName, referralPageRoute),
  MenuItem(deactivationPageDisplayName, deactivationPageRoute),
  MenuItem(servicePageDisplayName, servicePageRoute),
  MenuItem(shopPageDisplayName, shopPageRoute),
  MenuItem(subscriberPageDisplayName, subscriberPageRoute),
  // MenuItem(authenticationPageDisplayName, authenticationPageRoute),
  MenuItem(termsPageDisplayName, termsPageRoute),
];
