import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import 'otp_verification_screen.dart';
import '../../models/user.dart';
import '../../providers/settings_provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _adminIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _adminIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('admin_login')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16), // 🔹 Consistent outer padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 HEADER CARD (Professional Notice)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: theme.colorScheme.primary,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restricted Administration Portal',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Use authorized credentials only. All actions are logged for compliance.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// 🔹 PRIVILEGE BADGE (Theme Based)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'HIGH PRIVILEGE ACCESS',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 18),

            /// 🔹 LOGIN FORM CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    /// Admin ID Field
                    TextFormField(
                      controller: _adminIdController,
                      decoration: const InputDecoration(
                        labelText: 'Admin ID',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: loc.translate('password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Login Button (Uses Global Theme)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleLogin,
                        icon: const Icon(Icons.security_outlined),
                        label: Text(
                          '${loc.translate('login').toUpperCase()} • PASSWORD',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            /// 🔹 Security Notice
            Text(
              'For security, OTP verification is mandatory for every login.',
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 20),

            /// 🔹 Language Selector
            _buildLanguageSelector(context, loc),
          ],
        ),
      ),
    );
  }

  // =====================================
  // 🔐 Login Logic (Separated Cleanly)
  // =====================================
  void _handleLogin() {
    final loc = AppLocalizations.of(context);

    if (_adminIdController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      _loginWithPassword();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('enter_credentials')),
        ),
      );
    }
  }

  Future<void> _loginWithPassword() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      _adminIdController.text.trim(),
      _passwordController.text,
      UserType.admin,
    );
    if (!mounted) {
      return;
    }
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OTPVerificationScreen(
          identifier: _adminIdController.text.trim(),
          userType: UserType.admin,
          isSecondFactor: true,
        ),
      ),
    );
  }

  // =====================================
  // 🌍 Language Selector (Improved)
  // =====================================
  Widget _buildLanguageSelector(
      BuildContext context, AppLocalizations loc) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'hi', 'name': 'हिंदी'},
      {'code': 'mr', 'name': 'मराठी'},
    ];
    final selectedCode = settingsProvider.locale.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.language, color: theme.colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              loc.translate('select_language'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Text(
            '${loc.translate('language')}: ${_languageName(selectedCode)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: languages.map((lang) {
            final code = lang['code']!;
            final isSelected = selectedCode == code;

            return ChoiceChip(
              label: Text(lang['name']!),
              selected: isSelected,
              showCheckmark: false,
              avatar: isSelected
                  ? Icon(Icons.check_circle,
                      color: theme.colorScheme.primary, size: 16)
                  : null,
              selectedColor:
                  theme.colorScheme.primary.withValues(alpha: 0.16),
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
              ),
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              onSelected: isSelected
                  ? null
                  : (_) => _setLanguage(context, settingsProvider, code),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _setLanguage(
    BuildContext context,
    SettingsProvider settingsProvider,
    String languageCode,
  ) async {
    await settingsProvider.setLanguage(languageCode);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language changed to ${_languageName(languageCode)}'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  String _languageName(String code) {
    switch (code) {
      case 'hi':
        return 'हिंदी';
      case 'mr':
        return 'मराठी';
      default:
        return 'English';
    }
  }
}
