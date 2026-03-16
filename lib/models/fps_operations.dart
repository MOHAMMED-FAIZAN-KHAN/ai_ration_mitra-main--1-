enum DealerNotificationLevel { info, warning, critical }

enum DealerRequisitionStatus { pending, approved, rejected }

enum DealerGrievanceStatus { open, inProgress, resolved }

class BeneficiaryRecord {
  final String id;
  final String? uid;
  final String name;
  final String cardNumber;
  final String category;
  final int familyMembers;
  final DateTime? lastCollectionDate;
  final DateTime nextEligibleDate;
  final bool isActive;
  final List<String> pendingItems;

  const BeneficiaryRecord({
    required this.id,
    required this.uid,
    required this.name,
    required this.cardNumber,
    required this.category,
    required this.familyMembers,
    required this.lastCollectionDate,
    required this.nextEligibleDate,
    required this.isActive,
    required this.pendingItems,
  });

  bool get isEligibleToday {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month, now.day);
    final eligibility =
        DateTime(nextEligibleDate.year, nextEligibleDate.month, nextEligibleDate.day);
    return isActive && !eligibility.isAfter(current);
  }

  BeneficiaryRecord copyWith({
    String? id,
    String? uid,
    String? name,
    String? cardNumber,
    String? category,
    int? familyMembers,
    DateTime? lastCollectionDate,
    DateTime? nextEligibleDate,
    bool? isActive,
    List<String>? pendingItems,
  }) {
    return BeneficiaryRecord(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      cardNumber: cardNumber ?? this.cardNumber,
      category: category ?? this.category,
      familyMembers: familyMembers ?? this.familyMembers,
      lastCollectionDate: lastCollectionDate ?? this.lastCollectionDate,
      nextEligibleDate: nextEligibleDate ?? this.nextEligibleDate,
      isActive: isActive ?? this.isActive,
      pendingItems: pendingItems ?? this.pendingItems,
    );
  }

  factory BeneficiaryRecord.fromJson(Map<String, dynamic> json) {
    return BeneficiaryRecord(
      id: json['id'] as String,
      uid: json['uid'] as String?,
      name: json['name'] as String,
      cardNumber: json['cardNumber'] as String,
      category: json['category'] as String,
      familyMembers: json['familyMembers'] as int,
      lastCollectionDate: json['lastCollectionDate'] == null
          ? null
          : DateTime.parse(json['lastCollectionDate'] as String),
      nextEligibleDate: DateTime.parse(json['nextEligibleDate'] as String),
      isActive: json['isActive'] as bool,
      pendingItems: (json['pendingItems'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'cardNumber': cardNumber,
      'category': category,
      'familyMembers': familyMembers,
      'lastCollectionDate': lastCollectionDate?.toIso8601String(),
      'nextEligibleDate': nextEligibleDate.toIso8601String(),
      'isActive': isActive,
      'pendingItems': pendingItems,
    };
  }
}

class DealerNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final DealerNotificationLevel level;

  const DealerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.level,
  });

  DealerNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    DealerNotificationLevel? level,
  }) {
    return DealerNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      level: level ?? this.level,
    );
  }

  factory DealerNotification.fromJson(Map<String, dynamic> json) {
    return DealerNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool,
      level: DealerNotificationLevel.values.firstWhere(
        (level) => level.name == json['level'],
        orElse: () => DealerNotificationLevel.info,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'level': level.name,
    };
  }
}

class DistributionLogEntry {
  final String id;
  final String cardNumber;
  final String beneficiaryName;
  final DateTime distributedAt;
  final Map<String, double> items; // item name -> quantity
  final String status;

  const DistributionLogEntry({
    required this.id,
    required this.cardNumber,
    required this.beneficiaryName,
    required this.distributedAt,
    required this.items,
    required this.status,
  });

  factory DistributionLogEntry.fromJson(Map<String, dynamic> json) {
    return DistributionLogEntry(
      id: json['id'] as String,
      cardNumber: json['cardNumber'] as String,
      beneficiaryName: json['beneficiaryName'] as String,
      distributedAt: DateTime.parse(json['distributedAt'] as String),
      items: (json['items'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardNumber': cardNumber,
      'beneficiaryName': beneficiaryName,
      'distributedAt': distributedAt.toIso8601String(),
      'items': items,
      'status': status,
    };
  }
}

class StockRequisition {
  final String id;
  final String itemName;
  final double requestedQuantity;
  final String unit;
  final String reason;
  final DateTime requestedAt;
  final DealerRequisitionStatus status;

  const StockRequisition({
    required this.id,
    required this.itemName,
    required this.requestedQuantity,
    required this.unit,
    required this.reason,
    required this.requestedAt,
    required this.status,
  });

  StockRequisition copyWith({
    String? id,
    String? itemName,
    double? requestedQuantity,
    String? unit,
    String? reason,
    DateTime? requestedAt,
    DealerRequisitionStatus? status,
  }) {
    return StockRequisition(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      requestedQuantity: requestedQuantity ?? this.requestedQuantity,
      unit: unit ?? this.unit,
      reason: reason ?? this.reason,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
    );
  }

  factory StockRequisition.fromJson(Map<String, dynamic> json) {
    return StockRequisition(
      id: json['id'] as String,
      itemName: json['itemName'] as String,
      requestedQuantity: (json['requestedQuantity'] as num).toDouble(),
      unit: json['unit'] as String,
      reason: json['reason'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      status: DealerRequisitionStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => DealerRequisitionStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'requestedQuantity': requestedQuantity,
      'unit': unit,
      'reason': reason,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status.name,
    };
  }
}

class DealerGrievance {
  final String id;
  final String title;
  final String description;
  final DealerGrievanceStatus status;
  final DateTime createdAt;
  final String? adminRemark;

  const DealerGrievance({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.adminRemark,
  });

  DealerGrievance copyWith({
    String? id,
    String? title,
    String? description,
    DealerGrievanceStatus? status,
    DateTime? createdAt,
    String? adminRemark,
  }) {
    return DealerGrievance(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      adminRemark: adminRemark ?? this.adminRemark,
    );
  }

  factory DealerGrievance.fromJson(Map<String, dynamic> json) {
    return DealerGrievance(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: DealerGrievanceStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => DealerGrievanceStatus.open,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      adminRemark: json['adminRemark'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'adminRemark': adminRemark,
    };
  }
}
