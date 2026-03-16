class CitizenDistributionData {
  static final List<DistributionRecord> historyRecords = [
    DistributionRecord(
      id: '1',
      date: DateTime(2026, 1, 18),
      items: [
        DistributionItem(name: 'Wheat', quantity: '5', unit: 'kg'),
        DistributionItem(name: 'Rice', quantity: '3', unit: 'kg'),
        DistributionItem(name: 'Sugar', quantity: '1', unit: 'kg'),
      ],
      status: DistributionStatus.completed,
      shopName: 'Shyam Ration Store',
      time: '10:30 AM',
      distributedBy: 'Ram Kumar',
      familyMembers: 4,
    ),
    DistributionRecord(
      id: '2',
      date: DateTime(2026, 2, 14),
      items: [
        DistributionItem(name: 'Wheat', quantity: '5', unit: 'kg'),
        DistributionItem(name: 'Rice', quantity: '3', unit: 'kg'),
        DistributionItem(name: 'Sugar', quantity: '1', unit: 'kg'),
      ],
      status: DistributionStatus.completed,
      shopName: 'Shyam Ration Store',
      time: '11:00 AM',
      distributedBy: 'Ram Kumar',
      familyMembers: 4,
    ),
  ];

  static final List<UpcomingDistribution> upcomingRecords = [
    UpcomingDistribution(
      id: 'u1',
      date: DateTime(2026, 3, 19),
      estimatedItems: [
        DistributionItem(name: 'Wheat', quantity: '5', unit: 'kg'),
        DistributionItem(name: 'Rice', quantity: '3', unit: 'kg'),
        DistributionItem(name: 'Sugar', quantity: '1', unit: 'kg'),
      ],
      shopName: 'Shyam Ration Store',
      estimatedTime: '10:00 AM - 04:00 PM',
      priority: DistributionPriority.normal,
      daysRemaining: 0,
    ),
    UpcomingDistribution(
      id: 'u2',
      date: DateTime(2026, 4, 19),
      estimatedItems: [
        DistributionItem(name: 'Wheat', quantity: '5', unit: 'kg'),
        DistributionItem(name: 'Rice', quantity: '3', unit: 'kg'),
        DistributionItem(name: 'Sugar', quantity: '1', unit: 'kg'),
      ],
      shopName: 'Shyam Ration Store',
      estimatedTime: '10:00 AM - 04:00 PM',
      priority: DistributionPriority.normal,
      daysRemaining: 0,
    ),
  ];

  static Set<DateTime> get historyDates => historyRecords
      .map((record) => DateTime(record.date.year, record.date.month, record.date.day))
      .toSet();

  static Set<DateTime> get upcomingDates => upcomingRecords
      .map((record) => DateTime(record.date.year, record.date.month, record.date.day))
      .toSet();

  static List<UpcomingDistribution> upcomingWithDaysRemaining([DateTime? now]) {
    final current = now ?? DateTime.now();
    return upcomingRecords
        .map((dist) => dist.copyWith(daysRemaining: _daysFromToday(dist.date, current)))
        .toList();
  }

  static UpcomingDistribution? nextUpcomingDistribution([DateTime? now]) {
    final current = now ?? DateTime.now();
    final candidates = upcomingWithDaysRemaining(current)
        .where((dist) => dist.daysRemaining >= 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (candidates.isEmpty) {
      return null;
    }
    return candidates.first;
  }

  static int _daysFromToday(DateTime target, DateTime now) {
    final targetDate = DateTime(target.year, target.month, target.day);
    final currentDate = DateTime(now.year, now.month, now.day);
    return targetDate.difference(currentDate).inDays;
  }
}

enum DistributionStatus { completed, cancelled, pending }

enum DistributionPriority { normal, high, urgent }

class DistributionItem {
  final String name;
  final String quantity;
  final String unit;

  const DistributionItem({
    required this.name,
    required this.quantity,
    required this.unit,
  });
}

class DistributionRecord {
  final String id;
  final DateTime date;
  final List<DistributionItem> items;
  final DistributionStatus status;
  final String shopName;
  final String time;
  final String distributedBy;
  final int familyMembers;

  const DistributionRecord({
    required this.id,
    required this.date,
    required this.items,
    required this.status,
    required this.shopName,
    required this.time,
    required this.distributedBy,
    required this.familyMembers,
  });
}

class UpcomingDistribution {
  final String id;
  final DateTime date;
  final List<DistributionItem> estimatedItems;
  final String shopName;
  final String estimatedTime;
  final DistributionPriority priority;
  final int daysRemaining;

  const UpcomingDistribution({
    required this.id,
    required this.date,
    required this.estimatedItems,
    required this.shopName,
    required this.estimatedTime,
    required this.priority,
    required this.daysRemaining,
  });

  UpcomingDistribution copyWith({
    String? id,
    DateTime? date,
    List<DistributionItem>? estimatedItems,
    String? shopName,
    String? estimatedTime,
    DistributionPriority? priority,
    int? daysRemaining,
  }) {
    return UpcomingDistribution(
      id: id ?? this.id,
      date: date ?? this.date,
      estimatedItems: estimatedItems ?? this.estimatedItems,
      shopName: shopName ?? this.shopName,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      priority: priority ?? this.priority,
      daysRemaining: daysRemaining ?? this.daysRemaining,
    );
  }
}
