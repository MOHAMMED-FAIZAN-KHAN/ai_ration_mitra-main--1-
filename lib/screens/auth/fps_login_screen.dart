import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import 'otp_verification_screen.dart';
import '../../models/user.dart';

class FPSLoginScreen extends StatefulWidget {
  const FPSLoginScreen({super.key});

  @override
  State<FPSLoginScreen> createState() => _FPSLoginScreenState();
}

class _FPSLoginScreenState extends State<FPSLoginScreen> {
  final _fpsIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fpsIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('fps_login'))),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.saffron.withValues(alpha: 0.16),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.saffron.withValues(alpha: 0.28)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storefront, color: AppColors.saffron),
                        SizedBox(width: 8),
                        Text(
                          'Authorized Dealer Login',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Secure access for FPS operations, distribution control and stock workflows.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'Govt. Verified Dealer Authentication',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fpsIdController,
                        decoration: const InputDecoration(
                          labelText: 'FPS Shop ID',
                          hintText: 'e.g., FPS-2736',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Access Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.saffron,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            _loginWithPassword(context);
                          },
                          icon: const Icon(Icons.verified_user_outlined),
                          label: Text(
                            '${loc.translate('login').toUpperCase()} • PASSWORD',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("New shop onboarding? "),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/fps-register'),
                    child: Text(loc.translate('register_now')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildLanguageSelector(context, loc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, AppLocalizations loc) {
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
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.8),
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

  Future<void> _loginWithPassword(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final fpsId = _fpsIdController.text.trim();
    final password = _passwordController.text;
    if (fpsId.isEmpty || password.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.translate('enter_password')} / FPS ID required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(fpsId, password, UserType.fpsDealer);
    if (!mounted) {
      return;
    }
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OTPVerificationScreen(
          identifier: fpsId,
          userType: UserType.fpsDealer,
          isSecondFactor: true,
        ),
      ),
    );
  }
}
