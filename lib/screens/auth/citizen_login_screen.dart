import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import 'otp_verification_screen.dart';
import 'citizen_register_screen.dart';
import '../../models/user.dart';

class CitizenLoginScreen extends StatefulWidget {
  const CitizenLoginScreen({super.key});

  @override
  State<CitizenLoginScreen> createState() => _CitizenLoginScreenState();
}

class _CitizenLoginScreenState extends State<CitizenLoginScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  bool _obscureAadhaar = true;
  bool _obscurePassword = true;

  final TextEditingController _aadhaarController =
      TextEditingController();
  final TextEditingController _mobileController =
      TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController();

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    /// Smooth rebuild when switching tabs
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aadhaarController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final authProvider = context.watch<AuthProvider>();
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('citizen_login')),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildHeader(context),

            const SizedBox(height: 30),

            _buildTabBar(context),

            const SizedBox(height: 30),

            /// Smooth animated switching
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _tabController.index == 0
                  ? _buildAadhaarForm(context)
                  : _buildMobileForm(context),
            ),

            const SizedBox(height: 16),
            _buildPasswordField(context),
            const SizedBox(height: 24),

            _buildLanguageSelector(context, settingsProvider),

            const SizedBox(height: 30),

            _buildLoginButton(context, authProvider),

            const SizedBox(height: 20),

            _buildFooter(),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(loc.translate('dont_have_account')),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const CitizenRegisterScreen(),
                      ),
                    );
                  },
                  child: Text(loc.translate('register_now')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.translate('secure_authentication'),
            style: const TextStyle(
                fontSize: 14,
                color: AppColors.saffron,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(loc.translate('welcome_back'),
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold)),
        Text(loc.translate('access_ration'),
            style:
                const TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );
  }

  // ================= TAB BAR =================
  Widget _buildTabBar(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.saffron,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.saffron.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[700],
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: [
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(loc.translate('aadhaar')),
            ),
          ),
          Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(loc.translate('mobile')),
            ),
          ),
        ],
      ),
    );
  }

  // ================= AADHAAR FORM =================
  Widget _buildAadhaarForm(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      key: const ValueKey("aadhaar_form"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${loc.translate('aadhaar')} Authentication',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        const Text(
          "Your Aadhaar is encrypted & secure",
          style: TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 20),

        TextFormField(
          controller: _aadhaarController,
          keyboardType: TextInputType.number,
          maxLength: 12,
          obscureText: _obscureAadhaar,
          decoration: InputDecoration(
            labelText: loc.translate('aadhaar'),
            hintText: "XXXX XXXX 1234",
            prefixIcon: const Icon(Icons.fingerprint),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureAadhaar = !_obscureAadhaar;
                });
              },
              icon: Icon(
                _obscureAadhaar ? Icons.visibility : Icons.visibility_off,
              ),
              tooltip: _obscureAadhaar ? 'Show Aadhaar' : 'Hide Aadhaar',
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // ================= MOBILE FORM =================
  Widget _buildMobileForm(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      key: const ValueKey("mobile_form"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${loc.translate('mobile')} Verification',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        const Text(
          "Use your registered mobile for secure login",
          style: TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 20),

        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: const InputDecoration(
            labelText: "Mobile Number",
            prefixIcon: Icon(Icons.phone_android),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }

  // ================= LOGIN BUTTON =================
  Widget _buildLoginButton(BuildContext context, AuthProvider authProvider) {
    final loc = AppLocalizations.of(context);

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          ElevatedButton(
            onPressed: authProvider.isLoading
                ? null
                : () => _loginWithPassword(context),
            child: Text("${loc.translate('login')} with Password"),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: authProvider.isLoading
                ? null
                : () => _continueWithGoogle(context),
            icon: authProvider.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.account_circle_outlined),
            label: const Text('Continue with Google'),
          ),
        ],
      ),
    );
  }

  Future<void> _loginWithPassword(BuildContext context) async {
    String identifier;
    if (_tabController.index == 0) {
      if (_aadhaarController.text.trim().length != 12) {
        _showError('Enter valid Aadhaar number');
        return;
      }
      identifier = _aadhaarController.text.trim();
    } else {
      if (_mobileController.text.trim().length != 10) {
        _showError('Enter valid mobile number');
        return;
      }
      identifier = _mobileController.text.trim();
    }

    if (_passwordController.text.trim().isEmpty) {
      _showError('Password is required');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.login(
      identifier,
      _passwordController.text,
      UserType.citizen,
    );
    if (!mounted) {
      return;
    }
    if (!ok) {
      _showError(authProvider.error ?? 'Login failed');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OTPVerificationScreen(
          identifier: identifier,
          userType: UserType.citizen,
          isSecondFactor: true,
        ),
      ),
    );
  }

  Future<void> _continueWithGoogle(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.signInWithGoogle(role: UserType.citizen);
    if (!mounted) {
      return;
    }

    if (!ok) {
      _showError(authProvider.error ?? 'Google sign-in failed');
      return;
    }

    Navigator.pushReplacementNamed(context, '/citizen-dashboard');
  }

  // ================= FOOTER =================
  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.security, color: AppColors.saffron),
            SizedBox(width: 8),
            Text("Protected by UIDAI"),
          ],
        ),
      ],
    );
  }

  // ================= LANGUAGE =================
  Widget _buildLanguageSelector(
      BuildContext context,
      SettingsProvider settingsProvider) {
    final loc = AppLocalizations.of(context);
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }
}
