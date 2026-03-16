import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../models/fps_operations.dart';
import '../../models/grievance.dart';
import '../../models/stock.dart';
import '../../providers/admin_stock_provider.dart';
import '../../providers/fps_operations_provider.dart';
import '../../providers/grievance_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _showOnlyOpen = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<GrievanceProvider>().loadAllGrievances();
      await context.read<AdminStockProvider>().loadAllStock();
    });
  }

  @override
  Widget build(BuildContext context) {
    final grievanceProvider = context.watch<GrievanceProvider>();
    final stockProvider = context.watch<AdminStockProvider>();
    final fpsOps = context.watch<FPSOperationsProvider>();

    final alerts = _buildAlerts(grievanceProvider, stockProvider, fpsOps);
    final visible = _showOnlyOpen
        ? alerts.where((item) => item.status != 'Resolved').toList()
        : alerts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operational Alerts'),
        actions: [
          Row(
            children: [
              const Text('Open'),
              Switch(
                value: _showOnlyOpen,
                onChanged: (value) => setState(() => _showOnlyOpen = value),
              ),
            ],
          ),
        ],
      ),
      body: visible.isEmpty
          ? const Center(child: Text('No alerts'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final alert = visible[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: alert.color.withValues(alpha: 0.18),
                      child: Icon(alert.icon, color: alert.color),
                    ),
                    title: Text(alert.title),
                    subtitle: Text(alert.message),
                    trailing: Chip(
                      label: Text(
                        alert.status,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      backgroundColor: alert.status == 'Resolved'
                          ? AppColors.green
                          : alert.color,
                    ),
                    onTap: () {
                      if (alert.route != null) {
                        Navigator.pushNamed(context, alert.route!);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  List<_AlertItem> _buildAlerts(
    GrievanceProvider grievanceProvider,
    AdminStockProvider stockProvider,
    FPSOperationsProvider fpsOps,
  ) {
    final citizenPending = grievanceProvider.grievances
        .where((item) =>
            item.status == GrievanceStatus.pending ||
            item.status == GrievanceStatus.inProgress)
        .length;
    final fpsPending = fpsOps.grievances
        .where((item) => item.status != DealerGrievanceStatus.resolved)
        .length;
    final criticalStocks = stockProvider.stockItems
        .where((item) => item.status == StockStatus.critical)
        .toList();
    final pendingRequisitions = fpsOps.requisitions
        .where((item) => item.status == DealerRequisitionStatus.pending)
        .length;

    return [
      _AlertItem(
        title: 'Citizen Grievance Queue',
        message: '$citizenPending citizen grievances require action.',
        status: citizenPending > 0 ? 'Open' : 'Resolved',
        color: citizenPending > 0 ? Colors.red : AppColors.green,
        icon: Icons.feedback_outlined,
        route: '/admin/grievances',
      ),
      _AlertItem(
        title: 'FPS Dealer Grievance Queue',
        message: '$fpsPending FPS dealer grievances are unresolved.',
        status: fpsPending > 0 ? 'Open' : 'Resolved',
        color: fpsPending > 0 ? Colors.deepOrange : AppColors.green,
        icon: Icons.storefront_outlined,
        route: '/admin/grievances',
      ),
      _AlertItem(
        title: 'Critical Stock Alerts',
        message: criticalStocks.isEmpty
            ? 'No critical stock shortage.'
            : '${criticalStocks.length} critical stock items across FPS stores.',
        status: criticalStocks.isEmpty ? 'Resolved' : 'Open',
        color: criticalStocks.isEmpty ? AppColors.green : AppColors.saffron,
        icon: Icons.inventory_2_outlined,
        route: '/admin/stock',
      ),
      _AlertItem(
        title: 'Pending Requisitions',
        message: '$pendingRequisitions stock requisitions pending approval.',
        status: pendingRequisitions > 0 ? 'Open' : 'Resolved',
        color: pendingRequisitions > 0 ? Colors.indigo : AppColors.green,
        icon: Icons.assignment_outlined,
        route: '/admin/requisitions',
      ),
    ];
  }
}

class _AlertItem {
  final String title;
  final String message;
  final String status;
  final Color color;
  final IconData icon;
  final String? route;

  const _AlertItem({
    required this.title,
    required this.message,
    required this.status,
    required this.color,
    required this.icon,
    this.route,
  });
}
