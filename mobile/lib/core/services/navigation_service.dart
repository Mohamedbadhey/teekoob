// import 'package:shared_preferences/shared_preferences.dart'; // Removed - no local storage

class NavigationService {
  static const String _lastTabKey = 'last_bottom_navigation_tab';
  
  // Save the last visited bottom navigation tab
  static Future<void> saveLastTab(int tabIndex) async {
    // Note: No local storage - return default values
    // final prefs = await SharedPreferences.getInstance();
    // Note: No local storage - tab not saved locally
    // await prefs.setInt(_lastTabKey, tabIndex);
  }
  
  // Get the last visited bottom navigation tab (defaults to 0 = Home)
  static Future<int> getLastTab() async {
    // Note: No local storage - return default values
    // final prefs = await SharedPreferences.getInstance();
    // Note: No local storage - return default tab
    return 0; // Default to Home (index 0)
  }
  
  // Clear the last tab (useful for logout or reset)
  static Future<void> clearLastTab() async {
    // Note: No local storage - return default values
    // final prefs = await SharedPreferences.getInstance();
    // Note: No local storage - nothing to clear
    // await prefs.remove(_lastTabKey);
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
