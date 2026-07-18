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

const deletedAccountsPageDisplayName = "Deleted Accounts";
const deletedAccountsPageRoute = "/deleted-accounts";

const servicePageDisplayName = "Service";
const servicePageRoute = "/service";

const shopPageDisplayName = "Shop";
const shopPageRoute = "/shop";

const subscriberPageDisplayName = "Subscribers";
const subscriberPageRoute = "/subscribers";

const reactionsPageDisplayName = "Reactions";
const reactionsPageRoute = "/reactions";

const authenticationPageDisplayName = "Log out";
const authenticationPageRoute = "/auth";
const termsPageDisplayName = "Data Collector Instructions";
const termsPageRoute = "/terms";
const contactPageDisplayName = "Contact Info";
const contactPageRoute = "/contact";
const notificationsPageDisplayName = "Notifications";
const notificationsPageRoute = "/notifications";

class MenuItem {
  final String name;
  final String route;

  MenuItem(this.name, this.route);
}

// Every togglable page/section a superadmin can grant to an admin. Mirrors
// members/permissions.py's PAGE_KEYS on the backend -- keep both in sync.
// 'staff_admin' is deliberately NOT a page key: managing other admins is
// always superuser-only, never toggle-able.
List<MenuItem> sideMenuItemRoutes = [
  MenuItem(overviewPageDisplayName, overviewPageRoute),
  MenuItem(driversPageDisplayName, driversPageRoute),
  MenuItem(clientsPageDisplayName, clientsPageRoute),
  MenuItem(InsertPageDisplayName, InsertPageRoute),
  MenuItem(AppstatusPageDisplayName, AppstatusPageRoute),
  MenuItem(referralPageDisplayName, referralPageRoute),
  MenuItem(deactivationPageDisplayName, deactivationPageRoute),
  MenuItem(deletedAccountsPageDisplayName, deletedAccountsPageRoute),
  MenuItem(servicePageDisplayName, servicePageRoute),
  MenuItem(shopPageDisplayName, shopPageRoute),
  MenuItem(subscriberPageDisplayName, subscriberPageRoute),
  MenuItem(reactionsPageDisplayName, reactionsPageRoute),
  MenuItem(notificationsPageDisplayName, notificationsPageRoute),
  // MenuItem(authenticationPageDisplayName, authenticationPageRoute),
  MenuItem(termsPageDisplayName, termsPageRoute),
  MenuItem(contactPageDisplayName, contactPageRoute),
];

// route -> backend page-key, for filtering the menu/routes by an admin's
// allowed_pages (from the login response). Superadmins bypass this entirely.
const Map<String, String> pageKeyForRoute = {
  overviewPageRoute: 'overview',
  driversPageRoute: 'drivers',
  clientsPageRoute: 'clients',
  InsertPageRoute: 'insert',
  AppstatusPageRoute: 'appstatus',
  referralPageRoute: 'referral',
  deactivationPageRoute: 'deactivation',
  deletedAccountsPageRoute: 'deleted_accounts',
  servicePageRoute: 'service',
  shopPageRoute: 'shop',
  subscriberPageRoute: 'subscribers',
  reactionsPageRoute: 'reactions',
  notificationsPageRoute: 'notifications',
  termsPageRoute: 'terms',
  contactPageRoute: 'contact',
};

// Every page key a superadmin can grant, in menu order, with its display
// label -- drives the checkbox list on the Manage Admins page.
const List<String> allPageKeys = [
  'overview', 'drivers', 'clients', 'insert', 'appstatus',
  'referral', 'deactivation', 'deleted_accounts', 'service', 'shop',
  'subscribers', 'reactions', 'notifications', 'terms', 'contact',
];

const Map<String, String> pageKeyLabels = {
  'overview': overviewPageDisplayName,
  'drivers': driversPageDisplayName,
  'clients': clientsPageDisplayName,
  'insert': InsertPageDisplayName,
  'appstatus': AppstatusPageDisplayName,
  'referral': referralPageDisplayName,
  'deactivation': deactivationPageDisplayName,
  'deleted_accounts': deletedAccountsPageDisplayName,
  'service': servicePageDisplayName,
  'shop': shopPageDisplayName,
  'subscribers': subscriberPageDisplayName,
  'reactions': reactionsPageDisplayName,
  'notifications': notificationsPageDisplayName,
  'terms': termsPageDisplayName,
  'contact': contactPageDisplayName,
};
