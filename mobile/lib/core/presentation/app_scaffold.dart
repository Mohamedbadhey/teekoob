import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/core/services/language_service.dart';
import 'package:teekoob/core/services/navigation_service.dart';
import 'package:teekoob/core/services/network_service.dart';
import 'package:teekoob/core/config/app_router.dart';
import 'package:teekoob/features/home/presentation/pages/home_page.dart';
import 'package:teekoob/features/books/presentation/pages/books_page.dart';
import 'package:teekoob/features/library/presentation/pages/library_page.dart';
import 'package:teekoob/features/settings/presentation/pages/settings_page.dart';
import 'package:teekoob/core/presentation/widgets/floating_audio_player.dart';
import 'package:teekoob/core/services/global_audio_player_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teekoob/features/auth/bloc/auth_bloc.dart';
import 'package:teekoob/features/auth/services/auth_service.dart';
import 'package:teekoob/core/services/network_service.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isOffline = false;
  final NetworkService _networkService = NetworkService();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  StreamSubscription<GoRouterState>? _routeSubscription;

  final List<Widget> _pages = [
    const HomePage(),
    const BooksPage(),
    const LibraryPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _networkService.initialize();
    _checkConnectivity();
    _listenToConnectivity();
    _checkAuthToken();
    _setupAuthListener();
    
    // Initialize current index based on route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final location = GoRouterState.of(context).uri.path;
        final index = NavigationService.getTabForRoute(location);
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
          });
        }
      }
    });
  }
  
  void _checkAuthToken() async {
    // Check token on app start and periodically
    final authService = AuthService();
    final isAuthenticated = await authService.isAuthenticated();
    if (!isAuthenticated && mounted) {
      // No token found, ensure user is logged out
      context.read<AuthBloc>().add(const LogoutRequested());
      context.go('/login');
    }
  }
  
  void _setupAuthListener() {
    // Auth state is checked via BlocListener in build method
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await _networkService.isConnected();
    if (!isConnected && !_isOffline) {
      _handleOffline();
    } else if (isConnected && _isOffline) {
      _handleOnline();
    }
  }

  void _listenToConnectivity() {
    _connectivitySubscription = _networkService.connectivityStream.listen((result) {
      final isConnected = result != ConnectivityResult.none;
      if (!isConnected && !_isOffline) {
        _handleOffline();
      } else if (isConnected && _isOffline) {
        _handleOnline();
      }
    });
  }

  void _handleOffline() {
    if (mounted) {
      setState(() {
        _isOffline = true;
      });
      
      // Navigate to library page (index 2) with offline tab
      if (_currentIndex != 2) {
        setState(() {
          _currentIndex = 2;
        });
        context.go('/home/library?tab=offline');
      } else {
        // Already on library page, just switch to offline tab
        context.go('/home/library?tab=offline');
      }
      
      // Show offline banner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.getLocalizedText(
              englishText: 'No internet connection. Showing offline content.',
              somaliText: 'Ma jiro internet. Waxaan tusaynaa waxa lagu kaydiyay.',
            ),
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleOnline() {
    if (mounted) {
      setState(() {
        _isOffline = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.getLocalizedText(
              englishText: 'Internet connection restored.',
              somaliText: 'Internetka waa la soo celiyay.',
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    _routeSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Handle app lifecycle changes for background audio
    final audioService = GlobalAudioPlayerService();
    audioService.handleAppLifecycleChange(state);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update index based on current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateCurrentIndex();
      }
    });
  }

  void _updateCurrentIndex() {
    final location = GoRouterState.of(context).uri.path;
    
    // Always default to Home (index 0) for hot refresh
    // This ensures that hot refresh always shows Home tab selected
    _currentIndex = NavigationService.getTabForRoute(location);
  }

  Future<void> _showExitConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            LocalizationService.getLocalizedText(
              englishText: 'Exit App',
              somaliText: 'Ka Bax App-ka',
            ),
          ),
          content: Text(
            LocalizationService.getLocalizedText(
              englishText: 'Are you ready to close the app?',
              somaliText: 'Ma diyaar u tahay inaad xirto app-ka?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Cancel',
                  somaliText: 'Jooji',
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Exit',
                  somaliText: 'Ka Bax',
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // User confirmed exit - close the app
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync current index with route
    final location = GoRouterState.of(context).uri.path;
    final routeIndex = NavigationService.getTabForRoute(location);
    
    // Update index if different - use post frame callback to avoid setState during build
    if (_currentIndex != routeIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentIndex != routeIndex) {
          setState(() {
            _currentIndex = routeIndex;
          });
        }
      });
    }
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // If user becomes unauthenticated, redirect to login
        if (state is Unauthenticated && mounted) {
          context.go('/login');
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            // Show exit confirmation dialog when Android back button is pressed
            await _showExitConfirmationDialog(context);
          }
        },
        child: Consumer<LanguageService>(
        builder: (context, languageService, child) {
          return ChangeNotifierProvider<GlobalAudioPlayerService>(
            create: (context) => GlobalAudioPlayerService(),
            child: Scaffold(
              body: Stack(
                children: [
                  IndexedStack(
                    index: _currentIndex,
                    children: _pages,
                  ),
                  // Floating Audio Player (draggable)
                  const FloatingAudioPlayer(),
                ],
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
            // Don't navigate if already on this tab
            if (_currentIndex == index) {
              return;
            }
            
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
            ),
          );
        },
      ),
      ),
    );
  }
}
