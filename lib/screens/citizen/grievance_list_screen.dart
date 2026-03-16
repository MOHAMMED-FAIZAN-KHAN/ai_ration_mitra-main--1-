import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/grievance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/grievance.dart';
import 'grievance_form_screen.dart';
import 'grievance_detail_screen.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/app_empty_state.dart';

class GrievanceListScreen extends StatefulWidget {
  const GrievanceListScreen({super.key});

  @override
  State<GrievanceListScreen> createState() => _GrievanceListScreenState();
}

class _GrievanceListScreenState extends State<GrievanceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  GrievanceStatus? _statusFilter;
  bool _didRequestInitialLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserGrievances();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserGrievances() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    await Provider.of<GrievanceProvider>(context, listen: false)
        .loadUserGrievances(userId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final grievanceProvider = Provider.of<GrievanceProvider>(context);
    final currentUser = auth.currentUser;

    if ((!auth.isInitialized || auth.isLoading) && currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Grievances')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (currentUser != null && !_didRequestInitialLoad) {
      _didRequestInitialLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadUserGrievances();
      });
    }

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Grievances')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 56),
              const SizedBox(height: 10),
              const Text('Please login to view grievances'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (grievanceProvider.isLoading && grievanceProvider.grievances.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Grievances')),
        body: const LoadingIndicator(),
      );
    }

    final allUserGrievances = grievanceProvider.getUserGrievances(currentUser.id);
    final userGrievances = allUserGrievances.where((grievance) {
      if (_statusFilter != null && grievance.status != _statusFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        return grievance.title.toLowerCase().contains(query) ||
            grievance.description.toLowerCase().contains(query) ||
            grievance.id.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Grievances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GrievanceFormScreen()),
            ).then((_) => _loadUserGrievances()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserGrievances,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserGrievances,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildSummaryRow(allUserGrievances),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, ID or description',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _statusFilter == null,
                    onSelected: (_) => setState(() => _statusFilter = null),
                  ),
                  const SizedBox(width: 8),
                  ...GrievanceStatus.values.map((status) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_getStatusText(status)),
                        selected: _statusFilter == status,
                        onSelected: (_) => setState(() => _statusFilter = status),
                      ),
                    );
                  }),
                ],
              ),
            ),
            if (grievanceProvider.hasError) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        grievanceProvider.error ?? 'Something went wrong',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    IconButton(
                      onPressed: grievanceProvider.clearError,
                      icon: const Icon(Icons.close),
                      color: Colors.red.shade700,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (userGrievances.isEmpty)
              _buildEmptyState(allUserGrievances.isEmpty)
            else
              ...userGrievances.map((grievance) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _getStatusColor(grievance.status).withValues(alpha: 0.15),
                      child: Icon(
                        _getStatusIcon(grievance.status),
                        color: _getStatusColor(grievance.status),
                      ),
                    ),
                    title: Text(
                      grievance.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${grievance.category.name.toUpperCase()} • ${_formatDate(grievance.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Chip(
                      label: Text(
                        _getStatusText(grievance.status),
                        style:
                            const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                      backgroundColor: _getStatusColor(grievance.status),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GrievanceDetailScreen(grievance: grievance),
                      ),
                    ).then((_) => _loadUserGrievances()),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(List<Grievance> grievances) {
    final pending =
        grievances.where((item) => item.status == GrievanceStatus.pending).length;
    final inProgress = grievances
        .where((item) => item.status == GrievanceStatus.inProgress)
        .length;
    final resolved =
        grievances.where((item) => item.status == GrievanceStatus.resolved).length;

    return Row(
      children: [
        Expanded(child: _SummaryTile(label: 'Pending', value: pending.toString())),
        const SizedBox(width: 8),
        Expanded(
            child:
                _SummaryTile(label: 'In Progress', value: inProgress.toString())),
        const SizedBox(width: 8),
        Expanded(
            child: _SummaryTile(label: 'Resolved', value: resolved.toString())),
      ],
    );
  }

  Widget _buildEmptyState(bool noTicketsYet) {
    return AppEmptyState(
      icon: Icons.feedback_outlined,
      title: noTicketsYet ? 'No grievances yet' : 'No matching grievances',
      message: noTicketsYet
          ? 'Submit a grievance to track it here.'
          : 'Try adjusting your search or filters.',
      action: noTicketsYet
          ? ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GrievanceFormScreen()),
              ).then((_) => _loadUserGrievances()),
              child: const Text('Submit Grievance'),
            )
          : null,
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

  IconData _getStatusIcon(GrievanceStatus status) {
    switch (status) {
      case GrievanceStatus.pending:
        return Icons.hourglass_empty;
      case GrievanceStatus.inProgress:
        return Icons.autorenew;
      case GrievanceStatus.resolved:
        return Icons.check_circle;
      case GrievanceStatus.rejected:
        return Icons.cancel;
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
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
