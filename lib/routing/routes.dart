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

const subscriberPageDisplayName = "Subscriber";
const subscriberPageRoute = "/subscriber";

const referralPageDisplayName = "User Referral";
const referralPageRoute = "/referral";

const deactivationPageDisplayName = "User Deactivation";
const deactivationPageRoute = "/deactivation";

const servicePageDisplayName = "Service";
const servicePageRoute = "/service";

const shopPageDisplayName = "Shop";
const shopPageRoute = "/shop";

const locationPageDisplayName = "Location";
const locationPageRoute = "/location";

const authenticationPageDisplayName = "Log out";
const authenticationPageRoute = "/auth";

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
  MenuItem(subscriberPageDisplayName, subscriberPageRoute),
  MenuItem(referralPageDisplayName, referralPageRoute),
  MenuItem(deactivationPageDisplayName, deactivationPageRoute),
  // MenuItem(servicePageDisplayName, servicePageRoute),
  // MenuItem(shopPageDisplayName, shopPageRoute),
  // MenuItem(locationPageDisplayName, locationPageRoute),
  // MenuItem(authenticationPageDisplayName, authenticationPageRoute),
];
