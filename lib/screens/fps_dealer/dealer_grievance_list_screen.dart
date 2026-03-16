import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/fps_operations.dart';
import '../../providers/fps_operations_provider.dart';
import '../../widgets/app_empty_state.dart';

class DealerGrievanceListScreen extends StatefulWidget {
  const DealerGrievanceListScreen({super.key});

  @override
  State<DealerGrievanceListScreen> createState() => _DealerGrievanceListScreenState();
}

class _DealerGrievanceListScreenState extends State<DealerGrievanceListScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ops = context.watch<FPSOperationsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dealer Grievances'),
        actions: [
          IconButton(
            onPressed: () => _openCreateGrievanceDialog(context),
            icon: const Icon(Icons.add),
            tooltip: 'New Grievance',
          ),
        ],
      ),
      body: ops.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ops.grievances.isEmpty
              ? const AppEmptyState(
                  icon: Icons.feedback_outlined,
                  title: 'No grievances yet',
                  message: 'Submit a grievance to track it here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ops.grievances.length,
                  itemBuilder: (context, index) {
                    final grievance = ops.grievances[index];
                    final color = _statusColor(grievance.status);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(grievance.title),
                        subtitle: Text(
                          '${grievance.description}\n${_formatDate(grievance.createdAt)}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<DealerGrievanceStatus>(
                          onSelected: (value) async {
                            await context
                                .read<FPSOperationsProvider>()
                                .updateGrievanceStatus(grievance.id, value);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: DealerGrievanceStatus.open,
                              child: Text('Open'),
                            ),
                            PopupMenuItem(
                              value: DealerGrievanceStatus.inProgress,
                              child: Text('In Progress'),
                            ),
                            PopupMenuItem(
                              value: DealerGrievanceStatus.resolved,
                              child: Text('Resolved'),
                            ),
                          ],
                          child: Chip(
                            label: Text(
                              grievance.status.name.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                            backgroundColor: color,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateGrievanceDialog(context),
        icon: const Icon(Icons.feedback_outlined),
        label: const Text('Raise Grievance'),
      ),
    );
  }

  Future<void> _openCreateGrievanceDialog(BuildContext context) async {
    _titleController.clear();
    _descriptionController.clear();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Dealer Grievance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
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
              await context.read<FPSOperationsProvider>().addGrievance(
                    title: _titleController.text,
                    description: _descriptionController.text,
                  );
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Color _statusColor(DealerGrievanceStatus status) {
    switch (status) {
      case DealerGrievanceStatus.open:
        return Colors.orange;
      case DealerGrievanceStatus.inProgress:
        return Colors.blue;
      case DealerGrievanceStatus.resolved:
        return Colors.green;
    }
  }
}
