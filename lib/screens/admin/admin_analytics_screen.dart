import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/colors.dart';
import '../../providers/admin_analytics_provider.dart';
import '../../widgets/common/loading_indicator.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminAnalyticsProvider>(context, listen: false).loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminAnalyticsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadAnalytics(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const LoadingIndicator()
          : provider.error != null
              ? Center(child: Text('Error: ${provider.error}'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview KPIs
                      _buildKPISection(provider),
                      const SizedBox(height: 24),

                      // User Analytics
                      _buildUserSection(provider),
                      const SizedBox(height: 24),

                      // Grievance Analytics
                      _buildGrievanceSection(provider),
                      const SizedBox(height: 24),

                      // Booking Analytics
                      _buildBookingSection(provider),
                      const SizedBox(height: 24),

                      // Stock Analytics
                      _buildStockSection(provider),
                      const SizedBox(height: 24),

                      // Distribution Analytics
                      _buildDistributionSection(provider),
                    ],
                  ),
                ),
    );
  }

  Widget _buildKPISection(AdminAnalyticsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildKPI('Total Users', provider.totalUsers.toString(), Icons.people),
                _buildKPI('Total Grievances', provider.totalGrievances.toString(), Icons.feedback),
                _buildKPI('Total Bookings', provider.totalBookings.toString(), Icons.calendar_today),
                _buildKPI('Total FPS Stores', '0', Icons.store),
                _buildKPI('Distribution Rate', '${(provider.distributionCompletionRate * 100).toStringAsFixed(1)}%', Icons.trending_up),
                _buildKPI('Resolution Rate', '${(provider.resolutionRate * 100).toStringAsFixed(1)}%', Icons.check_circle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPI(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.saffron, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildUserSection(AdminAnalyticsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPieChart(
                    'Users by Role',
                    {
                      'Citizens': provider.totalCitizens.toDouble(),
                      'FPS Dealers': provider.totalFPSDealers.toDouble(),
                      'Admins': provider.totalAdmins.toDouble(),
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBarChart(
                    'New Users per Month',
                    provider.newUsersPerMonth.map((k, v) => MapEntry(k, v.toDouble())),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrievanceSection(AdminAnalyticsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Grievance Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPieChart(
                    'By Status',
                    provider.grievancesByStatus.map((k, v) => MapEntry(k, v.toDouble())),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPieChart(
                    'By Category',
                    provider.grievancesByCategory.map((k, v) => MapEntry(k, v.toDouble())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Avg. Resolution', '${provider.avgResolutionDays.toStringAsFixed(1)} days')),
                Expanded(child: _buildStatCard('Resolution Rate', '${(provider.resolutionRate * 100).toStringAsFixed(1)}%')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSection(AdminAnalyticsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Booking Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPieChart(
                    'By Status',
                    provider.bookingsByStatus.map((k, v) => MapEntry(k, v.toDouble())),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPieChart(
                    'By Time Slot',
                    provider.bookingsByTimeSlot.map((k, v) => MapEntry(k, v.toDouble())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBarChart(
              'Bookings per Month',
              provider.bookingsPerMonth.map((k, v) => MapEntry(k, v.toDouble())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockSection(AdminAnalyticsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stock Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBarChart('Total Stock (kg)', provider.totalStockByCommodity),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPieChart(
                    'Stock Alerts',
                    {
                      'Low': provider.lowStockAlerts.toDouble(),
                      'Critical': provider.criticalStockAlerts.toDouble(),
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildBarChart('Incoming Stock (kg)', provider.incomingStock)),
                const SizedBox(width: 16),
                Expanded(child: _buildBarChart('Outgoing Stock (kg)', provider.outgoingStock)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionSection(AdminAnalyticsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Distribution Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildHorizontalBarChart('FPS Completion Rates', provider.fpsCompletionRates),
          ],
        ),
      ),
    );
  }

  // Helper chart widgets
  Widget _buildPieChart(String title, Map<String, double> data) {
    if (data.isEmpty) return const SizedBox();

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.teal];
    int index = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: PieChart(
            PieChartData(
              sections: data.entries.map((entry) {
                final color = colors[index % colors.length];
                index++;
                return PieChartSectionData(
                  value: entry.value,
                  title: entry.value > 0 ? '${entry.key}\n${entry.value}' : '',
                  color: color,
                  radius: 60,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(String title, Map<String, double> data) {
    if (data.isEmpty) return const SizedBox();

    final labels = data.keys.toList();
    final values = data.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: BarChart(
            BarChartData(
              barGroups: List.generate(values.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [BarChartRodData(toY: values[index], color: AppColors.saffron)],
                );
              }),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < labels.length) {
                        return Text(labels[index], style: const TextStyle(fontSize: 10));
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalBarChart(String title, Map<String, double> data) {
    if (data.isEmpty) return const SizedBox();

    final entries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 100, child: Text(entry.key, style: const TextStyle(fontSize: 12))),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: entry.value,
                        backgroundColor: Colors.grey[200],
                        color: AppColors.saffron,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(entry.value * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}