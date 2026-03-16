import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fps_operations_provider.dart';
import '../../providers/family_member_provider.dart';
import '../../data/citizen_distribution_data.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/section_header.dart';

class EntitlementsScreen extends StatefulWidget {
  final bool showAppBar;

  const EntitlementsScreen({super.key, this.showAppBar = true});

  @override
  State<EntitlementsScreen> createState() => _EntitlementsScreenState();
}

class _EntitlementsScreenState extends State<EntitlementsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entitlements = _entitlementEntries(context);
    final summary = _summaryCounts(entitlements);
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('My Entitlements'),
              centerTitle: true,
              elevation: 2,
            )
          : null,
      body: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
              parent: _animationController, curve: Curves.easeInOut),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with User Info
              _buildHeaderCard(),
              const SizedBox(height: 24),

              // Summary Section
              _buildSummarySection(summary),
              const SizedBox(height: 24),

              // Your Entitlements Title
              const SectionHeader(title: 'Your Entitlements'),

              // Entitlements List
              _buildEntitlementsList(entitlements),
              const SizedBox(height: 24),

              // Allocation Details
              const SectionHeader(
                title: 'Allocation Period',
                icon: Icons.info_outline,
              ),
              _buildAllocationSection(),
              const SizedBox(height: 24),

              // Recent Transactions
              _buildRecentTransactions(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final name = (user?.name ?? '').trim().isNotEmpty
        ? user!.name.trim()
        : 'Citizen User';
    final category = (user?.category ?? '').trim().isNotEmpty
        ? user!.category!.trim()
        : 'PHH (BPL)';
    final initials = _initials(name);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.saffron, AppColors.saffron.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.saffron.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$category Card Holder',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Verified & Active',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'CU';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildSummarySection(_EntitlementSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            label: 'Total Items',
            value: summary.total.toString(),
            icon: Icons.inventory_2,
            color: AppColors.saffron,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            label: 'Collected',
            value: summary.collected.toString(),
            icon: Icons.check_circle,
            color: AppColors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            label: 'Pending',
            value: summary.pending.toString(),
            icon: Icons.pending_actions,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEntitlementsList(List<_EntitlementEntry> entitlements) {
    if (entitlements.isEmpty) {
      return const AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No entitlements yet',
        message: 'Entitlements will appear here once they are configured.',
      );
    }

    return Column(
      children: List.generate(
        entitlements.length,
        (index) => _buildEntitlementItem(entitlements[index]),
      ),
    );
  }

  Widget _buildEntitlementItem(_EntitlementEntry item) {
    final isCollected = item.collected;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCollected
            ? AppColors.green.withValues(alpha: 0.08)
            : Colors.orange.withValues(alpha: 0.08),
        border: Border.all(
          color: isCollected
              ? AppColors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.name} - ${item.quantity} ${item.unit}'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCollected
                        ? AppColors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    color: isCollected ? AppColors.green : Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.quantity} ${item.unit}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCollected
                        ? AppColors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCollected ? Icons.check_circle : Icons.schedule,
                        size: 14,
                        color: isCollected ? AppColors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCollected ? 'Collected' : 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCollected ? AppColors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationSection() {
    final history = [..._syncedHistory()]
      ..sort((a, b) => a.date.compareTo(b.date));
    final firstCollection = history.isEmpty ? null : history.first.date;
    final nextDistribution = _syncedUpcomingDistribution();
    final nextCollection = nextDistribution?.date;
    final rationShop = nextDistribution?.shopName ??
        (history.isNotEmpty ? history.last.shopName : 'Shyam Ration Store');

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAllocationRow('From', _formatDate(firstCollection)),
          const SizedBox(height: 8),
          _buildAllocationRow('To', _formatDate(nextCollection)),
          const SizedBox(height: 8),
          _buildAllocationRow('Ration Shop', rationShop),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.67,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.saffron),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '67% of entitlements collected',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    final records = [..._syncedHistory()]
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentRecords = records.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent Collections'),
        if (recentRecords.isEmpty)
          const AppEmptyState(
            icon: Icons.receipt_long,
            title: 'No recent collections',
            message: 'Your latest collections will appear here.',
          )
        else
          ...List.generate(recentRecords.length, (index) {
            final record = recentRecords[index];
            final firstItem = record.items.isEmpty ? null : record.items.first;
            final title = firstItem == null
                ? 'Ration collection'
                : '${firstItem.name} - ${firstItem.quantity} ${firstItem.unit}';
            final item = _buildTransactionItem(
              title,
              _formatDate(record.date),
              Icons.check_circle,
              AppColors.green,
            );
            if (index == recentRecords.length - 1) {
              return item;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: item,
            );
          }),
      ],
    );
  }

  Widget _buildTransactionItem(
    String title,
    String date,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
        ],
      ),
    );
  }

  List<_EntitlementEntry> _entitlementEntries(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ops = context.watch<FPSOperationsProvider>();
    final familyProvider = context.watch<FamilyMemberProvider>();
    final beneficiary = ops.beneficiaryForCitizen(auth.currentUser);
    final pending = beneficiary?.pendingItems ?? const <String>[];

    // Calculate family head count (including primary beneficiary)
    final headCount = familyProvider.familyMembers.length + 1;

    final editable = _parseEntitlements(
      pending.isEmpty ? _defaultEntitlementStrings(headCount) : pending,
    );
    final collectedNames =
        _collectedItemNamesThisMonth(ops, beneficiary?.cardNumber);

    return editable
        .map(
          (item) => _EntitlementEntry(
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            collected: collectedNames.contains(_normalizeName(item.name)),
            icon: _iconForItem(item.name),
          ),
        )
        .toList();
  }

  _EntitlementSummary _summaryCounts(List<_EntitlementEntry> entitlements) {
    final total = entitlements.length;
    final collected = entitlements.where((item) => item.collected).length;
    final pending = total - collected;
    return _EntitlementSummary(
        total: total, collected: collected, pending: pending);
  }

  List<String> _defaultEntitlementStrings([int headCount = 1]) {
    // Per-head allocation: 3kg rice, 2kg wheat, 1kg sugar, 1kg daal
    final rice = (3 * headCount).toString();
    final wheat = (2 * headCount).toString();
    final sugar = (1 * headCount).toString();
    final daal = (1 * headCount).toString();

    return [
      'Rice ${rice}kg',
      'Wheat ${wheat}kg',
      'Sugar ${sugar}kg',
      'Daal ${daal}kg',
    ];
  }

  List<_EditableEntitlement> _parseEntitlements(List<String> raw,
      {int headCount = 1}) {
    final items = <_EditableEntitlement>[];
    final pattern = RegExp(r'([\d.]+)\s*([a-zA-Z]+)?');

    for (final entry in raw) {
      final text = entry.trim();
      if (text.isEmpty) {
        continue;
      }
      final match = pattern.firstMatch(text);
      if (match == null) {
        items.add(_EditableEntitlement(
          name: text,
          quantity: '1',
          unit: _defaultUnitFor(text),
        ));
        continue;
      }

      final quantity = match.group(1) ?? '1';
      final unit = (match.group(2) ?? '').trim().isEmpty
          ? _defaultUnitFor(text)
          : match.group(2)!.trim();
      var name = text.substring(0, match.start).trim();
      if (name.isEmpty) {
        name = text.replaceAll(match.group(0)!, '').trim();
      }
      if (name.isEmpty) {
        name = 'Item';
      }
      items.add(_EditableEntitlement(
        name: name,
        quantity: quantity,
        unit: unit,
      ));
    }

    if (items.isEmpty) {
      return _defaultEntitlementStrings(headCount)
          .map(_parseSingleEntitlement)
          .toList();
    }
    return items;
  }

  _EditableEntitlement _parseSingleEntitlement(String raw) {
    final items = _parseEntitlements([raw]);
    return items.isEmpty
        ? const _EditableEntitlement(name: 'Item', quantity: '1', unit: 'kg')
        : items.first;
  }

  String _defaultUnitFor(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.contains('oil') || normalized.contains('kerosene')) {
      return 'L';
    }
    return 'kg';
  }

  Set<String> _collectedItemNamesThisMonth(
    FPSOperationsProvider ops,
    String? cardNumber,
  ) {
    if (cardNumber == null || cardNumber.trim().isEmpty) {
      return {};
    }
    final records = ops.distributionHistoryForCard(cardNumber);
    if (records.isEmpty) {
      return {};
    }
    final now = DateTime.now();
    final match = records.cast<DistributionRecord?>().firstWhere(
          (record) =>
              record != null &&
              record.date.year == now.year &&
              record.date.month == now.month,
          orElse: () => null,
        );
    if (match == null) {
      return {};
    }
    return match.items.map((item) => _normalizeName(item.name)).toSet();
  }

  String _normalizeName(String name) {
    return name.trim().toLowerCase();
  }

  IconData _iconForItem(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.contains('rice')) {
      return Icons.grain;
    }
    if (normalized.contains('wheat')) {
      return Icons.local_dining;
    }
    if (normalized.contains('sugar')) {
      return Icons.opacity;
    }
    if (normalized.contains('oil') || normalized.contains('kerosene')) {
      return Icons.local_gas_station;
    }
    if (normalized.contains('salt')) {
      return Icons.grain;
    }
    if (normalized.contains('dal') || normalized.contains('lentil')) {
      return Icons.circle;
    }
    return Icons.inventory_2;
  }

  List<DistributionRecord> _syncedHistory() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ops = Provider.of<FPSOperationsProvider>(context, listen: false);
    final beneficiary = ops.beneficiaryForCitizen(auth.currentUser);
    if (beneficiary == null) {
      return const [];
    }
    return ops.distributionHistoryForCard(beneficiary.cardNumber);
  }

  UpcomingDistribution? _syncedUpcomingDistribution() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ops = Provider.of<FPSOperationsProvider>(context, listen: false);
    final beneficiary = ops.beneficiaryForCitizen(auth.currentUser);
    if (beneficiary == null) {
      return null;
    }
    final upcoming = ops.upcomingDistributionForCard(beneficiary.cardNumber);
    return upcoming.isEmpty ? null : upcoming.first;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not available';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _EntitlementEntry {
  final String name;
  final String quantity;
  final String unit;
  final bool collected;
  final IconData icon;

  const _EntitlementEntry({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.collected,
    required this.icon,
  });
}

class _EntitlementSummary {
  final int total;
  final int collected;
  final int pending;

  const _EntitlementSummary({
    required this.total,
    required this.collected,
    required this.pending,
  });
}

class _EditableEntitlement {
  final String name;
  final String quantity;
  final String unit;

  const _EditableEntitlement({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  _EditableEntitlement copyWith({
    String? name,
    String? quantity,
    String? unit,
  }) {
    return _EditableEntitlement(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }
}
