// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/fps_operations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fps_operations_provider.dart';

class FPSDashboard extends StatelessWidget {
  const FPSDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final ops = context.watch<FPSOperationsProvider>();
    final auth = context.watch<AuthProvider>();
    final dealer = auth.currentUser;
    final pendingRequisitions = ops.requisitions
        .where((item) => item.status == DealerRequisitionStatus.pending)
        .length;
    final dealerName = (dealer?.name ?? '').trim().isNotEmpty
        ? dealer!.name.trim()
        : 'FPS Dealer';
    final fpsId =
        (dealer?.fpsId ?? '').trim().isNotEmpty ? dealer!.fpsId!.trim() : 'FPS-2736';
    final address =
        (dealer?.address ?? '').trim().isNotEmpty ? dealer!.address!.trim() : 'Ward 11, Mumbai';

    return WillPopScope(
      onWillPop: () => _confirmLogout(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ration Shop Owner Panel'),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/fps/notifications'),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none),
                  if (ops.unreadNotificationCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${ops.unreadNotificationCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Chip(
                label: Text('Shop Active',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                backgroundColor: AppColors.green,
                padding: EdgeInsets.symmetric(horizontal: 6),
              ),
            ),
          ],
        ),
        body: ops.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                  /// HEADER CARD (Styled Like Citizen Dashboard)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.saffron.withValues(alpha: 0.08),
                          Colors.orange.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.saffron.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$dealerName ($fpsId)',
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Daily operational dashboard for distribution and stock',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          address,
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// METRICS GRID
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.3,
                    children: [
                      _metricCard(
                        title: 'Eligible Today',
                        value: '${ops.eligibleBeneficiaryCount}',
                        color: Colors.blue,
                        icon: Icons.people_alt_outlined,
                        onTap: () =>
                            Navigator.pushNamed(context, '/fps/beneficiaries'),
                      ),
                      _metricCard(
                        title: 'Distributed Today',
                        value: '${ops.todayDistributionCount}',
                        color: Colors.green,
                        icon: Icons.check_circle_outline,
                        onTap: () =>
                            Navigator.pushNamed(context, '/fps/distribution'),
                      ),
                      _metricCard(
                        title: 'Low Stock Items',
                        value: '${ops.lowStockItems.length}',
                        color: Colors.red,
                        icon: Icons.warning_amber_rounded,
                        onTap: () =>
                            Navigator.pushNamed(context, '/fps/stock'),
                      ),
                      _metricCard(
                        title: 'Pending Requisitions',
                        value: '$pendingRequisitions',
                        color: Colors.orange,
                        icon: Icons.request_page_outlined,
                        onTap: () => Navigator.pushNamed(
                            context, '/fps/stock-requisition'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  const Text(
                    'Quick Operations',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  /// QUICK TILES
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.25,
                    children: [
                      _quickTile(
                          context: context,
                          title: 'Scan Beneficiary',
                          icon: Icons.qr_code_scanner,
                          color: Colors.blue,
                          route: '/fps/scan'),
                      _quickTile(
                          context: context,
                          title: 'Manage Stock',
                          icon: Icons.inventory_2_outlined,
                          color: Colors.orange,
                          route: '/fps/stock'),
                      _quickTile(
                          context: context,
                          title: 'Distribution Queue',
                          icon: Icons.local_shipping_outlined,
                          color: Colors.green,
                          route: '/fps/distribution'),
                      _quickTile(
                          context: context,
                          title: 'Plan Distribution',
                          icon: Icons.event_note_outlined,
                          color: Colors.indigo,
                          route: '/fps/distribution-planner'),
                      _quickTile(
                          context: context,
                          title: 'Beneficiary Registry',
                          icon: Icons.badge_outlined,
                          color: Colors.purple,
                          route: '/fps/beneficiaries'),
                      _quickTile(
                          context: context,
                          title: 'Notifications',
                          icon: Icons.notifications_active_outlined,
                          color: Colors.red,
                          route: '/fps/notifications'),
                      _quickTile(
                          context: context,
                          title: 'Dealer Profile',
                          icon: Icons.person_outline,
                          color: Colors.teal,
                          route: '/fps/profile'),
                      _quickTile(
                          context: context,
                          title: 'Grievances',
                          icon: Icons.feedback_outlined,
                          color: Colors.brown,
                          route: '/fps/grievances'),
                    ],
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Low Stock Alerts',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (ops.lowStockItems.isEmpty)
                    Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('All stock levels are healthy.'),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/fps/stock'),
                            icon:
                                const Icon(Icons.inventory_2_outlined),
                            label: const Text(
                              'MANAGE STOCK',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                                context, '/fps/stock-requisition'),
                            icon:
                                const Icon(Icons.request_quote_outlined),
                            label: const Text(
                              'RAISE REQUEST',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.saffron,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...ops.lowStockItems.take(3).map(
                          (item) => Card(
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const Icon(Icons.warning,
                                  color: Colors.red),
                              title: Text(item.itemName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  'Current: ${item.currentStock.toStringAsFixed(0)} ${item.unit} / '
                                  '${item.maxCapacity.toStringAsFixed(0)} ${item.unit}'),
                              trailing: TextButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/fps/stock'),
                                child: const Text('Manage'),
                              ),
                            ),
                          ),
                        )
                  ],
                  ],
                ),
              ),
      ),
    );
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Do you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
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
        ) ??
        false;

    if (shouldLogout) {
      await context.read<AuthProvider>().logout();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
    return false;
  }

  Widget _metricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _quickTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
