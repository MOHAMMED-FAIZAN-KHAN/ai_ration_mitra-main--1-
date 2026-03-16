import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../models/fps_operations.dart';
import '../../providers/fps_operations_provider.dart';

class RequisitionManagementScreen extends StatefulWidget {
  const RequisitionManagementScreen({super.key});

  @override
  State<RequisitionManagementScreen> createState() =>
      _RequisitionManagementScreenState();
}

class _RequisitionManagementScreenState
    extends State<RequisitionManagementScreen> {
  late TextEditingController _allocationController;

  @override
  void initState() {
    super.initState();
    _allocationController = TextEditingController();
  }

  @override
  void dispose() {
    _allocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ops = context.watch<FPSOperationsProvider>();
    final requisitions = ops.requisitions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Requisitions'),
      ),
      body: ops.isLoading
          ? const Center(child: CircularProgressIndicator())
          : requisitions.isEmpty
              ? const Center(child: Text('No requisitions received'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: requisitions.length,
                  itemBuilder: (context, index) {
                    final req = requisitions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${req.itemName} • ${req.requestedQuantity} ${req.unit}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    _statusText(req.status),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                  backgroundColor: _statusColor(req.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              req.reason,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Requested: ${_formatDate(req.requestedAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (req.status ==
                                DealerRequisitionStatus.pending) ...[
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () async {
                                      await context
                                          .read<FPSOperationsProvider>()
                                          .updateRequisitionStatus(
                                            req.id,
                                            DealerRequisitionStatus.rejected,
                                          );
                                    },
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.green,
                                    ),
                                    onPressed: () =>
                                        _showAllocationDialog(context, req),
                                    child: const Text('Approve'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _statusText(DealerRequisitionStatus status) {
    switch (status) {
      case DealerRequisitionStatus.pending:
        return 'Pending';
      case DealerRequisitionStatus.approved:
        return 'Approved';
      case DealerRequisitionStatus.rejected:
        return 'Rejected';
    }
  }

  Color _statusColor(DealerRequisitionStatus status) {
    switch (status) {
      case DealerRequisitionStatus.pending:
        return Colors.orange;
      case DealerRequisitionStatus.approved:
        return AppColors.green;
      case DealerRequisitionStatus.rejected:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showAllocationDialog(
    BuildContext context,
    StockRequisition req,
  ) async {
    _allocationController.text = req.requestedQuantity.toString();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Allocate Stock to Dealer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item: ${req.itemName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Requested: ${req.requestedQuantity} ${req.unit}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _allocationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity to Allocate (${req.unit})',
                border: const OutlineInputBorder(),
                hintText: 'Enter allocation quantity',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This quantity will be automatically added to the dealer\'s inventory.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
            ),
            onPressed: () async {
              final allocationQty =
                  double.tryParse(_allocationController.text.trim()) ?? 0;
              if (allocationQty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid quantity'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final ops = context.read<FPSOperationsProvider>();

              // Approve the requisition
              await ops.updateRequisitionStatus(
                req.id,
                DealerRequisitionStatus.approved,
              );

              // Automatically add the allocated stock to the dealer's inventory
              await ops.receiveStock(req.itemName, allocationQty);

              if (context.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Requisition approved and ${allocationQty} ${req.unit} of ${req.itemName} allocated to dealer',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Approve & Allocate'),
          ),
        ],
      ),
    );
  }
}
