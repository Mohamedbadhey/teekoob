import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/core/services/language_service.dart';
import 'package:teekoob/core/services/navigation_service.dart';
import 'package:teekoob/features/home/presentation/pages/home_page.dart';
import 'package:teekoob/features/books/presentation/pages/books_page.dart';
import 'package:teekoob/features/library/presentation/pages/library_page.dart';
import 'package:teekoob/features/settings/presentation/pages/settings_page.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const BooksPage(),
    const LibraryPage(),
    const SettingsPage(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentIndex();
  }

  void _updateCurrentIndex() {
    final location = GoRouterState.of(context).uri.path;
    print('Current location: $location'); // Debug log
    
    // Always default to Home (index 0) for hot refresh
    // This ensures that hot refresh always shows Home tab selected
    _currentIndex = NavigationService.getTabForRoute(location);
    
    print('Updated current index to: $_currentIndex'); // Debug log
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) async {
            setState(() {
              _currentIndex = index;
            });
            
            // Save the last visited tab
            await NavigationService.saveLastTab(index);
            
            // Navigate to the correct route
            final route = NavigationService.getRouteForTab(index);
            context.go(route);
          },
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                color: _currentIndex == 0 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              label: LocalizationService.getHomeText,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.explore,
                color: _currentIndex == 1 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              label: LocalizationService.getBooksText,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.library_books,
                color: _currentIndex == 2 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              label: LocalizationService.getLibraryText,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                color: _currentIndex == 3 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              label: LocalizationService.getProfileText,
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
