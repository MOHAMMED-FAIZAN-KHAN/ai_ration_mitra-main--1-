import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/stock.dart';

class StockSummaryCard extends StatelessWidget {
  final StockSummary summary;
  const StockSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary.itemName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.saffron)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildStat('Total Stock', '${summary.totalStock} kg'), _buildStat('Remaining', '${summary.remaining} kg')]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildStat('Cleared Today', '${summary.clearedToday} kg'), _buildStat('Incoming', '${summary.incoming} kg')]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildStat('Missing', '${summary.missing} kg', color: Colors.red), _buildStat('Capacity', '${summary.totalCapacity} kg')]),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: summary.totalCapacity > 0 ? summary.totalStock / summary.totalCapacity : 0,
              backgroundColor: Colors.grey[300],
              color: AppColors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color color = Colors.black87}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}