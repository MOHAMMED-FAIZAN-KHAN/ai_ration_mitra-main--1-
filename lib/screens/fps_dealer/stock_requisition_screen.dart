import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/stock.dart';
import '../../providers/fps_operations_provider.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/section_header.dart';

class StockRequisitionScreen extends StatefulWidget {
  const StockRequisitionScreen({super.key});

  @override
  State<StockRequisitionScreen> createState() => _StockRequisitionScreenState();
}

class _StockRequisitionScreenState extends State<StockRequisitionScreen> {
  final _formKey = GlobalKey<FormState>();
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
    _selectedItem ??= ops.stockItems.isEmpty ? null : ops.stockItems.first.itemName;

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Requisition')),
      body: ops.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Requisition',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedItem,
                      decoration: const InputDecoration(
                        labelText: 'Item',
                        border: OutlineInputBorder(),
                      ),
                      items: ops.stockItems
                          .map(
                            (stock) => DropdownMenuItem<String>(
                              value: stock.itemName,
                              child: Text(stock.itemName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _selectedItem = value),
                      validator: (value) => value == null ? 'Select an item' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Requested Quantity',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final qty = double.tryParse(value ?? '');
                        if (qty == null || qty <= 0) return 'Enter valid quantity';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Reason required' : null,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _submit(context),
                        child: const Text('Submit Requisition'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const SectionHeader(title: 'Submitted Requests'),
          if (ops.requisitions.isEmpty)
            const AppEmptyState(
              icon: Icons.assignment_outlined,
              title: 'No requisitions yet',
              message: 'Submit a requisition to see it listed here.',
            )
          else
            ...ops.requisitions.map(
                  (req) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.assignment),
                      title: Text('${req.itemName} - ${req.requestedQuantity} ${req.unit}'),
                      subtitle: Text('${_formatDate(req.requestedAt)}\nReason: ${req.reason}'),
                      isThreeLine: true,
                      trailing: Chip(label: Text(req.status.name.toUpperCase())),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate() || _selectedItem == null) {
      return;
    }
    final ops = context.read<FPSOperationsProvider>();
    final qty = double.parse(_qtyController.text.trim());
    final unit = _findStockByName(ops.stockItems, _selectedItem!)?.unit ??
        'kg';
    await ops.addRequisition(
      itemName: _selectedItem!,
      quantity: qty,
      unit: unit,
      reason: _reasonController.text.trim(),
    );
    _qtyController.clear();
    _reasonController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Requisition submitted successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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
