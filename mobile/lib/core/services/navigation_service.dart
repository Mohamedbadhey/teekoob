import 'package:shared_preferences/shared_preferences.dart';

class NavigationService {
  static const String _lastTabKey = 'last_bottom_navigation_tab';
  
  // Save the last visited bottom navigation tab
  static Future<void> saveLastTab(int tabIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastTabKey, tabIndex);
  }
  
  // Get the last visited bottom navigation tab (defaults to 0 = Home)
  static Future<int> getLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastTabKey) ?? 0; // Default to Home (index 0)
  }
  
  // Clear the last tab (useful for logout or reset)
  static Future<void> clearLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastTabKey);
  }
  
  // Get the route for a given tab index
  static String getRouteForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return '/home';
      case 1:
        return '/home/books';
      case 2:
        return '/home/library';
      case 3:
        return '/home/settings';
      default:
        return '/home';
    }
  }
  
  // Get tab index for a given route
  static int getTabForRoute(String route) {
    switch (route) {
      case '/home':
      case '/home/':
        return 0;
      case '/home/books':
        return 1;
      case '/home/library':
        return 2;
      case '/home/settings':
        return 3;
      default:
        return 0;
    }
  }
}
