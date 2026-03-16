import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/fps_operations.dart';
import '../../providers/fps_operations_provider.dart';

class DistributionPlannerScreen extends StatefulWidget {
  const DistributionPlannerScreen({super.key});

  @override
  State<DistributionPlannerScreen> createState() => _DistributionPlannerScreenState();
}

class _DistributionPlannerScreenState extends State<DistributionPlannerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ops = context.watch<FPSOperationsProvider>();
    final beneficiaries = ops.searchBeneficiaries(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Distribution Planner'),
      ),
      body: ops.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: const InputDecoration(
                      hintText: 'Search beneficiary name/card',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: beneficiaries.length,
                    itemBuilder: (context, index) {
                      final beneficiary = beneficiaries[index];
                      final completedThisMonth = _completedForCurrentMonth(
                        ops.distributionLogs,
                        beneficiary.cardNumber,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_outline),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${beneficiary.name} (${beneficiary.cardNumber})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Upcoming distribution: ${_formatDate(beneficiary.nextEligibleDate)}',
                              ),
                              const SizedBox(height: 6),
                              Text(
                                completedThisMonth
                                    ? 'Completed for current month'
                                    : 'Not completed for current month',
                                style: TextStyle(
                                  color:
                                      completedThisMonth ? Colors.green : Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _changeUpcomingDate(context, beneficiary.cardNumber),
                                      icon: const Icon(Icons.edit_calendar),
                                      label: const Text('Change Upcoming'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: completedThisMonth
                                          ? null
                                          : () => _markCompleted(context, beneficiary.cardNumber),
                                      icon: const Icon(Icons.check_circle_outline),
                                      label: const Text('Mark Completed'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _changeUpcomingDate(BuildContext context, String cardNumber) async {
    final ops = context.read<FPSOperationsProvider>();
    final beneficiary = ops.beneficiaryByCardNumber(cardNumber);
    if (beneficiary == null) {
      return;
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: beneficiary.nextEligibleDate,
      firstDate: DateTime.now().subtract(const Duration(days: 31)),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (!mounted || selected == null) {
      return;
    }

    final success = await ops.updateUpcomingDistributionDate(
      cardNumber: cardNumber,
      nextDate: selected,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Upcoming date updated' : (ops.error ?? 'Failed to update date'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _markCompleted(BuildContext context, String cardNumber) async {
    final ops = context.read<FPSOperationsProvider>();
    final success = await ops.distributeToBeneficiary(cardNumber);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Distribution marked completed' : (ops.error ?? 'Unable to mark completed'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  bool _completedForCurrentMonth(List<DistributionLogEntry> logs, String cardNumber) {
    final now = DateTime.now();
    return logs.any((log) {
      return log.cardNumber == cardNumber &&
          log.distributedAt.year == now.year &&
          log.distributedAt.month == now.month;
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
