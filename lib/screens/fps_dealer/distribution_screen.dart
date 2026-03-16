import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/fps_operations_provider.dart';
import '../../widgets/app_empty_state.dart';

class DistributionScreen extends StatefulWidget {
  const DistributionScreen({super.key});

  @override
  State<DistributionScreen> createState() => _DistributionScreenState();
}

class _DistributionScreenState extends State<DistributionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ops = context.watch<FPSOperationsProvider>();

    if (ops.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Distribution Operations')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final query = _search.trim();
    final beneficiaries = ops.searchBeneficiaries(query);
    final eligibleCount = beneficiaries.where((b) => b.isEligibleToday).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Distribution Operations')),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            _buildSearchBar(query),
            _buildStatRow(
                queueCount: beneficiaries.length, eligibleCount: eligibleCount),
            const TabBar(
              tabs: [Tab(text: 'Queue'), Tab(text: 'Logs')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildQueueTab(context, beneficiaries, query),
                  _buildLogsTab(ops),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search bar
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar(String query) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Search by beneficiary name or card number',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stat chips row
  // ---------------------------------------------------------------------------

  Widget _buildStatRow({required int queueCount, required int eligibleCount}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              icon: Icons.groups_2_outlined,
              label: 'Queue',
              value: '$queueCount',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatChip(
              icon: Icons.check_circle_outline,
              label: 'Eligible',
              value: '$eligibleCount',
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Queue tab
  // ---------------------------------------------------------------------------

  Widget _buildQueueTab(
    BuildContext context,
    List<dynamic> beneficiaries,
    String query,
  ) {
    if (beneficiaries.isEmpty) {
      return _EmptyQueueState(query: query);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: beneficiaries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final b = beneficiaries[index];
        return _QueueCard(
          beneficiary: b,
          eligible: b.isEligibleToday as bool,
          onDistribute: () => _distribute(context, b.cardNumber as String),
          dateFormat: _dateFormat,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Logs tab
  // ---------------------------------------------------------------------------

  Widget _buildLogsTab(FPSOperationsProvider ops) {
    final logs = ops.distributionLogs;

    if (logs.isEmpty) {
      return const AppEmptyState(
        icon: Icons.receipt_long,
        title: 'No distribution logs',
        message: 'Completed distributions will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final log = logs[index];
        final itemsSummary = log.items.entries
            .map((e) => '${e.key} ${e.value.toStringAsFixed(0)}')
            .join(', ');

        return Card(
          child: ListTile(
            leading:
                const Icon(Icons.assignment_turned_in, color: Colors.green),
            title: Text('${log.beneficiaryName} (${log.cardNumber})'),
            subtitle: Text(
              '${_dateTimeFormat.format(log.distributedAt)}\n$itemsSummary',
            ),
            isThreeLine: true,
            trailing: Text(
              log.status,
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Distribute action
  // ---------------------------------------------------------------------------

  Future<void> _distribute(BuildContext context, String cardNumber) async {
    final ops = context.read<FPSOperationsProvider>();
    final success = await ops.distributeToBeneficiary(cardNumber);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Distribution completed successfully'
              : (ops.error ?? 'Distribution failed'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}

// =============================================================================
// Private sub-widgets — extracted to keep build methods readable.
// =============================================================================

/// Stat chip used in the queue summary row.
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Card representing a single beneficiary in the queue.
class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.beneficiary,
    required this.eligible,
    required this.onDistribute,
    required this.dateFormat,
  });

  final dynamic beneficiary;
  final bool eligible;
  final VoidCallback onDistribute;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final statusColor = eligible ? Colors.green : Colors.orange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: Icon(
                eligible ? Icons.check_circle : Icons.schedule,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    beneficiary.name as String,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Card: ${beneficiary.cardNumber}  |  ${beneficiary.category}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  _EligibilityBadge(
                    eligible: eligible,
                    nextEligibleDate: beneficiary.nextEligibleDate as DateTime,
                    dateFormat: dateFormat,
                    color: statusColor,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: eligible ? onDistribute : null,
                child: const Text('Distribute'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill badge showing eligibility status inside a queue card.
class _EligibilityBadge extends StatelessWidget {
  const _EligibilityBadge({
    required this.eligible,
    required this.nextEligibleDate,
    required this.dateFormat,
    required this.color,
  });

  final bool eligible;
  final DateTime nextEligibleDate;
  final DateFormat dateFormat;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = eligible
        ? 'Eligible for distribution today'
        : 'Next eligible on ${dateFormat.format(nextEligibleDate)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

/// Empty state shown when the queue search returns no results.
class _EmptyQueueState extends StatelessWidget {
  const _EmptyQueueState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.isNotEmpty;
    return AppEmptyState(
      icon: hasQuery ? Icons.search_off : Icons.inbox_outlined,
      title: hasQuery ? 'No results' : 'Queue is empty',
      message: hasQuery
          ? 'No beneficiary found for "$query". Try a card number like RC1001.'
          : 'No beneficiaries are waiting for distribution.',
    );
  }
}
