import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/stock.dart';
import '../../providers/fps_operations_provider.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/section_header.dart';

class StockManagement extends StatefulWidget {
  const StockManagement({super.key});

  @override
  State<StockManagement> createState() => _StockManagementState();
}

class _StockManagementState extends State<StockManagement> {
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedItem;

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ops = context.watch<FPSOperationsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/fps/stock-requisition'),
            icon: const Icon(Icons.request_page_outlined),
            tooltip: 'Stock Requisitions',
          ),
        ],
      ),
      body: ops.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        title: 'Items',
                        value: '${ops.stockItems.length}',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summaryCard(
                        title: 'Low/Critical',
                        value: '${ops.lowStockItems.length}',
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.remove_circle_outline,
                        color: Colors.red),
                    title: const Text('Remove Stock'),
                    subtitle:
                        const Text('Deduct stock moved out / damaged stock'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openRemoveStockDialog(context),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.assignment_outlined,
                        color: Colors.orange),
                    title: const Text('Raise Stock Requisition'),
                    subtitle: const Text('Send stock request to admin'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openRequisitionDialog(context),
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Current Inventory'),
                ...ops.stockItems.map((item) => _stockCard(context, item)),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Recent Requisitions'),
                if (ops.requisitions.isEmpty)
                  const AppEmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No requisitions yet',
                    message: 'Submitted requisitions will appear here.',
                  )
                else
                  ...ops.requisitions.take(3).map(
                        (req) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.description_outlined),
                            title: Text(
                                '${req.itemName} - ${req.requestedQuantity} ${req.unit}'),
                            subtitle: Text(
                                'Status: ${req.status.name.toUpperCase()}'),
                          ),
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }

  Widget _stockCard(BuildContext context, StockItem item) {
    final level = item.currentStock / item.maxCapacity;
    final color = switch (item.status) {
      StockStatus.good => Colors.green,
      StockStatus.low => Colors.orange,
      StockStatus.critical => Colors.red,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.itemName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(
                    item.status.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  backgroundColor: color,
                ),
              ],
            ),
            Text(
              '${item.currentStock.toStringAsFixed(0)} ${item.unit} / ${item.maxCapacity.toStringAsFixed(0)} ${item.unit}',
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: level.clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRequisitionDialog(BuildContext context) async {
    final ops = context.read<FPSOperationsProvider>();
    _selectedItem =
        ops.stockItems.isEmpty ? null : ops.stockItems.first.itemName;
    _qtyController.clear();
    _reasonController.clear();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raise Requisition'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedItem,
              items: ops.stockItems
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.itemName,
                      child: Text(item.itemName),
                    ),
                  )
                  .toList(),
              onChanged: (value) => _selectedItem = value,
              decoration: const InputDecoration(labelText: 'Item'),
            ),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Requested Quantity'),
            ),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = double.tryParse(_qtyController.text.trim()) ?? 0;
              if (_selectedItem == null ||
                  quantity <= 0 ||
                  _reasonController.text.trim().isEmpty) {
                return;
              }
              final item = _findStockByName(ops.stockItems, _selectedItem!);
              await ops.addRequisition(
                itemName: _selectedItem!,
                quantity: quantity,
                unit: item?.unit ?? 'kg',
                reason: _reasonController.text.trim(),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Requisition submitted to admin'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _openRemoveStockDialog(BuildContext context) async {
    final ops = context.read<FPSOperationsProvider>();
    _selectedItem =
        ops.stockItems.isEmpty ? null : ops.stockItems.first.itemName;
    _qtyController.clear();
    _reasonController.clear();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedItem,
              items: ops.stockItems
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.itemName,
                      child: Text(item.itemName),
                    ),
                  )
                  .toList(),
              onChanged: (value) => _selectedItem = value,
              decoration: const InputDecoration(labelText: 'Item'),
            ),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Quantity to Remove'),
            ),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Moved stock / damaged / returned',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = double.tryParse(_qtyController.text.trim()) ?? 0;
              final reason = _reasonController.text.trim();
              if (_selectedItem == null || quantity <= 0 || reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Select item, enter quantity and reason'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              final success = await ops.removeStock(
                _selectedItem!,
                quantity,
                reason: reason,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Stock removed successfully'
                      : (ops.error ?? 'Unable to remove stock')),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

StockItem? _findStockByName(List<StockItem> items, String itemName) {
  for (final item in items) {
    if (item.itemName == itemName) {
      return item;
    }
  }
  return null;
}
