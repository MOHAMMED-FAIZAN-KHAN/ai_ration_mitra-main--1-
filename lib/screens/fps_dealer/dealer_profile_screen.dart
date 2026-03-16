import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../models/fps_operations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fps_operations_provider.dart';
import 'dealer_profile_qr_screen.dart';

class DealerProfileScreen extends StatelessWidget {
  const DealerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ops = context.watch<FPSOperationsProvider>();
    final user = auth.currentUser;
    final pendingRequisitions = ops.requisitions
        .where((item) => item.status == DealerRequisitionStatus.pending)
        .length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Dealer Profile',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          IconButton(
            onPressed: user == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DealerProfileQrScreen(user: user),
                      ),
                    ),
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'Show Dealer QR',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/fps/edit-profile'),
            icon: const Icon(Icons.edit_outlined, color: AppColors.saffron),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings_outlined, color: AppColors.saffron),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: ops.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildIdentityCard(user),
                const SizedBox(height: 12),
                _buildStatsRow(
                  context: context,
                  ops: ops,
                  pendingRequisitions: pendingRequisitions,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context: context,
                  title: 'Dealer Information',
                  icon: Icons.badge_outlined,
                  children: [
                    _infoRow(context, 'Dealer Name', user?.name ?? 'FPS Dealer'),
                    _divider(context),
                    _infoRow(context, 'Shop ID', user?.fpsId ?? 'FPS-2736'),
                    _divider(context),
                    _infoRow(context, 'Mobile', user?.mobileNumber ?? 'Not available'),
                    _divider(context),
                    _infoRow(context, 'Email', user?.email ?? 'Not available'),
                    _divider(context),
                    _infoRow(context, 'Address', user?.address ?? 'Shyam Nagar, Sector 9'),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context: context,
                  title: 'Operations Snapshot',
                  icon: Icons.dashboard_customize_outlined,
                  children: [
                    _infoRow(context, 'Today Distributions', '${ops.todayDistributionCount}'),
                    _divider(context),
                    _infoRow(
                      context,
                      'Eligible Beneficiaries',
                      '${ops.eligibleBeneficiaryCount}',
                    ),
                    _divider(context),
                    _infoRow(context, 'Low Stock Items', '${ops.lowStockItems.length}'),
                    _divider(context),
                    _infoRow(context, 'Pending Requisitions', '$pendingRequisitions'),
                    _divider(context),
                    _infoRow(context, 'Open Grievances', '${ops.openGrievanceCount}'),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/fps/edit-profile'),
                  icon: const Icon(Icons.edit_note),
                  label: const Text(
                    'EDIT DEALER PROFILE',
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
                  onPressed: user == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DealerProfileQrScreen(user: user),
                            ),
                          ),
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text(
                    'SHOW DEALER PROFILE QR',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showLogoutDialog(context, context.read<AuthProvider>()),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'LOGOUT',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildIdentityCard(user) {
    final name = user?.name?.toString().trim().isNotEmpty == true
        ? user.name.toString().trim()
        : 'FPS Dealer';
    final initial = name[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.saffron.withValues(alpha: 0.92),
            const Color(0xFFCC7A2C),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.24),
            child: Text(
              initial,
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
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Shop ID: ${user?.fpsId ?? 'FPS-2736'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _badge('Verified Dealer'),
                    const SizedBox(width: 8),
                    _badge('Operational'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow({
    required BuildContext context,
    required FPSOperationsProvider ops,
    required int pendingRequisitions,
  }) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context: context,
            value: '${ops.todayDistributionCount}',
            label: 'Today Distribution',
            color: AppColors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            context: context,
            value: '${ops.lowStockItems.length}',
            label: 'Low Stock',
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            context: context,
            value: '$pendingRequisitions',
            label: 'Pending Req.',
            color: Colors.indigo,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required BuildContext context,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
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

  Widget _infoRow(BuildContext context, String label, String value) {
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

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

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
              navigator.pushReplacementNamed('/');
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
