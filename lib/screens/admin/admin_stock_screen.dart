import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_stock_provider.dart';
import '../../models/stock.dart';
import '../../widgets/admin/stock_summary_card.dart';
import '../../widgets/common/loading_indicator.dart';
import 'stock_detail_screen.dart';

class AdminStockScreen extends StatefulWidget {
  const AdminStockScreen({super.key});

  @override
  State<AdminStockScreen> createState() => _AdminStockScreenState();
}

class _AdminStockScreenState extends State<AdminStockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<AdminStockProvider>(context, listen: false);
    await provider.loadAllStock();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminStockProvider>(context);
    final appBarForeground = Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onPrimary;
    final unselectedColor = appBarForeground.withValues(alpha: 0.72);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: appBarForeground,
          unselectedLabelColor: unselectedColor,
          indicatorColor: appBarForeground,
          indicatorWeight: 2.8,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Live Stock'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const LoadingIndicator()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverview(provider),
                _buildLiveStock(provider),
                _buildHistory(provider),
              ],
            ),
    );
  }

  Widget _buildOverview(AdminStockProvider provider) {
    final summaries = provider.getStockSummary();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Stock Summary by Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...summaries.map((summary) => StockSummaryCard(summary: summary)),
      ],
    );
  }

  Widget _buildLiveStock(AdminStockProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Live Stock Levels (All Stores)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...provider.stockItems.map((item) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(item.status).withValues(alpha: 0.2),
                  child: Icon(_getStatusIcon(item.status), color: _getStatusColor(item.status), size: 20),
                ),
                title: Text('${item.fpsName} - ${item.itemName}'),
                subtitle: Text('${item.currentStock} / ${item.maxCapacity} ${item.unit} • Updated: ${_formatTime(item.lastUpdated)}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _getStatusColor(item.status), borderRadius: BorderRadius.circular(12)),
                  child: Text('${item.percentage.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StockDetailScreen(itemName: item.itemName)),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildHistory(AdminStockProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Stock Movement History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...provider.movements.map((movement) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getMovementColor(movement.type).withValues(alpha: 0.2),
                  child: Icon(_getMovementIcon(movement.type), color: _getMovementColor(movement.type), size: 20),
                ),
                title: Text('${movement.fpsName} - ${movement.itemName}'),
                subtitle: Text('${movement.type.toString().split('.').last}: ${movement.quantity} ${movement.unit} • ${_formatDate(movement.timestamp)}'),
                trailing: Text(movement.referenceId ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            )),
      ],
    );
  }

  Color _getStatusColor(StockStatus status) {
    switch (status) {
      case StockStatus.good:
        return Colors.green;
      case StockStatus.low:
        return Colors.orange;
      case StockStatus.critical:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(StockStatus status) {
    switch (status) {
      case StockStatus.good:
        return Icons.check_circle;
      case StockStatus.low:
        return Icons.warning;
      case StockStatus.critical:
        return Icons.error;
    }
  }

  Color _getMovementColor(MovementType type) {
    switch (type) {
      case MovementType.received:
        return Colors.green;
      case MovementType.distributed:
        return Colors.blue;
      case MovementType.missing:
        return Colors.red;
      case MovementType.incoming:
        return Colors.orange;
    }
  }

  IconData _getMovementIcon(MovementType type) {
    switch (type) {
      case MovementType.received:
        return Icons.download;
      case MovementType.distributed:
        return Icons.upload;
      case MovementType.missing:
        return Icons.error_outline;
      case MovementType.incoming:
        return Icons.schedule;
    }
  }

  String _formatTime(DateTime time) => '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
