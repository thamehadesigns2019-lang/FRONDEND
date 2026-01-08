import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/constants.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/models/user_settings.dart';
import 'package:thameeha/theme/themes.dart';
import 'package:thameeha/screens/profile_screen.dart';
import 'package:thameeha/screens/help_support_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thameeha/utils/file_utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // simple clean background
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, appState, child) {
            UserSettings settings = appState.userSettings;

            return Column(
              children: [
                // Header with profile
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: Row(
                    children: [
                      // Profile avatar
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 32,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appState.isAuthenticated ? 'Welcome Back!' : 'Guest User',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appState.isAuthenticated ? 'Manage your account' : 'Sign in to access all features',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Settings list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (!appState.isAuthenticated) ...[
                         Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                             color: AppTheme.primaryPurple,
                             borderRadius: BorderRadius.circular(12),
                             boxShadow: [
                               BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                             ]
                          ),
                          child: Material(
                             color: Colors.transparent,
                             child: InkWell(
                                 onTap: () => Navigator.pushNamed(context, '/login'),
                                 borderRadius: BorderRadius.circular(12),
                                 child: const Padding(
                                     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                     child: Row(
                                         mainAxisAlignment: MainAxisAlignment.center,
                                         children: [
                                             Icon(Icons.login, color: Colors.white),
                                             SizedBox(width: 12),
                                             Text(
                                                 "Sign In to your account", 
                                                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                             )
                                         ]
                                     )
                                 )
                             )
                          )
                         )
                      ],

                      // Account section
                      _buildSectionHeader('Account'),
                      _buildSettingCard(
                        icon: Icons.person_outline_rounded,
                        title: 'Profile',
                        subtitle: 'Manage your profile information',
                        iconColor: AppTheme.primaryPurple,
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        },
                      ),
                      _buildSettingCard(
                        icon: Icons.contacts_outlined,
                        title: 'Sync Contacts',
                        subtitle: 'Invite friends and share products',
                        iconColor: Colors.blueAccent,
                        onTap: () => _handleContactsSync(context),
                      ),
                      _buildSettingCard(
                        icon: Icons.storage_outlined,
                        title: 'Storage Management',
                        subtitle: 'Clean cache and manage downloads',
                        iconColor: Colors.orangeAccent,
                        onTap: () => _handleStorageManagement(context),
                      ),
                      
                      // Preferences section
                      const SizedBox(height: 24),
                      _buildSectionHeader('Preferences'),
                      _buildSwitchCard(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Receive updates and offers',
                        iconColor: Colors.pinkAccent,
                        value: settings.enableNotifications,
                        onChanged: (value) {
                          appState.updateUserSettings(
                            UserSettings(
                              enableNotifications: value,
                              darkMode: false, // Default to false
                              preferredCurrency: settings.preferredCurrency,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildCurrencyCard(
                        settings: settings,
                        appState: appState,
                      ),

                      // Support section
                      const SizedBox(height: 24),
                      _buildSectionHeader('Support'),
                      _buildSettingCard(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        subtitle: 'Get help with your orders',
                        iconColor: Colors.teal,
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSettingCard(
                        icon: Icons.info_outline_rounded,
                        title: 'About App',
                        subtitle: 'Version 1.0.0',
                        iconColor: Colors.indigo,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            _buildSnackBar('Navigate to About App', Icons.info_rounded),
                          );
                        },
                      ),
                      
                      // Logout button
                      if (appState.isAuthenticated) ...[
                        const SizedBox(height: 32),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                await appState.logout();
                                Navigator.of(context).pushReplacementNamed('/login');
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.logout_rounded,
                                      color: AppTheme.errorRed,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Logout',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.errorRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
             Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryPurple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyCard({
    required UserSettings settings,
    required AppState appState,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
             Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.attach_money_rounded,
                color: Colors.amber,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Currency',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Auto-detected',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                   const Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                   const SizedBox(width: 4),
                   Text(
                    settings.preferredCurrency,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SnackBar _buildSnackBar(String message, IconData icon) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppTheme.primaryPurple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _handleContactsSync(BuildContext context) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar('Contact sync is only available on mobile devices.', Icons.info_outline),
      );
      return;
    }
    // 1. Request Permission
    final status = await Permission.contacts.request();
    
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar('Permission granted. Syncing contacts...', Icons.sync),
      );
      
      try {
        final contacts = await FastContacts.getAllContacts();
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar('Successfully synced ${contacts.length} contacts.', Icons.check_circle_rounded),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar('Error syncing: $e', Icons.error_outline),
        );
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar('Contact permission denied.', Icons.warning_rounded),
      );
    }
  }

  void _handleStorageManagement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Storage Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text("This will clear your local settings, cached images, and search history."),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      
                      // 1. Clear SharedPreferences
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      
                      // 2. Clear Temporary Directory (Cache)
                      await clearCache();

                      ScaffoldMessenger.of(context).showSnackBar(
                        _buildSnackBar('Application data cleared. Please restart.', Icons.auto_delete_rounded)
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, foregroundColor: Colors.white),
                    child: const Text("Clear All Data"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
