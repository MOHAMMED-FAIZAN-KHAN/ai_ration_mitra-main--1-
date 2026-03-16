import 'dart:async';

import 'package:flutter/material.dart';

import '../models/fps_operations.dart';
import '../models/stock.dart';
import '../models/user.dart';
import '../data/citizen_distribution_data.dart';
import '../services/firestore_service.dart';

class FPSOperationsProvider extends ChangeNotifier {
  final List<StockItem> _stockItems = [];
  final List<BeneficiaryRecord> _beneficiaries = [];
  final List<DistributionLogEntry> _distributionLogs = [];
  final List<DealerNotification> _notifications = [];
  final List<StockRequisition> _requisitions = [];
  final List<DealerGrievance> _grievances = [];
  final Set<String> _seededBeneficiaryUsers = {};

  bool _isLoading = true;
  String? _error;
  final FirestoreService _firestore;
  bool _seededStockDefaults = false;
  StreamSubscription<List<StockItem>>? _stockSubscription;
  StreamSubscription<List<BeneficiaryRecord>>? _beneficiarySubscription;
  StreamSubscription<List<DistributionLogEntry>>? _distributionSubscription;
  StreamSubscription<List<StockRequisition>>? _requisitionSubscription;
  StreamSubscription<List<DealerGrievance>>? _grievanceSubscription;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<StockItem> get stockItems => List.unmodifiable(_stockItems);
  List<BeneficiaryRecord> get beneficiaries =>
      List.unmodifiable(_beneficiaries);
  List<DistributionLogEntry> get distributionLogs =>
      List.unmodifiable(_distributionLogs);
  List<DealerNotification> get notifications =>
      List.unmodifiable(_notifications);
  List<StockRequisition> get requisitions => List.unmodifiable(_requisitions);
  List<DealerGrievance> get grievances => List.unmodifiable(_grievances);

  int get unreadNotificationCount =>
      _notifications.where((notification) => !notification.isRead).length;

  int get eligibleBeneficiaryCount =>
      _beneficiaries.where((beneficiary) => beneficiary.isEligibleToday).length;

  int get todayDistributionCount {
    final today = DateTime.now();
    return _distributionLogs.where((log) {
      return log.distributedAt.year == today.year &&
          log.distributedAt.month == today.month &&
          log.distributedAt.day == today.day;
    }).length;
  }

  int get openGrievanceCount {
    return _grievances
        .where(
            (grievance) => grievance.status != DealerGrievanceStatus.resolved)
        .length;
  }

  List<StockItem> get lowStockItems {
    return _stockItems
        .where((item) =>
            item.status == StockStatus.low ||
            item.status == StockStatus.critical)
        .toList();
  }

  FPSOperationsProvider({FirestoreService? firestoreService})
      : _firestore = firestoreService ?? FirestoreService() {
    _initialize();
  }

  Future<void> _initialize() async {
    _startRealtimeSync();
  }

  void _startRealtimeSync() {
    _stockSubscription?.cancel();
    _beneficiarySubscription?.cancel();
    _distributionSubscription?.cancel();
    _requisitionSubscription?.cancel();
    _grievanceSubscription?.cancel();

    _isLoading = true;
    _error = null;
    notifyListeners();

    _stockSubscription = _firestore.streamStockItems().listen((items) {
      _stockItems
        ..clear()
        ..addAll(items);
      _isLoading = false;
      if (!_seededStockDefaults) {
        _seededStockDefaults = true;
        _ensureDefaultStockItems(items);
      }
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load stock: $e';
      _isLoading = false;
      notifyListeners();
    });

    _beneficiarySubscription = _firestore.streamBeneficiaries().listen((items) {
      _beneficiaries
        ..clear()
        ..addAll(items);
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load beneficiaries: $e';
      notifyListeners();
    });

    _distributionSubscription =
        _firestore.streamDistributionLogs().listen((items) {
      _distributionLogs
        ..clear()
        ..addAll(items);
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load distribution logs: $e';
      notifyListeners();
    });

    _requisitionSubscription = _firestore.streamRequisitions().listen((items) {
      _requisitions
        ..clear()
        ..addAll(items);
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load requisitions: $e';
      notifyListeners();
    });

    _grievanceSubscription =
        _firestore.streamDealerGrievances().listen((items) {
      _grievances
        ..clear()
        ..addAll(items);
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load grievances: $e';
      notifyListeners();
    });
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  BeneficiaryRecord? findBeneficiary(String cardOrName) {
    final query = cardOrName.trim().toLowerCase();
    if (query.isEmpty) {
      return null;
    }
    final normalizedQuery = _normalizeSearchToken(query);
    for (final beneficiary in _beneficiaries) {
      final uid = beneficiary.uid?.toLowerCase() ?? '';
      if (beneficiary.cardNumber.toLowerCase() == query ||
          uid == query ||
          _normalizeSearchToken(beneficiary.cardNumber)
              .contains(normalizedQuery) ||
          (beneficiary.uid != null &&
              _normalizeSearchToken(beneficiary.uid!)
                  .contains(normalizedQuery)) ||
          beneficiary.name.toLowerCase().contains(query)) {
        return beneficiary;
      }
    }
    return null;
  }

  List<BeneficiaryRecord> searchBeneficiaries(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return List<BeneficiaryRecord>.from(_beneficiaries);
    }
    final normalizedQuery = _normalizeSearchToken(q);
    return _beneficiaries
        .where((beneficiary) =>
            beneficiary.name.toLowerCase().contains(q) ||
            beneficiary.cardNumber.toLowerCase().contains(q) ||
            (beneficiary.uid?.toLowerCase().contains(q) ?? false) ||
            _normalizeSearchToken(beneficiary.name).contains(normalizedQuery) ||
            _normalizeSearchToken(beneficiary.cardNumber)
                .contains(normalizedQuery) ||
            (beneficiary.uid != null &&
                _normalizeSearchToken(beneficiary.uid!)
                    .contains(normalizedQuery)))
        .toList();
  }

  BeneficiaryRecord? beneficiaryByCardNumber(String cardNumber) {
    final query = cardNumber.trim().toLowerCase();
    if (query.isEmpty) {
      return null;
    }
    for (final beneficiary in _beneficiaries) {
      final uid = beneficiary.uid?.toLowerCase() ?? '';
      if (beneficiary.cardNumber.toLowerCase() == query || uid == query) {
        return beneficiary;
      }
    }
    return null;
  }

  BeneficiaryRecord? beneficiaryForCitizen(User? user) {
    if (user == null) {
      return _beneficiaries.isEmpty ? null : _beneficiaries.first;
    }

    final userName = user.name.trim().toLowerCase();
    if (userName.isNotEmpty) {
      for (final beneficiary in _beneficiaries) {
        if (beneficiary.name.trim().toLowerCase() == userName) {
          return beneficiary;
        }
      }
      for (final beneficiary in _beneficiaries) {
        if (beneficiary.name.trim().toLowerCase().contains(userName)) {
          return beneficiary;
        }
      }
    }

    final possibleIds = <String>[
      user.uid ?? '',
      user.id,
      user.mobileNumber ?? '',
      user.aadhaarNumber ?? '',
    ];
    for (final raw in possibleIds) {
      final candidate = beneficiaryByCardNumber(raw);
      if (candidate != null) {
        return candidate;
      }
    }

    if (_beneficiaries.isNotEmpty) {
      return _beneficiaries.first;
    }

    if (user.type == UserType.citizen) {
      final seeded = _buildBeneficiaryFromUser(user);
      _seedBeneficiary(seeded);
      return seeded;
    }

    return null;
  }

  BeneficiaryRecord _buildBeneficiaryFromUser(User user) {
    final cardNumber = (user.uid ?? '').trim().isNotEmpty
        ? user.uid!.trim()
        : (user.aadhaarNumber ?? '').trim().isNotEmpty
            ? user.aadhaarNumber!.trim()
            : (user.mobileNumber ?? '').trim().isNotEmpty
                ? user.mobileNumber!.trim()
                : user.id;
    final uid = _beneficiaryUidFromUser(user);
    final category = (user.category ?? '').trim().isEmpty
        ? 'PHH (BPL)'
        : user.category!.trim();
    return BeneficiaryRecord(
      id: user.id,
      uid: uid,
      name: user.name.trim().isEmpty ? 'Citizen User' : user.name.trim(),
      cardNumber: cardNumber,
      category: category,
      familyMembers: 4,
      lastCollectionDate: null,
      nextEligibleDate: DateTime.now(),
      isActive: true,
      pendingItems: const ['Rice 3kg', 'Wheat 5kg', 'Sugar 1kg'],
    );
  }

  String _beneficiaryUidFromUser(User user) {
    final rawUid = (user.uid ?? '').trim();
    if (rawUid.isNotEmpty) {
      return rawUid;
    }
    final aadhaarDigits =
        (user.aadhaarNumber ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (aadhaarDigits.length == 12) {
      return aadhaarDigits;
    }
    final mobileDigits =
        (user.mobileNumber ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (mobileDigits.isNotEmpty) {
      return mobileDigits;
    }
    return user.id;
  }

  void _seedBeneficiary(BeneficiaryRecord record) {
    if (_seededBeneficiaryUsers.contains(record.id)) {
      return;
    }
    _seededBeneficiaryUsers.add(record.id);
    _beneficiaries.add(record);
    notifyListeners();
    _firestore.upsertBeneficiary(record).catchError((_) {});
  }

  List<DistributionRecord> distributionHistoryForCard(String cardNumber) {
    final records = _distributionLogs
        .where(
            (log) => log.cardNumber.toLowerCase() == cardNumber.toLowerCase())
        .toList()
      ..sort((a, b) => b.distributedAt.compareTo(a.distributedAt));

    final beneficiary = beneficiaryByCardNumber(cardNumber);
    return records
        .map(
          (log) => DistributionRecord(
            id: log.id,
            date: log.distributedAt,
            items: log.items.entries
                .map(
                  (item) => DistributionItem(
                    name: item.key,
                    quantity: _formatQuantity(item.value),
                    unit: _unitForItem(item.key),
                  ),
                )
                .toList(),
            status: DistributionStatus.completed,
            shopName: 'Shyam Ration Store',
            time: _formatTime(log.distributedAt),
            distributedBy: 'FPS Dealer',
            familyMembers: beneficiary?.familyMembers ?? 0,
          ),
        )
        .toList();
  }

  List<UpcomingDistribution> upcomingDistributionForCard(String cardNumber) {
    final beneficiary = beneficiaryByCardNumber(cardNumber);
    if (beneficiary == null) {
      return const [];
    }
    final scheduledDate = DateTime(
      beneficiary.nextEligibleDate.year,
      beneficiary.nextEligibleDate.month,
      beneficiary.nextEligibleDate.day,
    );
    final days = _daysFromToday(scheduledDate);
    return [
      UpcomingDistribution(
        id: 'upcoming_${beneficiary.cardNumber}',
        date: scheduledDate,
        estimatedItems: _itemsFromPendingList(
          beneficiary.pendingItems,
          familyMembers: beneficiary.familyMembers,
        ),
        shopName: 'Shyam Ration Store',
        estimatedTime: '10:00 AM - 04:00 PM',
        priority:
            days <= 1 ? DistributionPriority.high : DistributionPriority.normal,
        daysRemaining: days < 0 ? 0 : days,
      ),
    ];
  }

  Future<bool> updateUpcomingDistributionDate({
    required String cardNumber,
    required DateTime nextDate,
  }) async {
    _error = null;
    final normalizedDate =
        DateTime(nextDate.year, nextDate.month, nextDate.day);
    final beneficiaryIndex = _beneficiaries
        .indexWhere((beneficiary) => beneficiary.cardNumber == cardNumber);
    if (beneficiaryIndex == -1) {
      _error = 'Beneficiary not found';
      notifyListeners();
      return false;
    }

    if (_hasDistributionInMonth(cardNumber, normalizedDate)) {
      _error = 'Distribution already completed for this month';
      notifyListeners();
      return false;
    }

    final existing = _beneficiaries[beneficiaryIndex];
    _beneficiaries[beneficiaryIndex] = existing.copyWith(
      nextEligibleDate: normalizedDate,
      pendingItems: existing.pendingItems.isEmpty
          ? const ['Rice 3kg', 'Wheat 5kg', 'Sugar 1kg']
          : existing.pendingItems,
    );

    final now = DateTime.now();
    _notifications.insert(
      0,
      DealerNotification(
        id: 'ntf_${now.microsecondsSinceEpoch}',
        title: 'Upcoming Distribution Updated',
        message:
            'Upcoming date for ${existing.name} (${existing.cardNumber}) set to ${_formatDate(normalizedDate)}.',
        createdAt: now,
        isRead: false,
        level: DealerNotificationLevel.info,
      ),
    );
    notifyListeners();
    try {
      await _firestore.upsertBeneficiary(_beneficiaries[beneficiaryIndex]);
      return true;
    } catch (e) {
      _error = 'Failed to update distribution date: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBeneficiaryEntitlements({
    required String cardNumber,
    required List<String> pendingItems,
  }) async {
    _error = null;
    final index = _beneficiaries
        .indexWhere((beneficiary) => beneficiary.cardNumber == cardNumber);
    if (index == -1) {
      _error = 'Beneficiary not found';
      notifyListeners();
      return false;
    }

    final sanitized = pendingItems
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (sanitized.isEmpty) {
      _error = 'At least one entitlement item is required';
      notifyListeners();
      return false;
    }

    final existing = _beneficiaries[index];
    final updated = existing.copyWith(pendingItems: sanitized);
    _beneficiaries[index] = updated;
    notifyListeners();
    try {
      await _firestore.upsertBeneficiary(updated);
      return true;
    } catch (e) {
      _error = 'Failed to update entitlements: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> distributeToBeneficiary(String cardNumber) async {
    _error = null;
    final beneficiaryIndex = _beneficiaries
        .indexWhere((beneficiary) => beneficiary.cardNumber == cardNumber);

    if (beneficiaryIndex == -1) {
      _error = 'Beneficiary not found';
      notifyListeners();
      return false;
    }

    final beneficiary = _beneficiaries[beneficiaryIndex];
    if (!beneficiary.isEligibleToday) {
      _error = 'Beneficiary is not eligible today';
      notifyListeners();
      return false;
    }

    final now = DateTime.now();
    if (_hasDistributionInMonth(cardNumber, now)) {
      _error = 'Distribution already marked completed for this month';
      notifyListeners();
      return false;
    }

    const required = {'Rice': 3.0, 'Wheat': 5.0, 'Sugar': 1.0};

    for (final entry in required.entries) {
      final stockIndex =
          _stockItems.indexWhere((item) => item.itemName == entry.key);
      if (stockIndex == -1 ||
          _stockItems[stockIndex].currentStock < entry.value) {
        _error = 'Insufficient stock for ${entry.key}';
        notifyListeners();
        return false;
      }
    }

    final updatedStockItems = <StockItem>[];
    for (var i = 0; i < _stockItems.length; i++) {
      final item = _stockItems[i];
      final requiredQty = required[item.itemName];
      if (requiredQty == null) {
        continue;
      }
      final updatedStock = (item.currentStock - requiredQty)
          .clamp(0, item.maxCapacity)
          .toDouble();
      final updatedItem = StockItem(
        id: item.id,
        fpsId: item.fpsId,
        fpsName: item.fpsName,
        itemName: item.itemName,
        currentStock: updatedStock,
        maxCapacity: item.maxCapacity,
        unit: item.unit,
        status: _deriveStatus(updatedStock, item.maxCapacity),
        lastUpdated: DateTime.now(),
      );
      _stockItems[i] = updatedItem;
      updatedStockItems.add(updatedItem);
    }

    final updatedBeneficiary = beneficiary.copyWith(
      lastCollectionDate: now,
      nextEligibleDate: _sameDayNextMonth(now),
      pendingItems: const [],
    );
    _beneficiaries[beneficiaryIndex] = updatedBeneficiary;

    final newLog = DistributionLogEntry(
      id: '',
      cardNumber: beneficiary.cardNumber,
      beneficiaryName: beneficiary.name,
      distributedAt: now,
      items: required,
      status: 'Completed',
    );
    _distributionLogs.insert(0, newLog);

    _notifications.insert(
      0,
      DealerNotification(
        id: 'ntf_${now.microsecondsSinceEpoch}',
        title: 'Distribution Completed',
        message:
            'Ration distributed to ${beneficiary.name} (${beneficiary.cardNumber}).',
        createdAt: now,
        isRead: false,
        level: DealerNotificationLevel.info,
      ),
    );

    notifyListeners();
    try {
      for (final item in updatedStockItems) {
        await _firestore.upsertStockItem(item);
        await _firestore.createStockMovement(
          StockMovement(
            id: '',
            fpsId: item.fpsId,
            fpsName: item.fpsName,
            itemName: item.itemName,
            type: MovementType.distributed,
            quantity: required[item.itemName] ?? 0,
            unit: item.unit,
            timestamp: now,
            remarks: 'Distribution for ${beneficiary.cardNumber}',
          ),
        );
      }
      await _firestore.upsertBeneficiary(updatedBeneficiary);
      await _firestore.createDistributionLog(newLog);
      return true;
    } catch (e) {
      _error = 'Distribution failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> receiveStock(String itemName, double quantity) async {
    _error = null;
    if (quantity <= 0) {
      _error = 'Enter a valid quantity';
      notifyListeners();
      return false;
    }

    final index = _stockItems.indexWhere((item) => item.itemName == itemName);
    if (index == -1) {
      _error = 'Stock item not found';
      notifyListeners();
      return false;
    }

    final item = _stockItems[index];
    final updatedStockAsDouble =
        (item.currentStock + quantity).clamp(0, item.maxCapacity).toDouble();

    final updatedItem = StockItem(
      id: item.id,
      fpsId: item.fpsId,
      fpsName: item.fpsName,
      itemName: item.itemName,
      currentStock: updatedStockAsDouble,
      maxCapacity: item.maxCapacity,
      unit: item.unit,
      status: _deriveStatus(updatedStockAsDouble, item.maxCapacity),
      lastUpdated: DateTime.now(),
    );
    _stockItems[index] = updatedItem;

    final now = DateTime.now();
    _notifications.insert(
      0,
      DealerNotification(
        id: 'ntf_${now.microsecondsSinceEpoch}',
        title: 'Stock Updated',
        message: '$quantity ${item.unit} $itemName received and updated.',
        createdAt: now,
        isRead: false,
        level: DealerNotificationLevel.info,
      ),
    );

    notifyListeners();
    try {
      await _firestore.upsertStockItem(updatedItem);
      await _firestore.createStockMovement(
        StockMovement(
          id: '',
          fpsId: item.fpsId,
          fpsName: item.fpsName,
          itemName: item.itemName,
          type: MovementType.received,
          quantity: quantity,
          unit: item.unit,
          timestamp: now,
          remarks: 'Stock received',
        ),
      );
      return true;
    } catch (e) {
      _error = 'Unable to update stock: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeStock(
    String itemName,
    double quantity, {
    String reason = '',
  }) async {
    _error = null;
    if (quantity <= 0) {
      _error = 'Enter a valid quantity';
      notifyListeners();
      return false;
    }

    final index = _stockItems.indexWhere((item) => item.itemName == itemName);
    if (index == -1) {
      _error = 'Stock item not found';
      notifyListeners();
      return false;
    }

    final item = _stockItems[index];
    if (quantity > item.currentStock) {
      _error = 'Cannot remove more than available stock';
      notifyListeners();
      return false;
    }

    final updatedStockAsDouble =
        (item.currentStock - quantity).clamp(0, item.maxCapacity).toDouble();

    final updatedItem = StockItem(
      id: item.id,
      fpsId: item.fpsId,
      fpsName: item.fpsName,
      itemName: item.itemName,
      currentStock: updatedStockAsDouble,
      maxCapacity: item.maxCapacity,
      unit: item.unit,
      status: _deriveStatus(updatedStockAsDouble, item.maxCapacity),
      lastUpdated: DateTime.now(),
    );
    _stockItems[index] = updatedItem;

    final reasonText = reason.trim();
    final now = DateTime.now();
    _notifications.insert(
      0,
      DealerNotification(
        id: 'ntf_${now.microsecondsSinceEpoch}',
        title: 'Stock Removed',
        message: reasonText.isEmpty
            ? '$quantity ${item.unit} $itemName removed from inventory.'
            : '$quantity ${item.unit} $itemName removed. Reason: $reasonText',
        createdAt: now,
        isRead: false,
        level: DealerNotificationLevel.warning,
      ),
    );

    notifyListeners();
    try {
      await _firestore.upsertStockItem(updatedItem);
      await _firestore.createStockMovement(
        StockMovement(
          id: '',
          fpsId: item.fpsId,
          fpsName: item.fpsName,
          itemName: item.itemName,
          type: MovementType.missing,
          quantity: quantity,
          unit: item.unit,
          timestamp: now,
          remarks: reasonText.isEmpty ? 'Stock removed' : reasonText,
        ),
      );
      return true;
    } catch (e) {
      _error = 'Unable to remove stock: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> addRequisition({
    required String itemName,
    required double quantity,
    required String unit,
    required String reason,
  }) async {
    _error = null;
    if (quantity <= 0 || reason.trim().isEmpty) {
      _error = 'Valid quantity and reason are required';
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final requisition = StockRequisition(
      id: '',
      itemName: itemName,
      requestedQuantity: quantity,
      unit: unit,
      reason: reason.trim(),
      requestedAt: now,
      status: DealerRequisitionStatus.pending,
    );
    _notifications.insert(
      0,
      DealerNotification(
        id: 'ntf_${now.microsecondsSinceEpoch}',
        title: 'Requisition Submitted',
        message: 'Requisition for $quantity $unit $itemName sent to admin.',
        createdAt: now,
        isRead: false,
        level: DealerNotificationLevel.warning,
      ),
    );
    notifyListeners();
    try {
      await _firestore.createRequisition(requisition);
    } catch (e) {
      _error = 'Failed to create requisition: $e';
      notifyListeners();
    }
  }

  Future<void> updateRequisitionStatus(
      String id, DealerRequisitionStatus status) async {
    final index =
        _requisitions.indexWhere((requisition) => requisition.id == id);
    if (index == -1) {
      return;
    }
    final requisition = _requisitions[index];
    _requisitions[index] = requisition.copyWith(status: status);

    final now = DateTime.now();
    final statusText = switch (status) {
      DealerRequisitionStatus.pending => 'Pending',
      DealerRequisitionStatus.approved => 'Approved',
      DealerRequisitionStatus.rejected => 'Rejected',
    };
    _notifications.insert(
      0,
      DealerNotification(
        id: 'ntf_${now.microsecondsSinceEpoch}',
        title: 'Requisition $statusText',
        message:
            'Requisition for ${requisition.itemName} (${requisition.requestedQuantity} ${requisition.unit}) is now $statusText.',
        createdAt: now,
        isRead: false,
        level: status == DealerRequisitionStatus.rejected
            ? DealerNotificationLevel.warning
            : DealerNotificationLevel.info,
      ),
    );

    notifyListeners();
    try {
      await _firestore.updateRequisitionStatus(id: id, status: status);
    } catch (e) {
      _error = 'Failed to update requisition: $e';
      notifyListeners();
    }
  }

  void markNotificationAsRead(String id) {
    final index =
        _notifications.indexWhere((notification) => notification.id == id);
    if (index == -1) {
      return;
    }
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  Future<void> addGrievance({
    required String title,
    required String description,
  }) async {
    if (title.trim().isEmpty || description.trim().isEmpty) {
      _error = 'Title and description are required';
      notifyListeners();
      return;
    }
    final now = DateTime.now();
    final grievance = DealerGrievance(
      id: '',
      title: title.trim(),
      description: description.trim(),
      status: DealerGrievanceStatus.open,
      createdAt: now,
      adminRemark: null,
    );
    _notifications.insert(
      0,
      DealerNotification(
        id: 'ntf_${now.microsecondsSinceEpoch}',
        title: 'Grievance Submitted',
        message: 'Your grievance "$title" was submitted to admin.',
        createdAt: now,
        isRead: false,
        level: DealerNotificationLevel.info,
      ),
    );
    notifyListeners();
    try {
      final id = await _firestore.createDealerGrievance(grievance);
      if (id.isNotEmpty) {
        _grievances.insert(0, grievance.copyWith(id: id));
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to submit grievance: $e';
      notifyListeners();
    }
  }

  Future<void> updateGrievanceStatus(
    String id,
    DealerGrievanceStatus status, {
    String? adminRemark,
  }) async {
    final index = _grievances.indexWhere((grievance) => grievance.id == id);
    if (index == -1) {
      return;
    }
    _grievances[index] = _grievances[index].copyWith(
      status: status,
      adminRemark: adminRemark?.trim().isEmpty == true
          ? _grievances[index].adminRemark
          : adminRemark,
    );
    notifyListeners();
    try {
      await _firestore.updateDealerGrievanceStatus(
        grievanceId: id,
        status: status,
        adminRemark: adminRemark,
      );
    } catch (e) {
      _error = 'Failed to update grievance: $e';
      notifyListeners();
    }
  }

  StockStatus _deriveStatus(double stock, double capacity) {
    if (capacity <= 0) {
      return StockStatus.critical;
    }
    final ratio = stock / capacity;
    if (ratio < 0.2) {
      return StockStatus.critical;
    }
    if (ratio < 0.4) {
      return StockStatus.low;
    }
    return StockStatus.good;
  }

  bool _hasDistributionInMonth(String cardNumber, DateTime reference) {
    return _distributionLogs.any((log) {
      if (log.cardNumber.toLowerCase() != cardNumber.toLowerCase()) {
        return false;
      }
      return log.distributedAt.year == reference.year &&
          log.distributedAt.month == reference.month;
    });
  }

  DateTime _sameDayNextMonth(DateTime source) {
    final nextMonthFirstDay = DateTime(source.year, source.month + 1, 1);
    final maxDayInNextMonth =
        DateTime(nextMonthFirstDay.year, nextMonthFirstDay.month + 1, 0).day;
    final day = source.day > maxDayInNextMonth ? maxDayInNextMonth : source.day;
    return DateTime(nextMonthFirstDay.year, nextMonthFirstDay.month, day);
  }

  int _daysFromToday(DateTime target) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return target.difference(today).inDays;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final meridian = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $meridian';
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _unitForItem(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized == 'oil' || normalized == 'kerosene') {
      return 'L';
    }
    return 'kg';
  }

  Future<void> _ensureDefaultStockItems(List<StockItem> items) async {
    final existing =
        items.map((item) => item.itemName.trim().toLowerCase()).toSet();
    final now = DateTime.now();
    const fpsId = 'FPS-2736';
    const fpsName = 'Main FPS Store';
    final defaults = [
      _StockSeed('Rice', 1000, 'kg'),
      _StockSeed('Wheat', 1000, 'kg'),
      _StockSeed('Sugar', 300, 'kg'),
      _StockSeed('Dal', 500, 'kg'),
    ];

    for (final seed in defaults) {
      if (existing.contains(seed.name.toLowerCase())) {
        continue;
      }
      final item = StockItem(
        id: 'stock_${seed.name.toLowerCase()}',
        fpsId: fpsId,
        fpsName: fpsName,
        itemName: seed.name,
        currentStock: 0,
        maxCapacity: seed.capacity,
        unit: seed.unit,
        status: StockStatus.critical,
        lastUpdated: now,
      );
      try {
        await _firestore.upsertStockItem(item);
      } catch (_) {
        // Ignore seeding errors; UI can still load without defaults.
      }
    }
  }

  String _normalizeSearchToken(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  List<DistributionItem> _itemsFromPendingList(
    List<String> pendingItems, {
    int familyMembers = 1,
  }) {
    if (pendingItems.isEmpty) {
      // Per-head allocation: 3kg rice, 2kg wheat, 1kg sugar, 1kg daal
      return [
        DistributionItem(
          name: 'Rice',
          quantity: (3 * familyMembers).toString(),
          unit: 'kg',
        ),
        DistributionItem(
          name: 'Wheat',
          quantity: (2 * familyMembers).toString(),
          unit: 'kg',
        ),
        DistributionItem(
          name: 'Sugar',
          quantity: (1 * familyMembers).toString(),
          unit: 'kg',
        ),
        DistributionItem(
          name: 'Daal',
          quantity: (1 * familyMembers).toString(),
          unit: 'kg',
        ),
      ];
    }

    return pendingItems.map((entry) {
      final parts = entry.trim().split(RegExp(r'\s+'));
      if (parts.length < 2) {
        return DistributionItem(name: entry, quantity: '1', unit: 'unit');
      }
      final itemName = parts.first;
      final qtyWithUnit = parts[1];
      final quantity = qtyWithUnit.replaceAll(RegExp(r'[^0-9.]'), '');
      final unit = qtyWithUnit.replaceAll(RegExp(r'[0-9.]'), '');
      return DistributionItem(
        name: itemName,
        quantity: quantity.isEmpty ? '1' : quantity,
        unit: unit.isEmpty ? 'unit' : unit,
      );
    }).toList();
  }

  @override
  void dispose() {
    _stockSubscription?.cancel();
    _beneficiarySubscription?.cancel();
    _distributionSubscription?.cancel();
    _requisitionSubscription?.cancel();
    _grievanceSubscription?.cancel();
    super.dispose();
  }
}

class _StockSeed {
  final String name;
  final double capacity;
  final String unit;

  const _StockSeed(this.name, this.capacity, this.unit);
}
