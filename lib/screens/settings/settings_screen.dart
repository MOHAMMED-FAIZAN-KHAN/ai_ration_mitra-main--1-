import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart'; // <-- IMPORT ADDED for UserType

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final loc = AppLocalizations.of(context);

    final languageNames = {
      'en': 'English',
      'hi': 'हिंदी',
      'mr': 'मराठी',
    };

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('settings')), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(loc.translate('appearance'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: Text(loc.translate('dark_mode')),
              subtitle: Text(loc.translate('switch_theme')),
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (value) => themeProvider.toggleTheme(value),
              secondary: const Icon(Icons.dark_mode),
            ),
          ),
          const SizedBox(height: 20),
          Text(loc.translate('language'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(loc.translate('select_language')),
              subtitle: Text(
                  languageNames[settingsProvider.locale.languageCode] ??
                      'English'),
              trailing: DropdownButton<String>(
                value: settingsProvider.locale.languageCode,
                items: [
                  DropdownMenuItem(
                      value: 'en', child: Text(languageNames['en']!)),
                  DropdownMenuItem(
                      value: 'hi', child: Text(languageNames['hi']!)),
                  DropdownMenuItem(
                      value: 'mr', child: Text(languageNames['mr']!)),
                ],
                onChanged: (value) {
                  if (value != null) settingsProvider.setLanguage(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(loc.translate('notifications'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: Text(loc.translate('enable_notifications')),
              subtitle: Text(loc.translate('receive_updates')),
              value: settingsProvider.notificationsEnabled,
              onChanged: (value) => settingsProvider.toggleNotifications(value),
              secondary: const Icon(Icons.notifications),
            ),
          ),
          const SizedBox(height: 20),
          Text(loc.translate('account'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(loc.translate('edit_profile')),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    if (authProvider.currentUser != null) {
                      switch (authProvider.currentUser!.type) {
                        case UserType.citizen:
                          Navigator.pushNamed(context, '/citizen/edit-profile');
                          break;
                        case UserType.fpsDealer:
                          Navigator.pushNamed(context, '/fps/edit-profile');
                          break;
                        case UserType.admin:
                          Navigator.pushNamed(context, '/admin/edit-profile');
                          break;
                      }
                    }
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(loc.translate('logout'),
                      style: const TextStyle(color: Colors.red)),
                  onTap: () async {
                    // Capture navigator before async gap
                    final navigator = Navigator.of(context);
                    await authProvider.logout();
                    if (context.mounted) {
                      navigator.pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
