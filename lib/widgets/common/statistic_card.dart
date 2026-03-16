import 'package:flutter/material.dart';

class StatisticCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const StatisticCard({super.key, required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [Icon(icon, color: color), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center)]),
      ),
    );
  }
}