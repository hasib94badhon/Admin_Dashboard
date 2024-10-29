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
 MenuItem(authenticationPageDisplayName, authenticationPageRoute),
];
