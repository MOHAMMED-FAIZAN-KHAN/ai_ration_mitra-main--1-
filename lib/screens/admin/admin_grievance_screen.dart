import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../models/fps_operations.dart';
import '../../models/grievance.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fps_operations_provider.dart';
import '../../providers/grievance_provider.dart';
import '../../widgets/app_empty_state.dart';

class AdminGrievanceScreen extends StatefulWidget {
  const AdminGrievanceScreen({super.key});

  @override
  State<AdminGrievanceScreen> createState() => _AdminGrievanceScreenState();
}

class _AdminGrievanceScreenState extends State<AdminGrievanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    await context.read<GrievanceProvider>().loadAllGrievances();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final citizenProvider = context.watch<GrievanceProvider>();
    final fpsOps = context.watch<FPSOperationsProvider>();
    final isLoadingInbox = citizenProvider.isLoading || fpsOps.isLoading;
    final appBarForeground = Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onPrimary;
    final unselectedColor = appBarForeground.withValues(alpha: 0.72);

    final allItems = _allInboxItems(citizenProvider, fpsOps);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unified Grievance Inbox'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: appBarForeground,
          unselectedLabelColor: unselectedColor,
          indicatorColor: appBarForeground,
          indicatorWeight: 2.8,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Citizen'),
            Tab(text: 'FPS Dealer'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search by ID, title, name, description',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                        icon: const Icon(Icons.clear),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          _buildSummary(allItems),
          const SizedBox(height: 8),
          Expanded(
            child: isLoadingInbox
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(allItems),
                      _buildList(allItems
                          .where((item) => item.source == 'citizen')
                          .toList()),
                      _buildList(
                          allItems.where((item) => item.source == 'fps').toList()),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        backgroundColor: AppColors.saffron,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  List<_InboxItem> _allInboxItems(
    GrievanceProvider citizenProvider,
    FPSOperationsProvider fpsOps,
  ) {
    final citizen = citizenProvider.grievances.map((item) {
      return _InboxItem(
        id: item.id,
        source: 'citizen',
        userName: item.userName,
        title: item.title,
        description: item.description,
        createdAt: item.createdAt,
        statusText: _citizenStatusText(item.status),
        statusColor: _citizenStatusColor(item.status),
        citizenGrievance: item,
      );
    });

    final fps = fpsOps.grievances.map((item) {
      return _InboxItem(
        id: item.id,
        source: 'fps',
        userName: 'FPS Dealer',
        title: item.title,
        description: item.description,
        createdAt: item.createdAt,
        statusText: _fpsStatusText(item.status),
        statusColor: _fpsStatusColor(item.status),
        fpsGrievance: item,
      );
    });

    final merged = [...citizen, ...fps];
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (_searchQuery.isEmpty) {
      return merged;
    }
    final q = _searchQuery.toLowerCase();
    return merged.where((item) {
      return item.id.toLowerCase().contains(q) ||
          item.userName.toLowerCase().contains(q) ||
          item.title.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildSummary(List<_InboxItem> items) {
    final pending = items
        .where((item) =>
            item.statusText == 'Pending' ||
            item.statusText == 'Open' ||
            item.statusText == 'In Progress')
        .length;
    final resolved = items.where((item) => item.statusText == 'Resolved').length;
    final rejected = items.where((item) => item.statusText == 'Rejected').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(child: _SummaryCard(label: 'Pending', value: '$pending')),
          const SizedBox(width: 8),
          Expanded(child: _SummaryCard(label: 'Resolved', value: '$resolved')),
          const SizedBox(width: 8),
          Expanded(child: _SummaryCard(label: 'Rejected', value: '$rejected')),
        ],
      ),
    );
  }

  Widget _buildList(List<_InboxItem> items) {
    if (items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No grievances',
        message: 'New grievances will appear here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: item.source == 'citizen'
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.2),
              child: Icon(
                item.source == 'citizen' ? Icons.person : Icons.storefront,
                color: item.source == 'citizen' ? Colors.green : Colors.orange,
              ),
            ),
            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${item.source.toUpperCase()} • ${item.userName} • ${_formatDate(item.createdAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Chip(
              label: Text(
                item.statusText,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
              backgroundColor: item.statusColor,
            ),
            onTap: () {
              if (item.citizenGrievance != null) {
                _openCitizenActionSheet(item.citizenGrievance!);
                return;
              }
              if (item.fpsGrievance != null) {
                _openFpsActionSheet(item.fpsGrievance!);
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _openCitizenActionSheet(Grievance grievance) async {
    final auth = context.read<AuthProvider>();
    final admin = auth.currentUser;
    if (admin == null || admin.type != UserType.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login as admin to resolve grievances'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final remarkController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(grievance.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Citizen: ${grievance.userName}'),
              const SizedBox(height: 6),
              Text('Status: ${_citizenStatusText(grievance.status)}'),
              const SizedBox(height: 10),
              Text(grievance.description),
              const SizedBox(height: 12),
              TextField(
                controller: remarkController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Admin Remark',
                  hintText: 'Enter action note',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          OutlinedButton(
            onPressed: () async {
              await _applyCitizenUpdate(
                grievance: grievance,
                status: GrievanceStatus.inProgress,
                remark: remarkController.text.trim(),
                admin: admin,
              );
              if (mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('In Progress'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () async {
              await _applyCitizenUpdate(
                grievance: grievance,
                status: GrievanceStatus.resolved,
                remark: remarkController.text.trim(),
                admin: admin,
              );
              if (mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Resolve'),
          ),
          TextButton(
            onPressed: () async {
              await _applyCitizenUpdate(
                grievance: grievance,
                status: GrievanceStatus.rejected,
                remark: remarkController.text.trim(),
                admin: admin,
              );
              if (mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    remarkController.dispose();
  }

  Future<void> _applyCitizenUpdate({
    required Grievance grievance,
    required GrievanceStatus status,
    required String remark,
    required User admin,
  }) async {
    final effectiveRemark = remark.isEmpty ? _defaultCitizenRemark(status) : remark;
    await context.read<GrievanceProvider>().updateGrievanceStatus(
          grievance.id,
          status,
          effectiveRemark,
          admin,
        );
    if (!mounted) {
      return;
    }
    final provider = context.read<GrievanceProvider>();
    final success = provider.error == null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Citizen grievance updated to ${_citizenStatusText(status)}'
              : (provider.error ?? 'Failed to update grievance'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    if (success) {
      _load();
    }
  }

  String _defaultCitizenRemark(GrievanceStatus status) {
    switch (status) {
      case GrievanceStatus.pending:
        return 'Case moved to pending queue for review.';
      case GrievanceStatus.inProgress:
        return 'Issue acknowledged and work in progress.';
      case GrievanceStatus.resolved:
        return 'Issue resolved successfully.';
      case GrievanceStatus.rejected:
        return 'Request rejected after verification.';
    }
  }

  Future<void> _openFpsActionSheet(DealerGrievance grievance) async {
    final remarkController =
        TextEditingController(text: grievance.adminRemark ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(grievance.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${_fpsStatusText(grievance.status)}'),
            const SizedBox(height: 8),
            Text(grievance.description),
            const SizedBox(height: 12),
            TextField(
              controller: remarkController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Admin Remark',
                hintText: 'Enter action note for dealer',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          OutlinedButton(
            onPressed: () async {
              await context.read<FPSOperationsProvider>().updateGrievanceStatus(
                    grievance.id,
                    DealerGrievanceStatus.inProgress,
                    adminRemark: remarkController.text.trim(),
                  );
              Navigator.pop(dialogContext);
              _load();
            },
            child: const Text('In Progress'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () async {
              await context.read<FPSOperationsProvider>().updateGrievanceStatus(
                    grievance.id,
                    DealerGrievanceStatus.resolved,
                    adminRemark: remarkController.text.trim(),
                  );
              Navigator.pop(dialogContext);
              _load();
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
    remarkController.dispose();
  }

  Color _citizenStatusColor(GrievanceStatus status) {
    switch (status) {
      case GrievanceStatus.pending:
        return Colors.orange;
      case GrievanceStatus.inProgress:
        return Colors.blue;
      case GrievanceStatus.resolved:
        return AppColors.green;
      case GrievanceStatus.rejected:
        return Colors.red;
    }
  }

  String _citizenStatusText(GrievanceStatus status) {
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

  Color _fpsStatusColor(DealerGrievanceStatus status) {
    switch (status) {
      case DealerGrievanceStatus.open:
        return Colors.orange;
      case DealerGrievanceStatus.inProgress:
        return Colors.blue;
      case DealerGrievanceStatus.resolved:
        return AppColors.green;
    }
  }

  String _fpsStatusText(DealerGrievanceStatus status) {
    switch (status) {
      case DealerGrievanceStatus.open:
        return 'Open';
      case DealerGrievanceStatus.inProgress:
        return 'In Progress';
      case DealerGrievanceStatus.resolved:
        return 'Resolved';
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _InboxItem {
  final String id;
  final String source;
  final String userName;
  final String title;
  final String description;
  final DateTime createdAt;
  final String statusText;
  final Color statusColor;
  final Grievance? citizenGrievance;
  final DealerGrievance? fpsGrievance;

  const _InboxItem({
    required this.id,
    required this.source,
    required this.userName,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.statusText,
    required this.statusColor,
    this.citizenGrievance,
    this.fpsGrievance,
  });
}
