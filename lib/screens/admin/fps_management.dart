import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../models/stock.dart';
import '../../providers/admin_stock_provider.dart';
import '../../widgets/app_empty_state.dart';

class FPSManagement extends StatefulWidget {
  const FPSManagement({super.key});

  @override
  State<FPSManagement> createState() => _FPSManagementState();
}

class _FPSManagementState extends State<FPSManagement> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminStockProvider>().loadAllStock();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminStockProvider>();
    final grouped = _groupByStore(provider.stockItems);
    final visible = grouped.where((shop) {
      final q = _search.toLowerCase();
      return q.isEmpty ||
          shop.name.toLowerCase().contains(q) ||
          shop.id.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FPS Management'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: TextField(
                    onChanged: (value) => setState(() => _search = value.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by FPS ID or shop name',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.storefront,
                          title: 'No FPS stores',
                          message: 'Try a different search or clear the filter.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final shop = visible[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _shopStatusColor(shop.status).withValues(alpha: 0.18),
                                  child: Icon(
                                    Icons.storefront,
                                    color: _shopStatusColor(shop.status),
                                  ),
                                ),
                                title: Text(shop.name),
                                subtitle: Text(
                                  '${shop.id} • Critical: ${shop.criticalCount} • Low: ${shop.lowCount}',
                                ),
                                trailing: Chip(
                                  label: Text(
                                    shop.status,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 11),
                                  ),
                                  backgroundColor: _shopStatusColor(shop.status),
                                ),
                                onTap: () => _openShopActions(shop),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  List<_ShopSummary> _groupByStore(List<StockItem> items) {
    final map = <String, List<StockItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.fpsId, () => []).add(item);
    }

    return map.entries.map((entry) {
      final stocks = entry.value;
      final critical =
          stocks.where((item) => item.status == StockStatus.critical).length;
      final low = stocks.where((item) => item.status == StockStatus.low).length;
      final status = critical > 0
          ? 'Critical'
          : low > 0
              ? 'Low'
              : 'Good';
      return _ShopSummary(
        id: entry.key,
        name: stocks.first.fpsName,
        status: status,
        criticalCount: critical,
        lowCount: low,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Color _shopStatusColor(String status) {
    switch (status) {
      case 'Critical':
        return Colors.red;
      case 'Low':
        return Colors.orange;
      default:
        return AppColors.green;
    }
  }

  Future<void> _openShopActions(_ShopSummary shop) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Wrap(
              children: [
                ListTile(
                  title: Text(shop.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(shop.id),
                ),
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('View Store Stock'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(this.context, '/admin/stock');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: const Text('Raise Inspection Alert'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Inspection alert created for ${shop.name}.')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShopSummary {
  final String id;
  final String name;
  final String status;
  final int criticalCount;
  final int lowCount;

  const _ShopSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.criticalCount,
    required this.lowCount,
  });
}
