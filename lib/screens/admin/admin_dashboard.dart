import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../models/fps_operations.dart';
import '../../models/stock.dart';
import '../../providers/admin_stock_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fps_operations_provider.dart';
import '../../providers/grievance_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    await context.read<GrievanceProvider>().loadAllGrievances();
    await context.read<AdminStockProvider>().loadAllStock();
  }

  @override
  Widget build(BuildContext context) {
    final grievanceProvider = context.watch<GrievanceProvider>();
    final stockProvider = context.watch<AdminStockProvider>();
    final fpsOps = context.watch<FPSOperationsProvider>();
    final auth = context.watch<AuthProvider>();

    final adminName = auth.currentUser?.name.trim();
    final adminInitial =
        (adminName != null && adminName.isNotEmpty)
            ? adminName[0].toUpperCase()
            : 'A';

    final citizenPending = grievanceProvider.pendingGrievanceCount;

    final fpsPending = fpsOps.grievances
        .where((item) => item.status != DealerGrievanceStatus.resolved)
        .length;

    final totalPendingGrievances = citizenPending + fpsPending;

    final pendingRequisitions = fpsOps.requisitions
        .where((item) => item.status == DealerRequisitionStatus.pending)
        .length;

    final criticalStockCount = stockProvider.stockItems
        .where((item) => item.status == StockStatus.critical)
        .length;

    return WillPopScope(
      onWillPop: () => _confirmLogout(context),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Admin Control Center',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.saffron,
                  Colors.deepOrange.shade700,
                ],
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () =>
                    Navigator.pushNamed(context, '/admin/profile'),
                borderRadius: BorderRadius.circular(24),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    adminInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF8F2),
                Color(0xFFFFFFFF),
              ],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                /// FUTURISTIC STATUS PANEL
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.saffron.withValues(alpha: 0.15),
                        Colors.orange.shade100,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.saffron.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.saffron,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          totalPendingGrievances == 0 &&
                                  pendingRequisitions == 0 &&
                                  criticalStockCount == 0
                              ? 'All systems stable and operational'
                              : 'Attention required: Pending administrative actions',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                /// MODULE GRID
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.05,
                  children: [
                    _AdminCard(
                      icon: Icons.feedback_outlined,
                      title: 'Grievances',
                      value: totalPendingGrievances.toString(),
                      color: Colors.red,
                      onTap: () =>
                          Navigator.pushNamed(context, '/admin/grievances'),
                    ),
                    _AdminCard(
                      icon: Icons.assignment_outlined,
                      title: 'Requisitions',
                      value: pendingRequisitions.toString(),
                      color: Colors.indigo,
                      onTap: () =>
                          Navigator.pushNamed(context, '/admin/requisitions'),
                    ),
                    _AdminCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Critical Stock',
                      value: criticalStockCount.toString(),
                      color: Colors.deepOrange,
                      onTap: () =>
                          Navigator.pushNamed(context, '/admin/stock'),
                    ),
                    _AdminCard(
                      icon: Icons.warning_amber_rounded,
                      title: 'Alerts',
                      value:
                          '${criticalStockCount + totalPendingGrievances}',
                      color: AppColors.saffron,
                      onTap: () =>
                          Navigator.pushNamed(context, '/admin/alerts'),
                    ),
                    _AdminCard(
                      icon: Icons.campaign_outlined,
                      title: 'Creator',
                      value: 'Notify',
                      color: Colors.deepPurple,
                      onTap: () =>
                          Navigator.pushNamed(context, '/admin/creator'),
                    ),
                    _AdminCard(
                      icon: Icons.storefront_outlined,
                      title: 'FPS Management',
                      value: 'Open',
                      color: Colors.blue,
                      onTap: () => Navigator.pushNamed(
                          context, '/admin/fps-management'),
                    ),
                    _AdminCard(
                      icon: Icons.list_alt_outlined,
                      title: 'Login Lists',
                      value: 'View',
                      color: Colors.brown,
                      onTap: () =>
                          Navigator.pushNamed(context, '/admin/login-lists'),
                    ),
                    _AdminCard(
                      icon: Icons.person_outline,
                      title: 'Admin Profile',
                      value: 'View',
                      color: Colors.teal,
                      onTap: () =>
                          Navigator.pushNamed(context, '/admin/profile'),
                    ),
                  ],
                ),
                ],
              ),
            ),
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
      if (!mounted) {
        return false;
      }
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
    return false;
  }
}

class _AdminCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<_AdminCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        transform: _hovered
            ? Matrix4.diagonal3Values(1.04, 1.04, 1)
            : Matrix4.identity(),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  widget.color.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color,
                            widget.color.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.value,
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color,
                        widget.color.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'OPEN MODULE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
