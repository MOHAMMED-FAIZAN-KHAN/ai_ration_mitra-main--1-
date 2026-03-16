import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_stock_provider.dart';
import '../../models/stock.dart';

class StockDetailScreen extends StatelessWidget {
  final String itemName;

  const StockDetailScreen({super.key, required this.itemName});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminStockProvider>(context);
    final storeStocks = provider.getStockForItem(itemName);
    final movements = provider.getMovementsForItem(itemName);

    return Scaffold(
      appBar: AppBar(
        title: Text('$itemName Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Store-wise Stock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...storeStocks.map((stock) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stock.fpsName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Current: ${stock.currentStock} ${stock.unit}'),
                            Text('Max: ${stock.maxCapacity} ${stock.unit}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: stock.percentage / 100,
                          backgroundColor: Colors.grey[300],
                          color: _getStatusColor(stock.status),
                        ),
                        const SizedBox(height: 8),
                        Text('Status: ${stock.status.toString().split('.').last}', style: TextStyle(color: _getStatusColor(stock.status))),
                      ],
                    ),
                  ),
                )),
            const Divider(height: 32),
            const Text('Recent Movements', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...movements.map((movement) => ListTile(
                  leading: CircleAvatar(
                    // ignore: deprecated_member_use
                    backgroundColor: _getMovementColor(movement.type).withOpacity(0.2),
                    child: Icon(_getMovementIcon(movement.type), color: _getMovementColor(movement.type), size: 20),
                  ),
                  title: Text(movement.fpsName),
                  subtitle: Text('${movement.type.toString().split('.').last}: ${movement.quantity} ${movement.unit}'),
                  trailing: Text(_formatDate(movement.timestamp)),
                )),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(StockStatus status) {
    switch (status) {
      case StockStatus.good: return Colors.green;
      case StockStatus.low: return Colors.orange;
      case StockStatus.critical: return Colors.red;
    }
  }

  Color _getMovementColor(MovementType type) {
    switch (type) {
      case MovementType.received: return Colors.green;
      case MovementType.distributed: return Colors.blue;
      case MovementType.missing: return Colors.red;
      case MovementType.incoming: return Colors.orange;
    }
  }

  IconData _getMovementIcon(MovementType type) {
    switch (type) {
      case MovementType.received: return Icons.download;
      case MovementType.distributed: return Icons.upload;
      case MovementType.missing: return Icons.error_outline;
      case MovementType.incoming: return Icons.schedule;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}