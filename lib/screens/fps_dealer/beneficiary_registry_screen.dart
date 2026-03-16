// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/fps_operations.dart';
import '../../providers/fps_operations_provider.dart';
import '../../widgets/app_empty_state.dart';

class BeneficiaryRegistryScreen extends StatefulWidget {
  const BeneficiaryRegistryScreen({super.key});

  @override
  State<BeneficiaryRegistryScreen> createState() =>
      _BeneficiaryRegistryScreenState();
}

class _BeneficiaryRegistryScreenState extends State<BeneficiaryRegistryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ops = context.watch<FPSOperationsProvider>();
    final list = ops.searchBeneficiaries(_search);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Beneficiary Registry',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.saffron,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: () {
              // You can add filter functionality here if needed
            },
            tooltip: 'Filter',
          ),
        ],
      ),
      body: ops.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.saffron),
              ),
            )
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beneficiaries',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: (value) => setState(() => _search = value),
                          decoration: InputDecoration(
                            hintText: 'Search by name, UID, or card number',
                            prefixIcon: const Icon(Icons.search,
                                color: AppColors.saffron),
                            suffixIcon: _search.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _search = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: AppColors.saffron, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: list.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.people_outline,
                          title: 'No beneficiaries found',
                          message:
                              'Try adjusting your search or clear the filter.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final beneficiary = list[index];
                            final eligible = beneficiary.isEligibleToday;
                            final uidLabel =
                                (beneficiary.uid ?? '').trim().isEmpty
                                    ? ''
                                    : 'UID: ${beneficiary.uid}';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: eligible
                                                  ? Colors.green
                                                      .withOpacity(0.1)
                                                  : Colors.orange
                                                      .withOpacity(0.1),
                                            ),
                                            child: Icon(
                                              eligible
                                                  ? Icons.verified
                                                  : Icons.schedule,
                                              color: eligible
                                                  ? Colors.green
                                                  : Colors.orange,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        beneficiary.name,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: eligible
                                                            ? Colors.green
                                                                .withOpacity(
                                                                    0.1)
                                                            : Colors.orange
                                                                .withOpacity(
                                                                    0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        eligible
                                                            ? 'Eligible'
                                                            : 'Pending',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: eligible
                                                              ? Colors
                                                                  .green[700]
                                                              : Colors
                                                                  .orange[700],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Card: ${beneficiary.cardNumber}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Category: ${beneficiary.category} | Family: ${beneficiary.familyMembers}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                if (uidLabel.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    uidLabel,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[500],
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!eligible) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: Colors.blue[700],
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Next eligible: ${_formatDate(beneficiary.nextEligibleDate)}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.blue[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          _buildActionButton(
                                            icon: Icons.edit_note_outlined,
                                            label: 'Edit',
                                            color: Colors.blue,
                                            onPressed: () =>
                                                _openEntitlementEditor(
                                              context,
                                              ops,
                                              beneficiary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildActionButton(
                                            icon: Icons.event_available,
                                            label: 'Plan',
                                            color: Colors.purple,
                                            onPressed: () => _pickUpcomingDate(
                                              context,
                                              ops,
                                              beneficiary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildActionButton(
                                            icon: Icons.local_shipping_outlined,
                                            label: 'Distribute',
                                            color: eligible
                                                ? Colors.green
                                                : Colors.grey,
                                            onPressed: eligible
                                                ? () async {
                                                    final success = await ops
                                                        .distributeToBeneficiary(
                                                            beneficiary
                                                                .cardNumber);
                                                    if (context.mounted) {
                                                      _showSnackBar(
                                                        context,
                                                        success
                                                            ? 'Distribution completed for ${beneficiary.cardNumber}'
                                                            : (ops.error ??
                                                                'Distribution failed'),
                                                        success,
                                                      );
                                                    }
                                                  }
                                                : () {
                                                    _showSnackBar(
                                                      context,
                                                      'Beneficiary is not eligible yet',
                                                      false,
                                                    );
                                                  },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _pickUpcomingDate(
    BuildContext context,
    FPSOperationsProvider ops,
    BeneficiaryRecord beneficiary,
  ) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: beneficiary.nextEligibleDate,
      firstDate: DateTime.now().subtract(const Duration(days: 31)),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.saffron,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) return;

    final success = await ops.updateUpcomingDistributionDate(
      cardNumber: beneficiary.cardNumber,
      nextDate: selected,
    );

    if (!context.mounted) return;

    _showSnackBar(
      context,
      success
          ? 'Upcoming date updated'
          : (ops.error ?? 'Failed to update date'),
      success,
    );
  }

  Future<void> _openEntitlementEditor(
    BuildContext context,
    FPSOperationsProvider ops,
    BeneficiaryRecord beneficiary,
  ) async {
    final initialItems = _parseEntitlements(
      beneficiary.pendingItems.isEmpty
          ? _defaultEntitlementStrings()
          : beneficiary.pendingItems,
    );
    final units = ['kg', 'L', 'unit'];
    final updated = await showModalBottomSheet<List<_EditableEntitlement>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final items = List<_EditableEntitlement>.from(initialItems);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 12,
                    bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Entitlements',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: item.name,
                                          decoration: InputDecoration(
                                            labelText: 'Item name',
                                            labelStyle: TextStyle(
                                                color: Colors.grey[600]),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                  color: AppColors.saffron),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setModalState(() {
                                              items[index] = item.copyWith(
                                                  name: value.trim());
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          onPressed: () {
                                            setModalState(() {
                                              items.removeAt(index);
                                            });
                                          },
                                          icon: const Icon(Icons.delete_outline,
                                              size: 20),
                                          color: Colors.red,
                                          tooltip: 'Remove',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          initialValue: item.quantity,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Quantity',
                                            labelStyle: TextStyle(
                                                color: Colors.grey[600]),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                  color: AppColors.saffron),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setModalState(() {
                                              items[index] = item.copyWith(
                                                quantity: value.trim(),
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.grey[300]!),
                                          ),
                                          child:
                                              DropdownButtonFormField<String>(
                                            initialValue: units.contains(item.unit)
                                                ? item.unit
                                                : units.first,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                            ),
                                            items: units
                                                .map(
                                                  (unit) => DropdownMenuItem(
                                                    value: unit,
                                                    child: Text(unit),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (value) {
                                              if (value == null) return;
                                              setModalState(() {
                                                items[index] =
                                                    item.copyWith(unit: value);
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  items.add(const _EditableEntitlement(
                                    name: '',
                                    quantity: '1',
                                    unit: 'kg',
                                  ));
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Item'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(sheetContext, items),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.saffron,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (updated == null) return;

    final formatted = updated
        .where((item) => item.name.trim().isNotEmpty)
        .map(_formatEntitlementString)
        .toList();
    final ok = await ops.updateBeneficiaryEntitlements(
      cardNumber: beneficiary.cardNumber,
      pendingItems: formatted,
    );

    if (!context.mounted) return;

    _showSnackBar(
      context,
      ok
          ? 'Entitlements updated successfully'
          : (ops.error ?? 'Failed to update'),
      ok,
    );
  }

  List<String> _defaultEntitlementStrings() {
    return const ['Rice 3kg', 'Wheat 5kg', 'Sugar 1kg'];
  }

  List<_EditableEntitlement> _parseEntitlements(List<String> raw) {
    final items = <_EditableEntitlement>[];
    final pattern = RegExp(r'([\d.]+)\s*([a-zA-Z]+)?');

    for (final entry in raw) {
      final text = entry.trim();
      if (text.isEmpty) continue;

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
      return _defaultEntitlementStrings().map(_parseSingleEntitlement).toList();
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

  String _formatEntitlementString(_EditableEntitlement item) {
    final qty = item.quantity.trim().isEmpty ? '1' : item.quantity.trim();
    final unit = item.unit.trim().isEmpty
        ? _defaultUnitFor(item.name)
        : item.unit.trim();
    return '${item.name.trim()} $qty$unit';
  }
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
