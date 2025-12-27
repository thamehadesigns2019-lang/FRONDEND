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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.lightBg,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<AppState>(
            builder: (context, appState, child) {
              UserSettings settings = appState.userSettings;

              return Column(
                children: [
                  // Header with profile
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Profile avatar
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 40,
                                color: Colors.white,
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
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    appState.isAuthenticated ? 'Manage your account' : 'Sign in to access all features',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                               gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                               borderRadius: BorderRadius.circular(16),
                            ),
                            child: Material(
                               color: Colors.transparent,
                               child: InkWell(
                                   onTap: () => Navigator.pushNamed(context, '/login'),
                                   borderRadius: BorderRadius.circular(16),
                                   child: const Padding(
                                       padding: EdgeInsets.all(20),
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00b09b), Color(0xFF96c93d)],
                          ),
                          onTap: () => _handleContactsSync(context),
                        ),
                        _buildSettingCard(
                          icon: Icons.storage_outlined,
                          title: 'Storage Management',
                          subtitle: 'Clean cache and manage downloads',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFff9966), Color(0xFFff5e62)],
                          ),
                          onTap: () => _handleStorageManagement(context),
                        ),
                        
                        // Preferences section
                        const SizedBox(height: 24),
                        _buildSectionHeader('Preferences'),
                        _buildSwitchCard(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'Receive updates and offers',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                          ),
                          value: settings.enableNotifications,
                          onChanged: (value) {
                            appState.updateUserSettings(
                              UserSettings(
                                enableNotifications: value,
                                darkMode: settings.darkMode,
                                preferredCurrency: settings.preferredCurrency,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildSwitchCard(
                          icon: Icons.dark_mode_outlined,
                          title: 'Dark Mode',
                          subtitle: 'Switch to dark theme',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF434343), Color(0xFF000000)],
                          ),
                          value: settings.darkMode,
                          onChanged: (value) {
                            appState.updateUserSettings(
                              UserSettings(
                                enableNotifications: settings.enableNotifications,
                                darkMode: value,
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                          ),
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D9FF), Color(0xFF6C63FF)],
                          ),
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
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.errorRed.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
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
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.errorRed.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.logout_rounded,
                                          color: AppTheme.errorRed,
                                          size: 20,
                                        ),
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
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
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
    required Gradient gradient,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB75E), Color(0xFFED8F03)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.attach_money_rounded,
                color: Colors.white,
                size: 24,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Auto-detected based on location',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                   const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                   const SizedBox(width: 6),
                   Text(
                    settings.preferredCurrency,
                    style: const TextStyle(
                      fontSize: 14,
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
