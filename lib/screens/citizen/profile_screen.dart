import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/colors.dart';
import 'citizen_profile_qr_screen.dart';
import 'edit_profile_screen.dart';
import '../../widgets/app_empty_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings_outlined, color: AppColors.saffron),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;

          if ((!authProvider.isInitialized || authProvider.isLoading) &&
              user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (user == null) {
            return const AppEmptyState(
              icon: Icons.person_outline,
              title: 'No profile yet',
              message: 'Sign in to see your profile details.',
            );
          }

          final category = _profileCategory(user.category);
          final mobile = _profileMobile(user.mobileNumber);
          final uid = _profileUid(user.uid, user.aadhaarNumber, user.id);
          final assignedShop = _profileAssignedShop(user.assignedShop);
          final location = _profileLocation(user.address);
          final aadhaarMasked = _maskAadhaar(user.aadhaarNumber);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Section
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.saffron,
                      child: Text(
                        _getAvatarInitial(user.name),
                        style: TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user.name.trim().isEmpty ? 'Citizen' : user.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'UID: $uid',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 30),

                // Personal Information Card
                _buildInfoCard(
                  context: context,
                  title: 'Personal Information',
                  icon: Icons.person,
                  children: [
                    _buildInfoRow(context, 'Full Name', user.name),
                    const Divider(height: 24),
                    _buildInfoRow(context, 'Mobile', mobile),
                    const Divider(height: 24),
                    _buildInfoRow(context, 'Email', user.email ?? 'Not provided'),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      'Aadhaar',
                      aadhaarMasked,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Distribution Details Card
                _buildInfoCard(
                  context: context,
                  title: 'Distribution Details',
                  icon: Icons.location_on,
                  children: [
                    _buildInfoRow(context, 'Category', category),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      'Assigned Shop',
                      assignedShop,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(context, 'Location', location),
                  ],
                ),
                const SizedBox(height: 16),

                // Account Status Card
                _buildInfoCard(
                  context: context,
                  title: 'Account Status',
                  icon: Icons.verified,
                  children: [
                    _buildInfoRow(context, 'Status', 'Verified', isHighlight: true),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CitizenProfileQrScreen(user: user),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Show Profile QR'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.saffron,
                      side: const BorderSide(color: AppColors.saffron),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.saffron,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, authProvider),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.saffron.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.saffron,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isHighlight ? AppColors.success : Colors.black87,
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  String _maskAadhaar(String? aadhaar) {
    if (aadhaar == null || aadhaar.trim().isEmpty) {
      return 'XXXX XXXX 1234';
    }
    final cleaned = aadhaar.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length >= 4) {
      return 'XXXX XXXX ${cleaned.substring(cleaned.length - 4)}';
    }
    if (aadhaar.length >= 4) {
      return 'XXXX XXXX ${aadhaar.substring(aadhaar.length - 4)}';
    }
    return 'XXXX XXXX 1234';
  }

  String _profileCategory(String? category) {
    final value = category?.trim() ?? '';
    return value.isEmpty ? 'PHH (BPL)' : value;
  }

  String _profileMobile(String? mobile) {
    final digits = (mobile ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    final value = mobile?.trim() ?? '';
    return value.isEmpty ? '+91 98765 43210' : value;
  }

  String _profileAssignedShop(String? assignedShop) {
    final value = assignedShop?.trim() ?? '';
    return value.isEmpty ? 'Shyam Ration Store' : value;
  }

  String _profileLocation(String? address) {
    final value = address?.trim() ?? '';
    return value.isEmpty ? 'Mumbai West' : value;
  }

  String _profileUid(String? uid, String? aadhaarNumber, String id) {
    final uidValue = uid?.trim() ?? '';
    if (uidValue.isNotEmpty) {
      return uidValue;
    }
    final aadhaarDigits =
        (aadhaarNumber ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (aadhaarDigits.length >= 12) {
      return '${aadhaarDigits.substring(0, 4)} ${aadhaarDigits.substring(4, 8)} ${aadhaarDigits.substring(8, 12)}';
    }
    final idDigits = id.replaceAll(RegExp(r'[^0-9]'), '').padRight(12, '0');
    return '${idDigits.substring(0, 4)} ${idDigits.substring(4, 8)} ${idDigits.substring(8, 12)}';
  }

  String _getAvatarInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'C';
    }
    return trimmed[0].toUpperCase();
  }

  void _showLogoutDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await authProvider.logout();
              navigator.pop();
              navigator.pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Yes',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
