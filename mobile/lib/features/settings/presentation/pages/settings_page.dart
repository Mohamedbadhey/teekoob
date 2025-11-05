import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/core/services/language_service.dart';
import 'package:teekoob/core/services/theme_service.dart';
import 'package:teekoob/features/auth/bloc/auth_bloc.dart';
import 'package:teekoob/features/settings/bloc/settings_bloc.dart';
import 'package:teekoob/core/config/app_theme.dart';
import 'package:teekoob/features/settings/presentation/pages/notification_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _autoDownloadEnabled = false;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'en';
  String _selectedTheme = 'system';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // Load settings when the page initializes
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<SettingsBloc>().add(LoadSettings(authState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is AuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is Unauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          LocalizationService.getSettingsText,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(),
            
            const Divider(height: 1),
            
            // Preferences Section
            _buildPreferencesSection(),
            
            const Divider(height: 1),
            
            // Account Section
            _buildAccountSection(),
            
            const Divider(height: 1),
            
            // Support Section
            _buildSupportSection(),
            
            const Divider(height: 1),
            
            // About Section
            _buildAboutSection(),
            
            const SizedBox(height: 32),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // If not authenticated, redirect to login
        if (authState is! Authenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/login');
            }
          });
          return const SizedBox.shrink();
        }

        final userName = authState.user.displayName;
        final userEmail = authState.user.email;
        final avatarUrl = authState.user.profilePicture;
        
        print('🔍 Profile Section Debug:');
        print('   - User authenticated: true');
        print('   - User name: $userName');
        print('   - User email: $userEmail');
        print('   - Avatar URL: $avatarUrl');
        print('   - Profile picture field: ${authState.user.profilePicture}');

        return _buildSection(
          title: LocalizationService.getProfileText,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0466c8).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: _buildProfileAvatar(avatarUrl),
                title: Text(
                  userName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  userEmail,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0466c8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF0466c8),
                    ),
                    onPressed: () {
                      if (authState is Authenticated) {
                        context.push('/edit-profile');
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreferencesSection() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            return Consumer<ThemeService>(
              builder: (context, themeService, child) {
                print('🎨 Settings: Consumer rebuild - current theme: ${themeService.currentTheme}');
            // Get current settings
            String currentLanguage = 'en';
            String currentTheme = 'system';
            bool notificationsEnabled = true;
            bool autoDownloadEnabled = false;

                // Get current theme from ThemeService
                switch (themeService.currentTheme) {
                  case ThemeMode.light:
                    currentTheme = 'light';
                    break;
                  case ThemeMode.dark:
                    currentTheme = 'dark';
                    break;
                  case ThemeMode.system:
                  default:
                    currentTheme = 'system';
                    break;
                }
                print('🎨 Settings: Converted theme to string: $currentTheme');

            if (authState is Authenticated) {
              currentLanguage = authState.user.preferredLanguage;
            }

            if (settingsState is SettingsLoaded) {
              currentLanguage = settingsState.settings['language'] ?? currentLanguage;
              notificationsEnabled = settingsState.settings['notifications']?['newReleases'] ?? true;
              autoDownloadEnabled = settingsState.settings['autoDownload'] ?? false;
            }

    return _buildSection(
      title: LocalizationService.getLocalizedText(
        englishText: 'Preferences',
        somaliText: 'Doorashooyin',
      ),
      children: [
        // Language Setting
                _buildPreferenceCard(
                  icon: Icons.language_rounded,
                  title: LocalizationService.getLanguageText,
                  subtitle: currentLanguage == 'en' ? 'English' : 'Soomaali',
                  trailing: _buildLanguageDropdown(currentLanguage, authState),
        ),
        
        // Theme Setting
                _buildPreferenceCard(
                  icon: Icons.palette_rounded,
                  title: LocalizationService.getThemeText,
                  subtitle: _getThemeDisplayName(currentTheme),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onPressed: () => _showThemeSelectionDialog(authState),
                  ),
        ),
        
        // Notifications Setting
                _buildPreferenceCard(
                  icon: Icons.notifications_rounded,
                  title: LocalizationService.getNotificationsText,
                  subtitle: LocalizationService.getLocalizedText(
              englishText: 'Manage notification settings',
              somaliText: 'Maamul dejinta ogeysiisyo',
            ),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsPage(),
                      ),
                    ),
                  ),
        ),
        
        // Auto Download Setting
                _buildPreferenceCard(
                  icon: Icons.download_rounded,
                  title: LocalizationService.getLocalizedText(
            englishText: 'Auto Download',
            somaliText: 'Si toos ah u soo deji',
                  ),
                  subtitle: LocalizationService.getLocalizedText(
              englishText: 'Automatically download new books',
              somaliText: 'Si toos ah u soo deji kutub cusub',
            ),
                  trailing: Switch(
                    value: autoDownloadEnabled,
                    onChanged: (value) => _updateAutoDownload(value, authState),
                    activeColor: const Color(0xFF0466c8),
                  ),
                ),
              ],
            );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAccountSection() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
    return _buildSection(
      title: LocalizationService.getLocalizedText(
        englishText: 'Account',
        somaliText: 'Akoonka',
      ),
      children: [
            // Change Password
            _buildAccountCard(
              icon: Icons.security_rounded,
              title: LocalizationService.getLocalizedText(
            englishText: 'Change Password',
            somaliText: 'Beddel Furaha',
              ),
              subtitle: LocalizationService.getLocalizedText(
                englishText: 'Update your account password',
                somaliText: 'Cusboonaysii furaha akoonkaaga',
              ),
              onTap: () => _showChangePasswordDialog(authState),
            ),
            
            // Subscription
            _buildAccountCard(
              icon: Icons.subscriptions_rounded,
              title: LocalizationService.getLocalizedText(
            englishText: 'Subscription',
            somaliText: 'Diiwaangelinta',
              ),
              subtitle: LocalizationService.getLocalizedText(
                englishText: 'Manage your subscription plan',
                somaliText: 'Maamul qorshaha diiwaangelinta',
              ),
              onTap: () => context.go('/subscription'),
            ),
            
            // Logout
            _buildAccountCard(
              icon: Icons.logout_rounded,
              title: LocalizationService.getLogoutText,
              subtitle: LocalizationService.getLocalizedText(
                englishText: 'Sign out of your account',
                somaliText: 'Ka bax akoonkaaga',
              ),
              onTap: () => _showLogoutDialog(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSupportSection() {
    return _buildSection(
      title: LocalizationService.getLocalizedText(
        englishText: 'Support',
        somaliText: 'Taageero',
      ),
      children: [
        // Send Feedback
        _buildSupportCard(
          icon: Icons.feedback_rounded,
          title: LocalizationService.getLocalizedText(
            englishText: 'Send Feedback',
            somaliText: 'Dir Feedback',
          ),
          subtitle: LocalizationService.getLocalizedText(
            englishText: 'Share your thoughts and suggestions',
            somaliText: 'Wadaag fikirkaaga iyo talooyinka',
          ),
          onTap: () => _showFeedbackDialog(),
        ),
        
        // Report Bug
        _buildSupportCard(
          icon: Icons.bug_report_rounded,
          title: LocalizationService.getLocalizedText(
            englishText: 'Report Bug',
            somaliText: 'Sheeg Khalad',
          ),
          subtitle: LocalizationService.getLocalizedText(
            englishText: 'Report issues you encountered',
            somaliText: 'Sheeg dhibaatooyinka aad la kulantay',
          ),
          onTap: () => _showBugReportDialog(),
        ),
        
        // Contact Support
        _buildSupportCard(
          icon: Icons.contact_support_rounded,
          title: LocalizationService.getLocalizedText(
            englishText: 'Contact Support',
            somaliText: 'La Xidhiidh Taageero',
          ),
          subtitle: LocalizationService.getLocalizedText(
            englishText: 'Get in touch with our support team',
            somaliText: 'La xidhiidh kooxda taageerada',
          ),
          onTap: () => _showContactSupportDialog(),
        ),
        
        // Rate App
        _buildSupportCard(
          icon: Icons.star_rounded,
          title: LocalizationService.getLocalizedText(
            englishText: 'Rate App',
            somaliText: 'Qiimee Appka',
          ),
          subtitle: LocalizationService.getLocalizedText(
            englishText: 'Rate us on the app store',
            somaliText: 'Qiimee app store-ka',
          ),
          onTap: () => _showRateAppDialog(),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: LocalizationService.getLocalizedText(
        englishText: 'About',
        somaliText: 'Ku Saabsan',
      ),
      children: [
        // App Version
        _buildAboutCard(
          icon: Icons.info_rounded,
          title: LocalizationService.getLocalizedText(
            englishText: 'App Version',
            somaliText: 'Nooca Appka',
          ),
          subtitle: '1.0.0 (Build 100)',
          onTap: () => _showVersionInfoDialog(),
        ),
        
        // App Info
        _buildAboutCard(
          icon: Icons.apps_rounded,
          title: LocalizationService.getLocalizedText(
            englishText: 'App Information',
            somaliText: 'Macluumaadka Appka',
          ),
          subtitle: LocalizationService.getLocalizedText(
            englishText: 'Developer and company details',
            somaliText: 'Horumarayaasha iyo macluumaadka shirkadda',
          ),
          onTap: () => _showAppInfoDialog(),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildPreferenceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0466c8).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0466c8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0466c8),
            size: 24,
          ),
        ),
        title: Text(
          title,
            style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildLanguageDropdown(String currentLanguage, AuthState authState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0466c8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0466c8).withOpacity(0.3),
        ),
      ),
      child: DropdownButton<String>(
        value: currentLanguage,
        underline: Container(),
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0466c8)),
        dropdownColor: Theme.of(context).colorScheme.surface,
        items: [
          DropdownMenuItem(
            value: 'en',
            child: Text(
              'English',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          DropdownMenuItem(
            value: 'so',
            child: Text(
              'Soomaali',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
        onChanged: (value) => _updateLanguage(value!, authState),
      ),
    );
  }


  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'system':
        return LocalizationService.getLocalizedText(
          englishText: 'System',
          somaliText: 'Nidaamka',
        );
      case 'light':
        return LocalizationService.getLocalizedText(
          englishText: 'Light',
          somaliText: 'Iftiin',
        );
      case 'dark':
        return LocalizationService.getLocalizedText(
          englishText: 'Dark',
          somaliText: 'Madow',
        );
      default:
        return 'System';
    }
  }

  void _updateLanguage(String language, AuthState authState) async {
    // Update the language service immediately for UI responsiveness
    final languageService = context.read<LanguageService>();
    await languageService.changeLanguage(language);
    
    if (authState is Authenticated) {
      // Only update settings, don't trigger profile update to avoid logout
      context.read<SettingsBloc>().add(UpdateLanguage(authState.user.id, language));
      
      _showSuccessMessage(LocalizationService.getLocalizedText(
        englishText: 'Language updated successfully!',
        somaliText: 'Luqadda si guul leh ayaa loo cusboonaysiiyay!',
      ));
    }
  }

  void _showThemeSelectionDialog(AuthState authState) {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeService>(
        builder: (context, themeService, child) => _ThemeSelectionDialog(
          authState: authState,
          themeService: themeService,
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildProfileAvatar(String? avatarUrl) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? Icon(
              Icons.person,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthState authState) {
    // TODO: Implement edit profile dialog
  }

  void _updateNotifications(bool value, AuthState authState) {
    // TODO: Implement notifications update
  }

  void _updateAutoDownload(bool value, AuthState authState) {
    // TODO: Implement auto download update
  }

  Widget _buildAccountCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showChangePasswordDialog(AuthState authState) {
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to change your password')),
      );
      return;
    }

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.getLocalizedText(
          englishText: 'Change Password',
          somaliText: 'Beddel Furaha',
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: LocalizationService.getLocalizedText(
                  englishText: 'Current Password',
                  somaliText: 'Furaha Hadda',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: LocalizationService.getLocalizedText(
                  englishText: 'New Password',
                  somaliText: 'Furaha Cusub',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: LocalizationService.getLocalizedText(
                  englishText: 'Confirm New Password',
                  somaliText: 'Xaqiiji Furaha Cusub',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'Cancel',
              somaliText: 'Jooji',
            )),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              
              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }

              context.read<AuthBloc>().add(ChangePasswordRequested(
                currentPassword: currentPasswordController.text,
                newPassword: newPasswordController.text,
              ));
              
              Navigator.of(context).pop();
            },
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'Change Password',
              somaliText: 'Beddel Furaha',
            )),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettingsDialog(AuthState authState) {
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to access privacy settings')),
      );
      return;
    }

    bool profileVisibility = authState.user.preferences['profileVisibility'] ?? true;
    bool readingHistory = authState.user.preferences['readingHistory'] ?? true;
    bool recommendations = authState.user.preferences['recommendations'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(LocalizationService.getLocalizedText(
            englishText: 'Privacy Settings',
            somaliText: 'Dejinta Sirta',
          )),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(LocalizationService.getLocalizedText(
                  englishText: 'Profile Visibility',
                  somaliText: 'Aragtida Profile',
                )),
                subtitle: Text(LocalizationService.getLocalizedText(
                  englishText: 'Allow others to see your profile',
                  somaliText: 'U ogolow dadka kale inay arkaan profile-kaaga',
                )),
                value: profileVisibility,
                onChanged: (value) => setState(() => profileVisibility = value),
              ),
              SwitchListTile(
                title: Text(LocalizationService.getLocalizedText(
                  englishText: 'Reading History',
                  somaliText: 'Taariikhda Akhriska',
                )),
                subtitle: Text(LocalizationService.getLocalizedText(
                  englishText: 'Save your reading history',
                  somaliText: 'Kaydi taariikhda akhriskaaga',
                )),
                value: readingHistory,
                onChanged: (value) => setState(() => readingHistory = value),
              ),
              SwitchListTile(
                title: Text(LocalizationService.getLocalizedText(
                  englishText: 'Personalized Recommendations',
                  somaliText: 'Talooyinka Gaarka ah',
                )),
                subtitle: Text(LocalizationService.getLocalizedText(
                  englishText: 'Get book recommendations based on your activity',
                  somaliText: 'Hel talooyin ku salaysan dhaqdhaqaaqaaga',
                )),
                value: recommendations,
                onChanged: (value) => setState(() => recommendations = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(LocalizationService.getLocalizedText(
                englishText: 'Cancel',
                somaliText: 'Jooji',
              )),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedPreferences = Map<String, dynamic>.from(authState.user.preferences);
                updatedPreferences['profileVisibility'] = profileVisibility;
                updatedPreferences['readingHistory'] = readingHistory;
                updatedPreferences['recommendations'] = recommendations;

                context.read<AuthBloc>().add(UpdateProfileRequested(
                  // Update preferences through profile update
                ));
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy settings updated')),
                );
              },
              child: Text(LocalizationService.getLocalizedText(
                englishText: 'Save',
                somaliText: 'Kaydi',
              )),
            ),
          ],
        ),
      ),
    );
  }

  void _showDataStorageDialog(AuthState authState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.getLocalizedText(
          englishText: 'Data & Storage',
          somaliText: 'Xogta & Kaydinta',
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'Manage your app data and storage:',
                somaliText: 'Maamul xogta app-ka iyo kaydinta:',
              ),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(LocalizationService.getLocalizedText(
                englishText: 'Clear Cache',
                somaliText: 'Nadiif Cache',
              )),
              subtitle: Text(LocalizationService.getLocalizedText(
                englishText: 'Remove temporary files',
                somaliText: 'Ka saar faylasha ku meel gaar ah',
              )),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: Text(LocalizationService.getLocalizedText(
                englishText: 'Clear Downloads',
                somaliText: 'Nadiif Soo dejinta',
              )),
              subtitle: Text(LocalizationService.getLocalizedText(
                englishText: 'Remove downloaded books',
                somaliText: 'Ka saar kutubta la soo dejiyay',
              )),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloads cleared successfully')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(LocalizationService.getLocalizedText(
                englishText: 'Clear Reading History',
                somaliText: 'Nadiif Taariikhda Akhriska',
              )),
              subtitle: Text(LocalizationService.getLocalizedText(
                englishText: 'Remove reading progress',
                somaliText: 'Ka saar horumarka akhriska',
              )),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reading history cleared successfully')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'Close',
              somaliText: 'Xidhiidh',
            )),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.getLocalizedText(
          englishText: 'Logout',
          somaliText: 'Ka Bax',
        )),
        content: Text(LocalizationService.getLocalizedText(
          englishText: 'Are you sure you want to logout?',
          somaliText: 'Ma hubtaa inaad rabto inaad ka baxdo?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'Cancel',
              somaliText: 'Jooji',
            )),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(const LogoutRequested());
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'Logout',
              somaliText: 'Ka Bax',
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showHelpDialog() {
    // TODO: Implement help dialog
  }

  void _showFeedbackDialog() {
    // TODO: Implement feedback dialog
  }

  void _showBugReportDialog() {
    // TODO: Implement bug report dialog
  }

  void _showContactSupportDialog() {
    // TODO: Implement contact support dialog
  }

  void _showRateAppDialog() {
    // TODO: Implement rate app dialog
  }

  Widget _buildAboutCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showVersionInfoDialog() {
    // TODO: Implement version info dialog
  }

  void _showTermsOfServiceDialog() {
    // TODO: Implement terms of service dialog
  }

  void _showPrivacyPolicyDialog() {
    // TODO: Implement privacy policy dialog
  }

  void _showOpenSourceLicensesDialog() {
    // TODO: Implement open source licenses dialog
  }

  void _showAppInfoDialog() {
    // TODO: Implement app info dialog
  }
}

class _ThemeSelectionDialog extends StatefulWidget {
  final AuthState authState;
  final ThemeService themeService;

  const _ThemeSelectionDialog({
    required this.authState,
    required this.themeService,
  });

  @override
  State<_ThemeSelectionDialog> createState() => _ThemeSelectionDialogState();
}

class _ThemeSelectionDialogState extends State<_ThemeSelectionDialog> {
  String selectedTheme = 'system';
  late ThemeService _themeService;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _themeService = widget.themeService;
    _themeService.addListener(_onThemeChanged);
    selectedTheme = _getCurrentThemeString(_themeService);
    print('🎨 Theme Dialog: initState - selectedTheme: $selectedTheme, currentTheme: ${_themeService.currentTheme}');
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        selectedTheme = _getCurrentThemeString(_themeService);
      });
    }
  }

  String _getCurrentThemeString(ThemeService themeService) {
    switch (themeService.currentTheme) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Theme Dialog: Building with _themeService.currentTheme: ${_themeService.currentTheme}');
    print('🎨 Theme Dialog: Building with selectedTheme: $selectedTheme');
    print('🎨 Theme Dialog: Building with _isApplying: $_isApplying');
    
    return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0466c8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.palette_rounded,
                  color: Color(0xFF0466c8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocalizationService.getThemeText,
                style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Description text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        LocalizationService.getLocalizedText(
                          englishText: 'Choose your preferred theme. Changes will be applied immediately.',
                          somaliText: 'Dooro mawduuca aad jeclaan karto. Isbeddelada ayaa si dhaqso leh loo codsiin doonaa.',
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
                      // System Theme Option
                      _buildThemeRadioOption(
                        value: 'system',
                        groupValue: selectedTheme,
                        title: LocalizationService.getLocalizedText(
                          englishText: 'System',
                          somaliText: 'Nidaamka',
                        ),
                        subtitle: LocalizationService.getLocalizedText(
                          englishText: 'Follow device theme',
                          somaliText: 'Raac mawduuca qalabka',
                        ),
                        icon: Icons.settings_brightness_rounded,
                        onChanged: (value) {
                          print('🎨 Theme Dialog: System theme selected: $value');
                          setState(() {
                            selectedTheme = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Light Theme Option
                      _buildThemeRadioOption(
                        value: 'light',
                        groupValue: selectedTheme,
                        title: LocalizationService.getLocalizedText(
                          englishText: 'Light',
                          somaliText: 'Iftiin',
                        ),
                        subtitle: LocalizationService.getLocalizedText(
                          englishText: 'Always use light theme',
                          somaliText: 'Had iyo jeer isticmaal mawduuc iftiin',
                        ),
                        icon: Icons.light_mode_rounded,
                        onChanged: (value) {
                          print('🎨 Theme Dialog: Light theme selected: $value');
                          setState(() {
                            selectedTheme = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Dark Theme Option
                      _buildThemeRadioOption(
                        value: 'dark',
                        groupValue: selectedTheme,
                        title: LocalizationService.getLocalizedText(
                          englishText: 'Dark',
                          somaliText: 'Madow',
                        ),
                        subtitle: LocalizationService.getLocalizedText(
                          englishText: 'Always use dark theme',
                          somaliText: 'Had iyo jeer isticmaal mawduuc madow',
                        ),
                        icon: Icons.dark_mode_rounded,
                        onChanged: (value) {
                          print('🎨 Theme Dialog: Dark theme selected: $value');
                          setState(() {
                            selectedTheme = value!;
                          });
                        },
                      ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                LocalizationService.getCancelText,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
              ElevatedButton(
                onPressed: _isApplying ? null : () {
                  print('🎨 Theme Dialog: Apply button pressed with selectedTheme: $selectedTheme');
                  print('🎨 Theme Dialog: _isApplying: $_isApplying');
                  
                  if (_isApplying) {
                    print('🎨 Theme Dialog: Already applying, ignoring press');
                    return;
                  }
                  
                  if (widget.authState is Authenticated) {
                    setState(() {
                      _isApplying = true;
                    });
                    
                    print('🎨 Settings: _updateTheme called with: $selectedTheme');
                    print('🎨 Settings: Current ThemeService theme before change: ${_themeService.currentTheme}');
                    
                    // Update theme using ThemeService
                    _themeService.setThemeFromString(selectedTheme);
                    print('🎨 Settings: After setThemeFromString, ThemeService theme: ${_themeService.currentTheme}');
                    
                    // Close dialog first
                    Navigator.of(context).pop();
                    
                    // Wait a moment for the theme to propagate, then save settings
                    Future.delayed(const Duration(milliseconds: 200), () {
                      print('🎨 Settings: ThemeService theme after delay: ${_themeService.currentTheme}');
                      
                      // Save to settings for persistence
                      context.read<SettingsBloc>().add(UpdateTheme((widget.authState as Authenticated).user.id, selectedTheme));
                      context.read<AuthBloc>().add(UpdateProfileRequested(
                        themePreference: selectedTheme,
                      ));
                    });
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(LocalizationService.getLocalizedText(
        englishText: 'Theme updated successfully!',
        somaliText: 'Mawduuca si guul leh ayaa loo cusboonaysiiyay!',
                        )),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(LocalizationService.getLocalizedText(
                englishText: _isApplying ? 'Applying...' : 'Apply',
                somaliText: _isApplying ? 'Waa la codsiinayaa...' : 'Codsi',
              )),
            ),
          ],
        );
  }

  Widget _buildThemeRadioOption({
    required String value,
    required String groupValue,
    required String title,
    required String subtitle,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    final bool isSelected = value == groupValue;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Theme preview circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getThemePreviewColor(value),
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: _getThemePreviewIconColor(value),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              
              // Theme info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Radio button
              Radio<String>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: const Color(0xFF0466c8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getThemePreviewColor(String theme) {
    switch (theme) {
      case 'light':
        return Colors.white;
      case 'dark':
        return const Color(0xFF121212);
      case 'system':
      default:
        return Theme.of(context).colorScheme.primary.withOpacity(0.1);
    }
  }

  Color _getThemePreviewIconColor(String theme) {
    switch (theme) {
      case 'light':
        return Colors.black87;
      case 'dark':
        return Colors.white;
      case 'system':
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  void _updateNotifications(bool enabled, AuthState authState) {
    if (authState is Authenticated) {
      final notificationSettings = {
        'newReleases': enabled,
        'subscriptionRenewals': enabled,
        'personalizedRecommendations': enabled,
        'readingReminders': false,
        'achievements': enabled,
      };
      context.read<SettingsBloc>().add(UpdateNotifications(authState.user.id, notificationSettings));
      _showSuccessMessage(LocalizationService.getLocalizedText(
        englishText: 'Notification settings updated!',
        somaliText: 'Dejinta ogeysiisyooyinka ayaa la cusboonaysiiyay!',
      ));
    }
  }

  void _updateAutoDownload(bool enabled, AuthState authState) {
    if (authState is Authenticated) {
      context.read<SettingsBloc>().add(UpdateAutoDownload(authState.user.id, enabled));
      _showSuccessMessage(LocalizationService.getLocalizedText(
        englishText: 'Auto download setting updated!',
        somaliText: 'Dejinta soo dejinta tooska ah ayaa la cusboonaysiiyay!',
      ));
    }
  }

  Widget _buildAccountCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0466c8).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDestructive 
                ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                : const Color(0xFF0466c8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDestructive ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: isDestructive ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showChangePasswordDialog(AuthState authState) {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0466c8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: Color(0xFF0466c8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Change Password',
                  somaliText: 'Beddel Furaha',
                ),
                style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: LocalizationService.getLocalizedText(
                      englishText: 'Current Password',
                      somaliText: 'Furaha Hadda',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0466c8)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureCurrentPassword = !obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: LocalizationService.getLocalizedText(
                      englishText: 'New Password',
                      somaliText: 'Furaha Cusub',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0466c8)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: LocalizationService.getLocalizedText(
                      englishText: 'Confirm New Password',
                      somaliText: 'Xaqiiji Furaha Cusub',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0466c8)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                LocalizationService.getCancelText,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPasswordController.text != confirmPasswordController.text) {
                  _showErrorMessage(LocalizationService.getLocalizedText(
                    englishText: 'Passwords do not match!',
                    somaliText: 'Furaha ma isku mideyn!',
                  ));
                  return;
                }
                if (newPasswordController.text.length < 6) {
                  _showErrorMessage(LocalizationService.getLocalizedText(
                    englishText: 'Password must be at least 6 characters!',
                    somaliText: 'Furaha waa inay noqdaa ugu yaraan 6 xaraf!',
                  ));
                  return;
                }
                if (authState is Authenticated) {
                  context.read<AuthBloc>().add(ChangePasswordRequested(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  ));
                  Navigator.of(context).pop();
                  _showSuccessMessage(LocalizationService.getLocalizedText(
                    englishText: 'Password changed successfully!',
                    somaliText: 'Furaha si guul leh ayaa loo beddelay!',
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(LocalizationService.getLocalizedText(
                englishText: 'Change Password',
                somaliText: 'Beddel Furaha',
              )),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacySettingsDialog(AuthState authState) {
    bool profileVisibility = true;
    bool readingHistory = true;
    bool personalizedAds = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0466c8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.privacy_tip_rounded,
                  color: Color(0xFF0466c8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Privacy Settings',
                  somaliText: 'Dejinta Sirta',
                ),
                style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(LocalizationService.getLocalizedText(
                    englishText: 'Public Profile',
                    somaliText: 'Profile Gaarka',
                  )),
                  subtitle: Text(LocalizationService.getLocalizedText(
                    englishText: 'Allow others to see your profile',
                    somaliText: 'U oggolow dadka kale inay arkaan profilekaaga',
                  )),
                  value: profileVisibility,
                  onChanged: (value) {
                    setState(() {
                      profileVisibility = value;
                    });
                  },
                  activeColor: const Color(0xFF0466c8),
                ),
                SwitchListTile(
                  title: Text(LocalizationService.getLocalizedText(
                    englishText: 'Reading History',
                    somaliText: 'Taariikhda Akhriska',
                  )),
                  subtitle: Text(LocalizationService.getLocalizedText(
                    englishText: 'Save your reading progress',
                    somaliText: 'Kaydi horumarka akhriskaaga',
                  )),
                  value: readingHistory,
                  onChanged: (value) {
                    setState(() {
                      readingHistory = value;
                    });
                  },
                  activeColor: const Color(0xFF0466c8),
                ),
                SwitchListTile(
                  title: Text(LocalizationService.getLocalizedText(
                    englishText: 'Personalized Ads',
                    somaliText: 'Xayeysiiska Gaarka',
                  )),
                  subtitle: Text(LocalizationService.getLocalizedText(
                    englishText: 'Show personalized advertisements',
                    somaliText: 'Muuji xayeysiisyo gaarka',
                  )),
                  value: personalizedAds,
                  onChanged: (value) {
                    setState(() {
                      personalizedAds = value;
                    });
                  },
                  activeColor: const Color(0xFF0466c8),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                LocalizationService.getCancelText,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessMessage(LocalizationService.getLocalizedText(
                  englishText: 'Privacy settings updated!',
                  somaliText: 'Dejinta sirta ayaa la cusboonaysiiyay!',
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(LocalizationService.getLocalizedText(
                englishText: 'Save',
                somaliText: 'Kaydi',
              )),
            ),
          ],
        ),
      ),
    );
  }

  void _showDataStorageDialog(AuthState authState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0466c8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storage_rounded,
                color: Color(0xFF0466c8),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'Data & Storage',
                somaliText: 'Xogta & Kaydinta',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'Clear all cached data to free up storage space. This will not affect your account or downloaded books.',
                somaliText: 'Nadiif dhammaan xogta cache si aad u furto meel kaydinta. Tani ma saamayn doonto akoonkaaga ama kutubta la soo dejiyay.',
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0466c8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF0466c8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      LocalizationService.getLocalizedText(
                        englishText: 'This action cannot be undone',
                        somaliText: 'Ficilkan lama soo celin karo',
                      ),
                      style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              LocalizationService.getCancelText,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (authState is Authenticated) {
                context.read<SettingsBloc>().add(ClearCache(authState.user.id));
                Navigator.of(context).pop();
                _showSuccessMessage(LocalizationService.getLocalizedText(
                  englishText: 'Cache cleared successfully!',
                  somaliText: 'Cache si guul leh ayaa loo nadiifiyay!',
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0466c8),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'Clear Cache',
              somaliText: 'Nadiif Cache',
            )),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0466c8).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0466c8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0466c8),
            size: 24,
          ),
        ),
        title: Text(
          title,
            style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0466c8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.help_rounded,
                color: Color(0xFF0466c8),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getHelpText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                'How to add books to library?',
                'How to add books to library?',
                'Click the heart icon on any book card to add it to your favorites.',
              ),
              _buildHelpItem(
                'How to change language?',
                'How to change language?',
                'Go to Settings > Preferences > Language and select your preferred language.',
              ),
              _buildHelpItem(
                'How to download books?',
                'How to download books?',
                'Enable auto-download in Settings > Preferences > Auto Download.',
              ),
              _buildHelpItem(
                'How to change password?',
                'How to change password?',
                'Go to Settings > Account > Change Password and follow the instructions.',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0466c8),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'Close',
              somaliText: 'Xidh',
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String titleSo, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0466c8).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0466c8).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();
    int selectedRating = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0466c8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.feedback_rounded,
                  color: Color(0xFF0466c8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Send Feedback',
                  somaliText: 'Dir Feedback',
                ),
                style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LocalizationService.getLocalizedText(
                    englishText: 'How would you rate your experience?',
                    somaliText: 'Sidee u qiimeysaa khibradaada?',
                  ),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedRating = index + 1;
                        });
                      },
                      child: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: const Color(0xFF0466c8),
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: LocalizationService.getLocalizedText(
                      englishText: 'Your feedback',
                      somaliText: 'Feedback-kaaga',
                    ),
                    hintText: LocalizationService.getLocalizedText(
                      englishText: 'Tell us what you think...',
                      somaliText: 'Nagu sheeg waxaad u malaynaysid...',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0466c8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                LocalizationService.getCancelText,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessMessage(LocalizationService.getLocalizedText(
                  englishText: 'Thank you for your feedback!',
                  somaliText: 'Mahadsanid feedback-kaaga!',
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(LocalizationService.getLocalizedText(
                englishText: 'Send',
                somaliText: 'Dir',
              )),
            ),
          ],
        ),
      ),
    );
  }

  void _showBugReportDialog() {
    final TextEditingController bugController = TextEditingController();
    String selectedCategory = 'General';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bug_report_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Report Bug',
                  somaliText: 'Sheeg Khalad',
                ),
                style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: LocalizationService.getLocalizedText(
                      englishText: 'Category',
                      somaliText: 'Qaybta',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0466c8)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'General',
                      child: Text(LocalizationService.getLocalizedText(
                        englishText: 'General',
                        somaliText: 'Guud',
                      )),
                    ),
                    DropdownMenuItem(
                      value: 'Performance',
                      child: Text(LocalizationService.getLocalizedText(
                        englishText: 'Performance',
                        somaliText: 'Waxqabadka',
                      )),
                    ),
                    DropdownMenuItem(
                      value: 'UI/UX',
                      child: Text(LocalizationService.getLocalizedText(
                        englishText: 'UI/UX',
                        somaliText: 'UI/UX',
                      )),
                    ),
                    DropdownMenuItem(
                      value: 'Crash',
                      child: Text(LocalizationService.getLocalizedText(
                        englishText: 'App Crash',
                        somaliText: 'App-ka Dhacay',
                      )),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bugController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: LocalizationService.getLocalizedText(
                      englishText: 'Describe the issue',
                      somaliText: 'Sharax dhibaatooyinka',
                    ),
                    hintText: LocalizationService.getLocalizedText(
                      englishText: 'What happened? What did you expect?',
                      somaliText: 'Maxaa dhacay? Maxaad filayay?',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0466c8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                LocalizationService.getCancelText,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessMessage(LocalizationService.getLocalizedText(
                  englishText: 'Bug report submitted!',
                  somaliText: 'Warbixinta khaladka ayaa la gudbiyay!',
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(LocalizationService.getLocalizedText(
                englishText: 'Submit',
                somaliText: 'Gudbi',
              )),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0466c8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.contact_support_rounded,
                color: Color(0xFF0466c8),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'Contact Support',
                somaliText: 'La Xidhiidh Taageero',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContactItem(
              Icons.email_rounded,
              'Email',
              'support@teekoob.com',
              () => _showSuccessMessage('Email app opened!'),
            ),
            _buildContactItem(
              Icons.phone_rounded,
              'Phone',
              '+1 (555) 123-4567',
              () => _showSuccessMessage('Phone app opened!'),
            ),
            _buildContactItem(
              Icons.chat_rounded,
              'Live Chat',
              'Available 24/7',
              () => _showSuccessMessage('Opening live chat...'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0466c8),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'Close',
              somaliText: 'Xidh',
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0466c8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0466c8),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showRateAppDialog() {
    int selectedRating = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0466c8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFF0466c8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Rate App',
                  somaliText: 'Qiimee Appka',
                ),
                style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'How would you rate Teekoob?',
                  somaliText: 'Sidee u qiimeysaa Teekoob?',
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedRating = index + 1;
                      });
                    },
                    child: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: const Color(0xFF0466c8),
                      size: 40,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              if (selectedRating >= 4)
                Text(
                  LocalizationService.getLocalizedText(
                    englishText: 'Thank you! Would you like to rate us on the app store?',
                    somaliText: 'Mahadsanid! Ma doonaysaa inaad noo qiimeyso app store-ka?',
                  ),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                LocalizationService.getCancelText,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
            if (selectedRating >= 4)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSuccessMessage(LocalizationService.getLocalizedText(
                    englishText: 'Opening app store...',
                    somaliText: 'Furanaya app store...',
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(LocalizationService.getLocalizedText(
                  englishText: 'Rate Now',
                  somaliText: 'Qiimee Hadda',
                )),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0466c8).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0466c8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0466c8),
            size: 24,
          ),
        ),
        title: Text(
          title,
            style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showVersionInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0466c8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_rounded,
                color: Color(0xFF0466c8),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'App Version',
                somaliText: 'Nooca Appka',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0466c8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Teekoob',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Build 100',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your digital library companion',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0466c8),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'Close',
              somaliText: 'Xidh',
            )),
          ),
        ],
      ),
    );
  }

  void _showTermsOfServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0466c8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: Color(0xFF0466c8),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'Terms of Service',
                somaliText: 'Shuruudaha Adeegga',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTermsSection(
                '1. Acceptance of Terms',
                'By using Teekoob, you agree to be bound by these terms and conditions.',
              ),
              _buildTermsSection(
                '2. Use License',
                'Permission is granted to temporarily download one copy of Teekoob for personal, non-commercial transitory viewing only.',
              ),
              _buildTermsSection(
                '3. Disclaimer',
                'The materials on Teekoob are provided on an "as is" basis. Teekoob makes no warranties, expressed or implied.',
              ),
              _buildTermsSection(
                '4. Limitations',
                'In no event shall Teekoob or its suppliers be liable for any damages arising out of the use or inability to use the materials on Teekoob.',
              ),
              _buildTermsSection(
                '5. Privacy',
                'Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the app.',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0466c8),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'Close',
              somaliText: 'Xidh',
            )),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0466c8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.privacy_tip_rounded,
                color: Color(0xFF0466c8),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'Privacy Policy',
                somaliText: 'Siyaasadda Sirta',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTermsSection(
                'Information We Collect',
                'We collect information you provide directly to us, such as when you create an account, use our services, or contact us.',
              ),
              _buildTermsSection(
                'How We Use Information',
                'We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you.',
              ),
              _buildTermsSection(
                'Information Sharing',
                'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent.',
              ),
              _buildTermsSection(
                'Data Security',
                'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
              ),
              _buildTermsSection(
                'Your Rights',
                'You have the right to access, update, or delete your personal information. You can do this through your account settings.',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0466c8),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'Close',
              somaliText: 'Xidh',
            )),
          ),
        ],
      ),
    );
  }

  void _showOpenSourceLicensesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0466c8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.open_in_new_rounded,
                color: Color(0xFF0466c8),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'Open Source Licenses',
                somaliText: 'Layisinka Open Source',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLicenseItem('Flutter', 'BSD 3-Clause License'),
              _buildLicenseItem('Dart', 'BSD 3-Clause License'),
              _buildLicenseItem('Hive', 'Apache License 2.0'),
              _buildLicenseItem('Dio', 'MIT License'),
              _buildLicenseItem('Equatable', 'MIT License'),
              _buildLicenseItem('Bloc', 'MIT License'),
              _buildLicenseItem('Go Router', 'BSD 3-Clause License'),
              _buildLicenseItem('Shared Preferences', 'BSD 3-Clause License'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0466c8),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'Close',
              somaliText: 'Xidh',
            )),
          ),
        ],
      ),
    );
  }

  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0466c8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.apps_rounded,
                color: Color(0xFF0466c8),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'App Information',
                somaliText: 'Macluumaadka Appka',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoItem('Developer', 'Teekoob Team'),
            _buildInfoItem('Company', 'Teekoob Technologies'),
            _buildInfoItem('Website', 'www.teekoob.com'),
            _buildInfoItem('Email', 'info@teekoob.com'),
            _buildInfoItem('Support', 'support@teekoob.com'),
            _buildInfoItem('Platform', 'Flutter'),
            _buildInfoItem('Target', 'Mobile & Web'),
            _buildInfoItem('Release Date', '2024'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0466c8),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'Close',
              somaliText: 'Xidh',
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseItem(String library, String license) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0466c8).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF0466c8).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            library,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            license,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF0466c8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthState authState) {
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();

    if (authState is Authenticated) {
      firstNameController.text = authState.user.firstName ?? '';
      lastNameController.text = authState.user.lastName ?? '';
      emailController.text = authState.user.email ?? '';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0466c8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Color(0xFF0466c8),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'Edit Profile',
                somaliText: 'Wax Ka Badal Profile',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: LocalizationService.getLocalizedText(
                    englishText: 'First Name',
                    somaliText: 'Magaca Hore',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0466c8)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: LocalizationService.getLocalizedText(
                    englishText: 'Last Name',
                    somaliText: 'Magaca Dambe',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0466c8)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: LocalizationService.getLocalizedText(
                    englishText: 'Email',
                    somaliText: 'Email',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0466c8)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              LocalizationService.getCancelText,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (authState is Authenticated) {
                context.read<AuthBloc>().add(UpdateProfileRequested(
                  displayName: '${firstNameController.text} ${lastNameController.text}',
                  language: authState.user.preferredLanguage,
                  themePreference: authState.user.preferences['theme'] ?? 'system',
                ));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LocalizationService.getLocalizedText(
                      englishText: 'Profile updated successfully!',
                      somaliText: 'Profile si guul leh ayaa loo cusboonaysiiyay!',
                    )),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0466c8),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'Save',
              somaliText: 'Kaydi',
            )),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
          englishText: 'Logout',
          somaliText: 'Ka Bax',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          LocalizationService.getLocalizedText(
          englishText: 'Are you sure you want to logout?',
          somaliText: 'Ma hubtaa inaad ka baxdo?',
          ),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              LocalizationService.getCancelText,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(const LogoutRequested());
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(LocalizationService.getLogoutText),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String? avatarUrl) {
    print('🖼️ _buildProfileAvatar called with URL: $avatarUrl');
    print('🖼️ URL type: ${avatarUrl.runtimeType}');
    print('🖼️ URL is null: ${avatarUrl == null}');
    return CircleAvatar(
      radius: 30,
      backgroundColor: const Color(0xFF0466c8),
      child: avatarUrl != null
          ? ClipOval(
              child: Image.network(
                avatarUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                headers: {
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                  'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                  'Cache-Control': 'no-cache',
                  'Referer': 'https://teekoob-production.up.railway.app/',
                },
                // Add frameBuilder to handle loading states better
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    child: child,
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('🖼️ Profile avatar error: $error');
                  print('🖼️ Avatar URL: $avatarUrl');
                  
                  // Check if it's a 429 (rate limit) error
                  if (error.toString().contains('429') || error.toString().contains('Too Many Requests')) {
                    print('🖼️ Google CDN rate limit detected - showing fallback');
                  }
                  
                  // Check if it's a CORS/network error (statusCode: 0)
                  if (error.toString().contains('statusCode: 0')) {
                    print('🖼️ CORS/Network error detected - trying alternative approach');
                    // Try to modify the URL to bypass some restrictions
                    if (avatarUrl != null && avatarUrl.contains('googleusercontent.com')) {
                      final modifiedUrl = avatarUrl.replaceAll('=s96-c', '=s200-c');
                      print('🖼️ Trying modified URL: $modifiedUrl');
                      return Image.network(
                        modifiedUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error2, stackTrace2) {
                          print('🖼️ Modified URL also failed: $error2');
                          return Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.surface,
                            size: 35,
                          );
                        },
                      );
                    }
                  }
                  
                  // Fallback to icon if image fails to load
                  return Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.surface,
                    size: 35,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: 60,
                    height: 60,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.surface,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              ),
            )
          : Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.surface,
              size: 35,
            ),
    );
  }
}

