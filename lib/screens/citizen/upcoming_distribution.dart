import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../data/citizen_distribution_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fps_operations_provider.dart';
import '../../widgets/app_empty_state.dart';

/// Upcoming distribution planner connected to Firestore.
/// Shows past distributions (green) and upcoming distributions (yellow).
class UpcomingDistributionPlanner extends StatefulWidget {
  final String title;
  final Color? primaryColor;
  final Function(DateTime)? onUpcomingDateTap;
  final Function(DistributionRecord)? onPastRecordTap;

  const UpcomingDistributionPlanner({
    super.key,
    this.title = 'Distribution Planner',
    this.primaryColor,
    this.onUpcomingDateTap,
    this.onPastRecordTap,
  });

  @override
  State<UpcomingDistributionPlanner> createState() =>
      _UpcomingDistributionPlannerState();
}

class _UpcomingDistributionPlannerState
    extends State<UpcomingDistributionPlanner> with TickerProviderStateMixin {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Cache today once — avoids repeated DateTime.now() calls per frame.
  final DateTime _today = DateTime.now();

  static final DateFormat _dayFormat = DateFormat('dd');
  static final DateFormat _monthFormat = DateFormat('MMM');
  static final DateFormat _fullDateFormat = DateFormat('dd MMMM yyyy');

  // Effective primary color, resolved once in build.
  Color get _primaryColor => widget.primaryColor ?? AppColors.saffron;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helper: normalise a DateTime to midnight for set lookups.
  // ---------------------------------------------------------------------------

  DateTime _toDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // ---------------------------------------------------------------------------
  // Helper: attach daysRemaining to upcoming distributions.
  // Belongs here (view-model concern) until the provider is refactored.
  // ---------------------------------------------------------------------------

  List<UpcomingDistribution> _withDaysRemaining(
      List<UpcomingDistribution> upcoming) {
    final today = _toDay(_today);
    return upcoming
        .map((d) => d.copyWith(daysRemaining: _toDay(d.date).difference(today).inDays))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Refresh helper
  // ---------------------------------------------------------------------------

  void _refresh() {
    setState(() {
      _fadeController
        ..reset()
        ..forward();
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ops = context.watch<FPSOperationsProvider>();
    final beneficiary = ops.beneficiaryForCitizen(auth.currentUser);

    final appBar = AppBar(
      title: Text(widget.title),
      centerTitle: true,
      backgroundColor: _primaryColor,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _refresh,
        ),
      ],
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
          message: 'Link a beneficiary profile to view distributions.',
        ),
      );
    }

    final records = ops.distributionHistoryForCard(beneficiary.cardNumber);
    final upcoming = ops.upcomingDistributionForCard(beneficiary.cardNumber);

    final displayRecords =
        records.isNotEmpty ? records : CitizenDistributionData.historyRecords;
    final displayUpcoming = upcoming.isNotEmpty
        ? upcoming
        : CitizenDistributionData.upcomingWithDaysRemaining();

    // Pre-compute sets so the calendar grid uses O(1) lookups.
    final pastDays = {for (final r in displayRecords) _toDay(r.date)};
    final upcomingDays = {for (final d in displayUpcoming) _toDay(d.date)};

    final upcomingWithDays = _withDaysRemaining(displayUpcoming);

    return Scaffold(
      appBar: appBar,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildCalendarSection(pastDays, upcomingDays),
            const SizedBox(height: 8),
            _buildLegend(),
            const SizedBox(height: 8),
            if (_selectedDay != null)
              _buildSelectedDayDetails(
                _selectedDay!,
                displayRecords,
                upcomingWithDays,
              ),
            const SizedBox(height: 8),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Upcoming', icon: Icon(Icons.upcoming)),
                        Tab(text: 'History', icon: Icon(Icons.history)),
                      ],
                      labelColor: Colors.orange,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.orange,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildUpcomingList(upcomingWithDays),
                          _buildHistoryList(displayRecords),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Calendar
  // ---------------------------------------------------------------------------

  Widget _buildCalendarSection(
    Set<DateTime> pastDays,
    Set<DateTime> upcomingDays,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMonthHeader(),
          _buildCalendarGrid(pastDays, upcomingDays),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
            onPressed: () => setState(() {
              _focusedDay =
                  DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
            }),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_focusedDay),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
            onPressed: () => setState(() {
              _focusedDay =
                  DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
    Set<DateTime> pastDays,
    Set<DateTime> upcomingDays,
  ) {
    final daysInMonth =
        DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final firstWeekday =
        DateTime(_focusedDay.year, _focusedDay.month, 1).weekday;
    // weekday: Mon=1 … Sun=7. Convert to 0-based column offset (Mon=0).
    final startOffset = firstWeekday - 1;
    final cellCount = startOffset + daysInMonth;

    const weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays
                .map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: cellCount,
            itemBuilder: (context, index) {
              if (index < startOffset) return const SizedBox.shrink();

              final dayNumber = index - startOffset + 1;
              final date =
                  DateTime(_focusedDay.year, _focusedDay.month, dayNumber);
              final dayKey = _toDay(date);

              final isPast = pastDays.contains(dayKey);
              final isUpcoming = upcomingDays.contains(dayKey);
              final isSelected =
                  _selectedDay != null && _toDay(_selectedDay!) == dayKey;
              final isToday = dayKey == _toDay(_today);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = date;
                    _fadeController
                      ..reset()
                      ..forward();
                  });
                  if (isUpcoming) widget.onUpcomingDateTap?.call(date);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? _primaryColor.withValues(alpha: 0.2)
                        : isPast
                            ? Colors.green.withValues(alpha: 0.1)
                            : isUpcoming
                                ? Colors.amber.withValues(alpha: 0.1)
                                : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? _primaryColor
                          : isPast
                              ? Colors.green
                              : isUpcoming
                                  ? Colors.amber
                                  : Colors.transparent,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            color: isToday
                                ? _primaryColor
                                : isPast
                                    ? Colors.green[700]
                                    : isUpcoming
                                        ? Colors.amber[800]
                                        : Colors.black87,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isPast || isUpcoming)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isPast ? Colors.green : Colors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Legend
  // ---------------------------------------------------------------------------

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.green, 'Past Distribution'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.amber, 'Upcoming'),
          const SizedBox(width: 16),
          _buildLegendItem(_primaryColor, 'Today'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Selected-day detail cards
  // ---------------------------------------------------------------------------

  Widget _buildSelectedDayDetails(
    DateTime day,
    List<DistributionRecord> records,
    List<UpcomingDistribution> upcomingWithDays,
  ) {
    final pastRecord = records.firstWhereOrNull((r) => _isSameDay(r.date, day));
    final upcoming =
        upcomingWithDays.firstWhereOrNull((d) => _isSameDay(d.date, day));

    if (pastRecord == null && upcoming == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          color: Colors.grey[50],
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.grey[200], shape: BoxShape.circle),
                  child: const Icon(Icons.info_outline, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_fullDateFormat.format(day),
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      const Text('No distribution scheduled',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (upcoming != null) return _buildUpcomingDetailCard(upcoming);
    return _buildPastDetailCard(pastRecord!);
  }

  Widget _buildUpcomingDetailCard(UpcomingDistribution upcoming) {
    final isToday = upcoming.daysRemaining == 0;
    final isTomorrow = upcoming.daysRemaining == 1;
    final statusText = isToday
        ? 'TODAY'
        : isTomorrow
            ? 'TOMORROW'
            : 'In ${upcoming.daysRemaining} days';
    final accentColor = isToday ? Colors.red : Colors.amber;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.amber[50],
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: accentColor, width: isToday ? 2 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration:
                        BoxDecoration(color: accentColor, shape: BoxShape.circle),
                    child: Icon(
                      isToday ? Icons.notifications_active : Icons.upcoming,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upcoming Distribution',
                          style: TextStyle(
                            color: isToday ? Colors.red : Colors.amber[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: isToday ? Colors.red : Colors.amber[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (upcoming.priority == DistributionPriority.high)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'HIGH PRIORITY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.store, 'Shop', upcoming.shopName),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.access_time, 'Time', upcoming.estimatedTime),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.calendar_today, 'Date',
                  _fullDateFormat.format(upcoming.date)),
              const SizedBox(height: 12),
              const Text('Expected Items:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...upcoming.estimatedItems.map((item) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.fiber_manual_record,
                            size: 8, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Text('${item.name}: ',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        Text('${item.quantity} ${item.unit}'),
                      ],
                    ),
                  )),
              if (isToday) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR Code at Shop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPastDetailCard(DistributionRecord record) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.green[50],
        elevation: 3,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Distribution Completed',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        Text(
                          _fullDateFormat.format(record.date),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record.time,
                      style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.store, 'Shop', record.shopName),
              const SizedBox(height: 8),
              _buildInfoRow(
                  Icons.person, 'Distributed by', record.distributedBy),
              const SizedBox(height: 8),
              _buildInfoRow(
                  Icons.people, 'Family Members', '${record.familyMembers}'),
              const SizedBox(height: 12),
              const Text('Items Received:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...record.items.map((item) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.fiber_manual_record,
                            size: 8, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Text('${item.name}: ',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        Text('${item.quantity} ${item.unit}'),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // List views
  // ---------------------------------------------------------------------------

  Widget _buildUpcomingList(List<UpcomingDistribution> upcoming) {
    if (upcoming.isEmpty) {
      return const AppEmptyState(
        icon: Icons.upcoming,
        title: 'No upcoming distributions',
        message: 'Upcoming schedules will appear here.',
      );
    }

    final sorted = [...upcoming]..sort((a, b) => a.date.compareTo(b.date));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final dist = sorted[index];
        final (statusText, statusColor) = _upcomingStatus(dist.daysRemaining);
        final isToday = dist.daysRemaining == 0;

        return GestureDetector(
          onTap: () => setState(() => _selectedDay = dist.date),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: isToday ? 4 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isToday ? Colors.red : Colors.transparent,
                width: isToday ? 2 : 0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildDateBadge(dist.date, statusColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Distribution at ${dist.shopName}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            _buildStatusChip(statusText, statusColor),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dist.estimatedItems.length} items expected',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(List<DistributionRecord> records) {
    if (records.isEmpty) {
      return const AppEmptyState(
        icon: Icons.history,
        title: 'No distribution history',
        message: 'Past distributions will appear here.',
      );
    }

    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final record = sorted[index];
        return GestureDetector(
          onTap: () {
            setState(() => _selectedDay = record.date);
            widget.onPastRecordTap?.call(record);
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildDateBadge(record.date, Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.shopName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          '${record.time} • ${record.items.length} items',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable sub-widgets
  // ---------------------------------------------------------------------------

  Widget _buildDateBadge(DateTime date, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _dayFormat.format(date),
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 16),
          ),
          Text(
            _monthFormat.format(date),
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pure helpers
  // ---------------------------------------------------------------------------

  /// Returns (label, color) for a given [daysRemaining] value.
  (String, Color) _upcomingStatus(int daysRemaining) => switch (daysRemaining) {
        0 => ('Today', Colors.red),
        1 => ('Tomorrow', Colors.orange),
        _ when daysRemaining < 0 => ('Overdue', Colors.red),
        _ => ('In $daysRemaining days', Colors.amber),
      };

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ---------------------------------------------------------------------------
// Iterable extension — avoids the silent-catch anti-pattern.
// Place in a shared extensions file if used elsewhere.
// ---------------------------------------------------------------------------

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}