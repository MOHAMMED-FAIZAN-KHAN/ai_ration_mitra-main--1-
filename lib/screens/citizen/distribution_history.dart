import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/constants/colors.dart';
import '../../data/citizen_distribution_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fps_operations_provider.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/section_header.dart';

class DistributionHistory extends StatefulWidget {
  const DistributionHistory({super.key});

  @override
  State<DistributionHistory> createState() => _DistributionHistoryState();
}

class _DistributionHistoryState extends State<DistributionHistory> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ops = context.watch<FPSOperationsProvider>();
    final beneficiary = ops.beneficiaryForCitizen(auth.currentUser);

    final appBar = AppBar(
      title: const Text('Ration Distribution History'),
      centerTitle: true,
    );

    if (ops.isLoading) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (beneficiary == null) {
      return Scaffold(
        appBar: appBar,
        body: const AppEmptyState(
          icon: Icons.person_outline,
          title: 'No beneficiary profile',
          message: 'Link a beneficiary profile to view distribution history.',
        ),
      );
    }

    final records = ops.distributionHistoryForCard(beneficiary.cardNumber);
    final displayRecords =
        records.isNotEmpty ? records : CitizenDistributionData.historyRecords;

    // Pre-compute O(1) lookup set — normalised to midnight.
    final rationTakenDays = {
      for (final r in displayRecords)
        DateTime(r.date.year, r.date.month, r.date.day)
    };

    final upcoming = ops.upcomingDistributionForCard(beneficiary.cardNumber);
    final displayUpcoming = upcoming.isNotEmpty
        ? upcoming
        : CitizenDistributionData.upcomingWithDaysRemaining();

    // Sort descending so records[0] is the most recent / nearest upcoming.
    final sortedRecords = [...displayRecords]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildCalendar(rationTakenDays, displayUpcoming),
          ),
          const SizedBox(height: 10),
          if (_selectedDay != null)
            _buildDayDetails(
              _selectedDay!,
              displayRecords,
              displayUpcoming,
            ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeader(title: 'History'),
          ),
          Expanded(child: _buildHistoryList(sortedRecords)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Calendar
  // ---------------------------------------------------------------------------

  Widget _buildCalendar(
    Set<DateTime> rationTakenDays,
    List<UpcomingDistribution> displayUpcoming,
  ) {
    // Build a set for upcoming days too — O(1) lookup.
    final upcomingDays = {
      for (final u in displayUpcoming)
        DateTime(u.date.year, u.date.month, u.date.day)
    };

    final now = DateTime.now();

    return TableCalendar(
      firstDay: DateTime(now.year, 1, 1),
      lastDay: DateTime(now.year, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, _) {
          final dayKey = DateTime(day.year, day.month, day.day);
          final taken = rationTakenDays.contains(dayKey);
          final isUpcoming = upcomingDays.contains(dayKey);

          if (!taken && !isUpcoming) return null;

          return Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: taken ? Colors.green : Colors.amber,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Day detail card
  // ---------------------------------------------------------------------------

  Widget _buildDayDetails(
    DateTime day,
    List<DistributionRecord> records,
    List<UpcomingDistribution> upcoming,
  ) {
    final record =
        records.firstWhereOrNull((r) => isSameDay(r.date, day));
    final upcomingItem =
        upcoming.firstWhereOrNull((u) => isSameDay(u.date, day));

    if (record != null) return _buildTakenCard(record);
    if (upcomingItem != null) return _buildUpcomingCard(upcomingItem);
    return _buildNoDistributionCard();
  }

  Widget _buildTakenCard(DistributionRecord record) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 10),
                  Text(
                    'Ration taken',
                    style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(record.time,
                      style: TextStyle(color: Colors.grey[700])),
                ],
              ),
              const SizedBox(height: 10),
              Text('Shop: ${record.shopName}',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 10),
              ...record.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: AppColors.saffron),
                      const SizedBox(width: 6),
                      Text('${item.name}: ',
                          style:
                              const TextStyle(fontWeight: FontWeight.w500)),
                      Text('${item.quantity}${item.unit}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingCard(UpcomingDistribution item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.amber[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.event_available, color: Colors.amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    'Upcoming ration scheduled at ${item.shopName}'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDistributionCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.orange[50],
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 10),
              Expanded(child: Text('No ration distribution on this day.')),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // History list
  // ---------------------------------------------------------------------------

  Widget _buildHistoryList(List<DistributionRecord> records) {
    if (records.isEmpty) {
      return const AppEmptyState(
        icon: Icons.receipt_long,
        title: 'No distribution history',
        message:
            'Your distribution records will appear here after collection.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: records.length,
      itemBuilder: (context, i) {
        final rec = records[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading:
                const Icon(Icons.event_available, color: Colors.green),
            title: Text(_dateFormat.format(rec.date)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shop: ${rec.shopName}'),
                Text('Status: ${rec.status.label}'),
                Wrap(
                  spacing: 8,
                  children: rec.items
                      .map((item) => Chip(
                            label: Text(
                                '${item.name} (${item.quantity}${item.unit})'),
                            backgroundColor: Colors.grey[100],
                          ))
                      .toList(),
                ),
              ],
            ),
            trailing:
                Text(rec.time, style: const TextStyle(fontSize: 12)),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Extension: replaces the silent-catch firstWhere anti-pattern.
// Move to a shared extensions file if used elsewhere.
// ---------------------------------------------------------------------------

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Extension on DistributionStatus — keeps label logic next to the enum.
// If you own the enum, move this getter directly onto it instead.
// ---------------------------------------------------------------------------

extension _DistributionStatusLabel on DistributionStatus {
  String get label => switch (this) {
        DistributionStatus.completed => 'Taken',
        DistributionStatus.pending => 'Pending',
        DistributionStatus.cancelled => 'Cancelled',
      };
}