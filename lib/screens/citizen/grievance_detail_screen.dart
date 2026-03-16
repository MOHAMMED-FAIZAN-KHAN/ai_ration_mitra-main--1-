import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/grievance.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grievance_provider.dart';
import '../../widgets/app_empty_state.dart';

class GrievanceDetailScreen extends StatefulWidget {
  final Grievance grievance;

  const GrievanceDetailScreen({super.key, required this.grievance});

  @override
  State<GrievanceDetailScreen> createState() => _GrievanceDetailScreenState();
}

class _GrievanceDetailScreenState extends State<GrievanceDetailScreen> {
  bool _hasMarkedViewed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasMarkedViewed) {
      return;
    }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = auth.currentUser?.type == UserType.admin;
    if (isAdmin) {
      Provider.of<GrievanceProvider>(context, listen: false)
          .markGrievanceAsViewed(widget.grievance.id);
    }
    _hasMarkedViewed = true;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final grievanceProvider = Provider.of<GrievanceProvider>(context);
    final isAdmin = auth.currentUser?.type == UserType.admin;
    final grievance =
        grievanceProvider.getGrievanceById(widget.grievance.id) ?? widget.grievance;
    final remarks = List<GrievanceRemark>.from(grievance.remarks)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grievance Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(_getStatusText(grievance.status),
                      style: const TextStyle(color: Colors.white)),
                  backgroundColor: _getStatusColor(grievance.status),
                ),
                Text('Submitted: ${_formatDate(grievance.createdAt)}',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            Text(grievance.title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Category: ${grievance.category.toString().split('.').last}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Text('Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(grievance.description),
            if (grievance.attachmentUrl != null) ...[
              const SizedBox(height: 16),
              const Text('Attachment:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  const Icon(Icons.attach_file),
                  const SizedBox(width: 8),
                  Text(grievance.attachmentUrl!),
                ],
              ),
            ],
            const Divider(height: 32),
            const Text('Remarks / Updates',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (remarks.isEmpty)
              const AppEmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'No remarks yet',
                message: 'Updates from support will appear here.',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: remarks.length,
                itemBuilder: (context, index) {
                  final remark = remarks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: remark.userType == 'admin'
                                    ? AppColors.saffron
                                    : Colors.green,
                                child: Icon(
                                  remark.userType == 'admin'
                                      ? Icons.admin_panel_settings
                                      : Icons.person,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(remark.userName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(_formatDate(remark.createdAt),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(remark.remark),
                        ],
                      ),
                    ),
                  );
                },
              ),
            if (isAdmin &&
                grievance.status != GrievanceStatus.resolved &&
                grievance.status != GrievanceStatus.rejected)
              _AdminActionPanel(grievance: grievance),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(GrievanceStatus status) {
    switch (status) {
      case GrievanceStatus.pending:
        return Colors.orange;
      case GrievanceStatus.inProgress:
        return Colors.blue;
      case GrievanceStatus.resolved:
        return Colors.green;
      case GrievanceStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusText(GrievanceStatus status) {
    switch (status) {
      case GrievanceStatus.pending:
        return 'Pending';
      case GrievanceStatus.inProgress:
        return 'In Progress';
      case GrievanceStatus.resolved:
        return 'Resolved';
      case GrievanceStatus.rejected:
        return 'Rejected';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Separate StatefulWidget to manage admin actions without using deprecated features
class _AdminActionPanel extends StatefulWidget {
  final Grievance grievance;

  const _AdminActionPanel({required this.grievance});

  @override
  State<_AdminActionPanel> createState() => _AdminActionPanelState();
}

class _AdminActionPanelState extends State<_AdminActionPanel> {
  final TextEditingController _remarkController = TextEditingController();
  GrievanceStatus? _selectedStatus;

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grievanceProvider = Provider.of<GrievanceProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Card(
      color: AppColors.saffron.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            // Use DropdownButton instead of DropdownButtonFormField to avoid deprecation
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Change Status',
                border: OutlineInputBorder(),
              ),
              child: DropdownButton<GrievanceStatus>(
                value: _selectedStatus ?? widget.grievance.status,
                isExpanded: true,
                underline: const SizedBox(),
                items: GrievanceStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_getStatusText(status)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedStatus = newValue;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarkController,
              decoration: const InputDecoration(
                labelText: 'Add Remark',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: grievanceProvider.isLoading
                      ? null
                      : () async {
                    if (_remarkController.text.isNotEmpty) {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final newStatus =
                          _selectedStatus ?? widget.grievance.status;

                      await grievanceProvider.updateGrievanceStatus(
                        widget.grievance.id,
                        newStatus,
                        _remarkController.text,
                        auth.currentUser!,
                      );

                      if (context.mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Remark added')),
                        );
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: grievanceProvider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Remark'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(GrievanceStatus status) {
    switch (status) {
      case GrievanceStatus.pending:
        return 'Pending';
      case GrievanceStatus.inProgress:
        return 'In Progress';
      case GrievanceStatus.resolved:
        return 'Resolved';
      case GrievanceStatus.rejected:
        return 'Rejected';
    }
  }
}
