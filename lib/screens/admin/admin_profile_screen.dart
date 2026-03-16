import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_empty_state.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Admin Profile',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/admin/edit-profile'),
            icon: const Icon(Icons.edit_outlined, color: AppColors.saffron),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings_outlined, color: AppColors.saffron),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: auth.isLoading && user == null
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const AppEmptyState(
                  icon: Icons.person_outline,
                  title: 'No admin user',
                  message: 'Sign in to view admin profile details.',
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildIdentityHeader(user.name, user.email, user.uid ?? user.id),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _miniStat(
                            context: context,
                            title: 'Privilege',
                            value: 'High',
                            color: Colors.red,
                            icon: Icons.shield_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _miniStat(
                            context: context,
                            title: 'Role',
                            value: 'State Admin',
                            color: Colors.indigo,
                            icon: Icons.admin_panel_settings_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _miniStat(
                            context: context,
                            title: 'Status',
                            value: 'Active',
                            color: AppColors.green,
                            icon: Icons.verified_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context: context,
                      title: 'Identity & Access',
                      icon: Icons.badge_outlined,
                      children: [
                        _row(context, 'Name', user.name),
                        _divider(context),
                        _row(context, 'Admin ID', user.uid ?? user.id),
                        _divider(context),
                        _row(context, 'Role', 'State Admin'),
                        _divider(context),
                        _row(context, 'Access', 'Restricted / Audited'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context: context,
                      title: 'Contact & Office',
                      icon: Icons.contact_phone_outlined,
                      children: [
                        _row(context, 'Email', user.email ?? 'admin@example.com'),
                        _divider(context),
                        _row(context, 'Mobile', user.mobileNumber ?? 'Not provided'),
                        _divider(context),
                        _row(context, 'Office', user.address ?? 'HQ Control Center'),
                        _divider(context),
                        _row(context, 'Authentication', 'Password + OTP'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/admin/edit-profile'),
                      icon: const Icon(Icons.edit_note),
                      label: const Text(
                        'EDIT ADMIN PROFILE',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saffron,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context, auth),
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'LOGOUT',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildIdentityHeader(String name, String? email, String adminId) {
    final safeName = name.trim().isEmpty ? 'Admin User' : name.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.saffron,
            AppColors.saffron.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            child: Text(
              safeName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  safeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email ?? 'admin@example.com',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  'Admin ID: $adminId',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required BuildContext context,
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.11),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
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
      elevation: 1.5,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                  child: Icon(icon, color: AppColors.saffron, size: 20),
                ),
                const SizedBox(width: 10),
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
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) =>
      Divider(height: 1, color: Colors.grey[300]);

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
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
