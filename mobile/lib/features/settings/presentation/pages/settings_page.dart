import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/services/localization_service.dart';
import 'package:teekoob/features/auth/bloc/auth_bloc.dart';
import 'package:teekoob/features/settings/bloc/settings_bloc.dart';
import 'package:teekoob/core/bloc/theme_bloc.dart';
import 'package:teekoob/core/config/app_theme.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          LocalizationService.getSettingsText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFF56C23),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
    );
  }

  Widget _buildProfileSection() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String userName = 'Guest User';
        String userEmail = 'guest@example.com';
        String? avatarUrl;

        if (authState is Authenticated) {
          userName = '${authState.user.firstName ?? ''} ${authState.user.lastName ?? ''}'.trim();
          if (userName.isEmpty) userName = authState.user.email ?? 'User';
          userEmail = authState.user.email ?? 'user@example.com';
          avatarUrl = authState.user.profilePicture;
        }

    return _buildSection(
      title: LocalizationService.getProfileText,
      children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF56C23).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFF56C23),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? const Icon(
              Icons.person,
              color: Colors.white,
                          size: 35,
                        )
                      : null,
          ),
          title: Text(
                  userName,
                  style: const TextStyle(
              fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: AppTheme.textPrimaryColor,
            ),
          ),
          subtitle: Text(
                  userEmail,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF56C23).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFFF56C23),
                    ),
            onPressed: () {
                      _showEditProfileDialog(context, authState);
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
            // Get current settings
            String currentLanguage = 'en';
            String currentTheme = 'system';
            bool notificationsEnabled = true;
            bool autoDownloadEnabled = false;

            if (authState is Authenticated) {
              currentLanguage = authState.user.preferredLanguage;
              currentTheme = authState.user.preferences['theme'] ?? 'system';
            }

            if (settingsState is SettingsLoaded) {
              currentLanguage = settingsState.settings['language'] ?? currentLanguage;
              currentTheme = settingsState.settings['theme'] ?? currentTheme;
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
                  trailing: _buildThemeDropdown(currentTheme, authState),
        ),
        
        // Notifications Setting
                _buildPreferenceCard(
                  icon: Icons.notifications_rounded,
                  title: LocalizationService.getNotificationsText,
                  subtitle: LocalizationService.getLocalizedText(
              englishText: 'Receive push notifications',
              somaliText: 'Hel ogeysiisyo',
            ),
                  trailing: Switch(
                    value: notificationsEnabled,
                    onChanged: (value) => _updateNotifications(value, authState),
                    activeColor: const Color(0xFFF56C23),
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
                    activeColor: const Color(0xFFF56C23),
                  ),
                ),
              ],
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
            
            // Privacy Settings
            _buildAccountCard(
              icon: Icons.privacy_tip_rounded,
              title: LocalizationService.getLocalizedText(
            englishText: 'Privacy Settings',
            somaliText: 'Dejinta Sirta',
              ),
              subtitle: LocalizationService.getLocalizedText(
                englishText: 'Manage your privacy preferences',
                somaliText: 'Maamul doorashooyinkaaga sirta',
              ),
              onTap: () => _showPrivacySettingsDialog(authState),
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
            
            // Data & Storage
            _buildAccountCard(
              icon: Icons.storage_rounded,
              title: LocalizationService.getLocalizedText(
                englishText: 'Data & Storage',
                somaliText: 'Xogta & Kaydinta',
              ),
              subtitle: LocalizationService.getLocalizedText(
                englishText: 'Clear cache and manage storage',
                somaliText: 'Nadiif cache oo maamul kaydinta',
              ),
              onTap: () => _showDataStorageDialog(authState),
            ),
            
            // Logout
            _buildAccountCard(
              icon: Icons.logout_rounded,
              title: LocalizationService.getLogoutText,
              subtitle: LocalizationService.getLocalizedText(
                englishText: 'Sign out of your account',
                somaliText: 'Ka bax akoonkaaga',
              ),
              isDestructive: true,
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
        // Help & FAQ
        _buildSupportCard(
          icon: Icons.help_rounded,
          title: LocalizationService.getHelpText,
          subtitle: LocalizationService.getLocalizedText(
            englishText: 'Get help and find answers',
            somaliText: 'Hel taageero oo hel jawaabaha',
          ),
          onTap: () => _showHelpDialog(),
        ),
        
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
        
        // Terms of Service
        _buildAboutCard(
          icon: Icons.description_rounded,
          title: LocalizationService.getLocalizedText(
            englishText: 'Terms of Service',
            somaliText: 'Shuruudaha Adeegga',
          ),
          subtitle: LocalizationService.getLocalizedText(
            englishText: 'Read our terms and conditions',
            somaliText: 'Akhri shuruudaha iyo xaaladaha',
          ),
          onTap: () => _showTermsOfServiceDialog(),
        ),
        
        // Privacy Policy
        _buildAboutCard(
          icon: Icons.privacy_tip_rounded,
          title: LocalizationService.getLocalizedText(
            englishText: 'Privacy Policy',
            somaliText: 'Siyaasadda Sirta',
          ),
          subtitle: LocalizationService.getLocalizedText(
            englishText: 'How we protect your data',
            somaliText: 'Sidee aan ilaalino xogtaaga',
          ),
          onTap: () => _showPrivacyPolicyDialog(),
        ),
        
        // Open Source Licenses
        _buildAboutCard(
          icon: Icons.open_in_new_rounded,
          title: LocalizationService.getLocalizedText(
            englishText: 'Open Source Licenses',
            somaliText: 'Layisinka Open Source',
          ),
          subtitle: LocalizationService.getLocalizedText(
            englishText: 'Third-party libraries and licenses',
            somaliText: 'Maktabado kale iyo layisinka',
          ),
          onTap: () => _showOpenSourceLicensesDialog(),
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
              color: AppTheme.primaryColor,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF56C23).withOpacity(0.1),
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
            color: const Color(0xFFF56C23).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFF56C23),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
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
        color: const Color(0xFFF56C23).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF56C23).withOpacity(0.3),
        ),
      ),
      child: DropdownButton<String>(
        value: currentLanguage,
        underline: Container(),
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFF56C23)),
        dropdownColor: AppTheme.cardColor,
        items: [
          DropdownMenuItem(
            value: 'en',
            child: Text(
              'English',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          DropdownMenuItem(
            value: 'so',
            child: Text(
              'Soomaali',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
        onChanged: (value) => _updateLanguage(value!, authState),
      ),
    );
  }

  Widget _buildThemeDropdown(String currentTheme, AuthState authState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF56C23).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF56C23).withOpacity(0.3),
        ),
      ),
      child: DropdownButton<String>(
        value: currentTheme,
        underline: Container(),
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFF56C23)),
        dropdownColor: AppTheme.cardColor,
        items: [
          DropdownMenuItem(
            value: 'system',
            child: Text(
              LocalizationService.getLocalizedText(
                englishText: 'System',
                somaliText: 'Nidaamka',
              ),
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          DropdownMenuItem(
            value: 'light',
            child: Text(
              LocalizationService.getLocalizedText(
                englishText: 'Light',
                somaliText: 'Iftiin',
              ),
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          DropdownMenuItem(
            value: 'dark',
            child: Text(
              LocalizationService.getLocalizedText(
                englishText: 'Dark',
                somaliText: 'Madow',
              ),
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
        onChanged: (value) => _updateTheme(value!, authState),
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

  void _updateLanguage(String language, AuthState authState) {
    if (authState is Authenticated) {
      context.read<SettingsBloc>().add(UpdateLanguage(authState.user.id, language));
      context.read<AuthBloc>().add(UpdateProfileRequested(
        language: language,
      ));
      _showSuccessMessage(LocalizationService.getLocalizedText(
        englishText: 'Language updated successfully!',
        somaliText: 'Luqadda si guul leh ayaa loo cusboonaysiiyay!',
      ));
    }
  }

  void _updateTheme(String theme, AuthState authState) {
    if (authState is Authenticated) {
      // Update the theme immediately using ThemeBloc
      context.read<ThemeBloc>().add(ChangeTheme(theme));
      
      // Also save to settings for persistence
      context.read<SettingsBloc>().add(UpdateTheme(authState.user.id, theme));
      context.read<AuthBloc>().add(UpdateProfileRequested(
        themePreference: theme,
      ));
      _showSuccessMessage(LocalizationService.getLocalizedText(
        englishText: 'Theme updated successfully!',
        somaliText: 'Mawduuca si guul leh ayaa loo cusboonaysiiyay!',
      ));
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF56C23).withOpacity(0.1),
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
                ? Colors.red.withOpacity(0.1)
                : const Color(0xFFF56C23).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : const Color(0xFFF56C23),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDestructive ? Colors.red : AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: isDestructive ? Colors.red : AppTheme.textPrimaryColor,
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
                  color: const Color(0xFFF56C23).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: Color(0xFFF56C23),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Change Password',
                  somaliText: 'Beddel Furaha',
                ),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
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
                      borderSide: const BorderSide(color: Color(0xFFF56C23)),
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
                      borderSide: const BorderSide(color: Color(0xFFF56C23)),
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
                      borderSide: const BorderSide(color: Color(0xFFF56C23)),
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
                style: const TextStyle(color: Colors.grey),
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
                backgroundColor: const Color(0xFFF56C23),
                foregroundColor: Colors.white,
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
                  color: const Color(0xFFF56C23).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.privacy_tip_rounded,
                  color: Color(0xFFF56C23),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Privacy Settings',
                  somaliText: 'Dejinta Sirta',
                ),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
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
                  activeColor: const Color(0xFFF56C23),
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
                  activeColor: const Color(0xFFF56C23),
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
                  activeColor: const Color(0xFFF56C23),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                LocalizationService.getCancelText,
                style: const TextStyle(color: Colors.grey),
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
                backgroundColor: const Color(0xFFF56C23),
                foregroundColor: Colors.white,
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
                color: const Color(0xFFF56C23).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storage_rounded,
                color: Color(0xFFF56C23),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'Data & Storage',
                somaliText: 'Xogta & Kaydinta',
              ),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
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
              style: TextStyle(color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF56C23).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFF56C23),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      LocalizationService.getLocalizedText(
                        englishText: 'This action cannot be undone',
                        somaliText: 'Ficilkan lama soo celin karo',
                      ),
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
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
              style: const TextStyle(color: Colors.grey),
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
              backgroundColor: const Color(0xFFF56C23),
              foregroundColor: Colors.white,
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
        backgroundColor: Colors.red,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF56C23).withOpacity(0.1),
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
            color: const Color(0xFFF56C23).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFF56C23),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
                  color: AppTheme.textPrimaryColor,
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
                color: const Color(0xFFF56C23).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.help_rounded,
                color: Color(0xFFF56C23),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getHelpText,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
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
              backgroundColor: const Color(0xFFF56C23),
              foregroundColor: Colors.white,
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
        color: const Color(0xFFF56C23).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF56C23).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
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
                  color: const Color(0xFFF56C23).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.feedback_rounded,
                  color: Color(0xFFF56C23),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Send Feedback',
                  somaliText: 'Dir Feedback',
                ),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
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
                  style: TextStyle(color: AppTheme.textPrimaryColor),
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
                        color: const Color(0xFFF56C23),
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
                      borderSide: const BorderSide(color: Color(0xFFF56C23)),
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
                style: const TextStyle(color: Colors.grey),
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
                backgroundColor: const Color(0xFFF56C23),
                foregroundColor: Colors.white,
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bug_report_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Report Bug',
                  somaliText: 'Sheeg Khalad',
                ),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
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
                      borderSide: const BorderSide(color: Color(0xFFF56C23)),
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
                      borderSide: const BorderSide(color: Color(0xFFF56C23)),
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
                style: const TextStyle(color: Colors.grey),
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
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
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
                color: const Color(0xFFF56C23).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.contact_support_rounded,
                color: Color(0xFFF56C23),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'Contact Support',
                somaliText: 'La Xidhiidh Taageero',
              ),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
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
              backgroundColor: const Color(0xFFF56C23),
              foregroundColor: Colors.white,
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
            color: const Color(0xFFF56C23).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFF56C23),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
                  color: AppTheme.textPrimaryColor,
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
                  color: const Color(0xFFF56C23).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF56C23),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocalizationService.getLocalizedText(
                  englishText: 'Rate App',
                  somaliText: 'Qiimee Appka',
                ),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
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
                style: TextStyle(color: AppTheme.textPrimaryColor),
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
                      color: const Color(0xFFF56C23),
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
                  style: TextStyle(color: AppTheme.textPrimaryColor),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                LocalizationService.getCancelText,
                style: const TextStyle(color: Colors.grey),
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
                  backgroundColor: const Color(0xFFF56C23),
                  foregroundColor: Colors.white,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF56C23).withOpacity(0.1),
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
            color: const Color(0xFFF56C23).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFF56C23),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
                  color: AppTheme.textPrimaryColor,
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
                color: const Color(0xFFF56C23).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_rounded,
                color: Color(0xFFF56C23),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'App Version',
                somaliText: 'Nooca Appka',
              ),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
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
                color: const Color(0xFFF56C23).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Teekoob',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF56C23),
                    ),
                  ),
                  const Text(
                    'Build 100',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your digital library companion',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
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
              backgroundColor: const Color(0xFFF56C23),
              foregroundColor: Colors.white,
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
                color: const Color(0xFFF56C23).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: Color(0xFFF56C23),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'Terms of Service',
                somaliText: 'Shuruudaha Adeegga',
              ),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
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
              backgroundColor: const Color(0xFFF56C23),
              foregroundColor: Colors.white,
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
                color: const Color(0xFFF56C23).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.privacy_tip_rounded,
                color: Color(0xFFF56C23),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'Privacy Policy',
                somaliText: 'Siyaasadda Sirta',
              ),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
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
              backgroundColor: const Color(0xFFF56C23),
              foregroundColor: Colors.white,
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
                color: const Color(0xFFF56C23).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.open_in_new_rounded,
                color: Color(0xFFF56C23),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'Open Source Licenses',
                somaliText: 'Layisinka Open Source',
              ),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
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
              backgroundColor: const Color(0xFFF56C23),
              foregroundColor: Colors.white,
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
                color: const Color(0xFFF56C23).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.apps_rounded,
                color: Color(0xFFF56C23),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'App Information',
                somaliText: 'Macluumaadka Appka',
              ),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
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
              backgroundColor: const Color(0xFFF56C23),
              foregroundColor: Colors.white,
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
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
        color: const Color(0xFFF56C23).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFF56C23).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            library,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          Text(
            license,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
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
        backgroundColor: const Color(0xFFF56C23),
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
                color: const Color(0xFFF56C23).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Color(0xFFF56C23),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
                englishText: 'Edit Profile',
                somaliText: 'Wax Ka Badal Profile',
              ),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
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
                    borderSide: const BorderSide(color: Color(0xFFF56C23)),
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
                    borderSide: const BorderSide(color: Color(0xFFF56C23)),
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
                    borderSide: const BorderSide(color: Color(0xFFF56C23)),
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
              style: const TextStyle(color: Colors.grey),
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
                    backgroundColor: const Color(0xFFF56C23),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF56C23),
              foregroundColor: Colors.white,
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocalizationService.getLocalizedText(
          englishText: 'Logout',
          somaliText: 'Ka Bax',
              ),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
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
                  style: TextStyle(color: AppTheme.textPrimaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              LocalizationService.getCancelText,
              style: const TextStyle(color: Colors.grey),
            ),
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
}

