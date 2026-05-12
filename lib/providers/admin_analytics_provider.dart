import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Added

class AdminAnalyticsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  // User stats
  int _totalUsers = 0;
  int _totalCitizens = 0;
  int _totalFPSDealers = 0;
  int _totalAdmins = 0;
  Map<String, int> _newUsersPerMonth = {};

  // Grievance stats
  int _totalGrievances = 0;
  Map<String, int> _grievancesByStatus = {};
  Map<String, int> _grievancesByCategory = {};
  double _avgResolutionDays = 0.0;
  double _resolutionRate = 0.0;

  // Booking stats
  int _totalBookings = 0;
  Map<String, int> _bookingsByStatus = {};
  Map<String, int> _bookingsByTimeSlot = {};
  Map<String, int> _bookingsPerMonth = {};

  // Stock stats
  Map<String, double> _totalStockByCommodity = {};
  int _lowStockAlerts = 0;
  int _criticalStockAlerts = 0;
  Map<String, double> _incomingStock = {};
  Map<String, double> _outgoingStock = {};

  // Distribution stats
  double _distributionCompletionRate = 0.0;
  Map<String, double> _fpsCompletionRates = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalUsers => _totalUsers;
  int get totalCitizens => _totalCitizens;
  int get totalFPSDealers => _totalFPSDealers;
  int get totalAdmins => _totalAdmins;
  Map<String, int> get newUsersPerMonth => _newUsersPerMonth;

  int get totalGrievances => _totalGrievances;
  Map<String, int> get grievancesByStatus => _grievancesByStatus;
  Map<String, int> get grievancesByCategory => _grievancesByCategory;
  double get avgResolutionDays => _avgResolutionDays;
  double get resolutionRate => _resolutionRate;

  int get totalBookings => _totalBookings;
  Map<String, int> get bookingsByStatus => _bookingsByStatus;
  Map<String, int> get bookingsByTimeSlot => _bookingsByTimeSlot;
  Map<String, int> get bookingsPerMonth => _bookingsPerMonth;

  Map<String, double> get totalStockByCommodity => _totalStockByCommodity;
  int get lowStockAlerts => _lowStockAlerts;
  int get criticalStockAlerts => _criticalStockAlerts;
  Map<String, double> get incomingStock => _incomingStock;
  Map<String, double> get outgoingStock => _outgoingStock;

  double get distributionCompletionRate => _distributionCompletionRate;
  Map<String, double> get fpsCompletionRates => _fpsCompletionRates;

  Future<void> loadAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadUserStats(),
        _loadGrievanceStats(),
        _loadBookingStats(),
        _loadStockStats(),
        _loadDistributionStats(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserStats() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    _totalUsers = usersSnapshot.docs.length;
    _totalCitizens = usersSnapshot.docs.where((doc) => doc['type'] == 'citizen').length;
    _totalFPSDealers = usersSnapshot.docs.where((doc) => doc['type'] == 'fps_dealer').length;
    _totalAdmins = usersSnapshot.docs.where((doc) => doc['type'] == 'admin').length;

    _newUsersPerMonth = {};
    for (var doc in usersSnapshot.docs) {
      final createdAt = (doc['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final monthKey = '${createdAt.year}-${createdAt.month}';
        _newUsersPerMonth[monthKey] = (_newUsersPerMonth[monthKey] ?? 0) + 1;
      }
    }
  }

  Future<void> _loadGrievanceStats() async {
    final grievancesSnapshot = await FirebaseFirestore.instance.collection('grievances').get();
    _totalGrievances = grievancesSnapshot.docs.length;

    _grievancesByStatus = {};
    _grievancesByCategory = {};
    int resolvedCount = 0;
    int totalResolutionDays = 0;

    for (var doc in grievancesSnapshot.docs) {
      final status = doc['status'] as String? ?? 'pending';
      _grievancesByStatus[status] = (_grievancesByStatus[status] ?? 0) + 1;

      final category = doc['category'] as String? ?? 'other';
      _grievancesByCategory[category] = (_grievancesByCategory[category] ?? 0) + 1;

      if (status == 'resolved') {
        resolvedCount++;
        final createdAt = (doc['createdAt'] as Timestamp?)?.toDate();
        final resolvedAt = (doc['updatedAt'] as Timestamp?)?.toDate();
        if (createdAt != null && resolvedAt != null) {
          totalResolutionDays += resolvedAt.difference(createdAt).inDays;
        }
      }
    }

    _resolutionRate = _totalGrievances > 0 ? resolvedCount / _totalGrievances : 0;
    _avgResolutionDays = resolvedCount > 0 ? totalResolutionDays / resolvedCount : 0;
  }

  Future<void> _loadBookingStats() async {
    final bookingsSnapshot = await FirebaseFirestore.instance.collection('bookings').get();
    _totalBookings = bookingsSnapshot.docs.length;

    _bookingsByStatus = {};
    _bookingsByTimeSlot = {};
    _bookingsPerMonth = {};

    for (var doc in bookingsSnapshot.docs) {
      final status = doc['status'] as String? ?? 'pending';
      _bookingsByStatus[status] = (_bookingsByStatus[status] ?? 0) + 1;

      final timeSlot = doc['timeSlot'] as String? ?? 'unknown';
      _bookingsByTimeSlot[timeSlot] = (_bookingsByTimeSlot[timeSlot] ?? 0) + 1;

      final bookingDate = (doc['bookingDate'] as Timestamp?)?.toDate();
      if (bookingDate != null) {
        final monthKey = '${bookingDate.year}-${bookingDate.month}';
        _bookingsPerMonth[monthKey] = (_bookingsPerMonth[monthKey] ?? 0) + 1;
      }
    }
  }

  Future<void> _loadStockStats() async {
    final stockSnapshot = await FirebaseFirestore.instance.collection('stock_items').get();

    _totalStockByCommodity = {};
    _lowStockAlerts = 0;
    _criticalStockAlerts = 0;

    for (var doc in stockSnapshot.docs) {
      final commodity = doc['itemName'] as String? ?? 'unknown';
      final currentStock = (doc['currentStock'] as num?)?.toDouble() ?? 0.0;
      _totalStockByCommodity[commodity] = (_totalStockByCommodity[commodity] ?? 0) + currentStock;

      final status = doc['status'] as String? ?? 'good';
      if (status == 'low') _lowStockAlerts++;
      if (status == 'critical') _criticalStockAlerts++;
    }

    final movementsSnapshot = await FirebaseFirestore.instance.collection('stock_movements').get();

    _incomingStock = {};
    _outgoingStock = {};

    for (var doc in movementsSnapshot.docs) {
      final commodity = doc['itemName'] as String? ?? 'unknown';
      final type = doc['type'] as String? ?? 'unknown';
      final quantity = (doc['quantity'] as num?)?.toDouble() ?? 0.0;

      if (type == 'received' || type == 'incoming') {
        _incomingStock[commodity] = (_incomingStock[commodity] ?? 0) + quantity;
      } else if (type == 'distributed') {
        _outgoingStock[commodity] = (_outgoingStock[commodity] ?? 0) + quantity;
      }
    }
  }

  Future<void> _loadDistributionStats() async {
    final distributionsSnapshot = await FirebaseFirestore.instance.collection('distributions').get();

    int totalCompleted = 0;
    int totalScheduled = 0;
    Map<String, int> fpsCompleted = {};
    Map<String, int> fpsScheduled = {};

    for (var doc in distributionsSnapshot.docs) {
      final status = doc['status'] as String? ?? 'pending';
      final fpsId = doc['fpsId'] as String? ?? 'unknown';
      if (status == 'completed') {
        totalCompleted++;
        fpsCompleted[fpsId] = (fpsCompleted[fpsId] ?? 0) + 1;
      } else {
        totalScheduled++;
        fpsScheduled[fpsId] = (fpsScheduled[fpsId] ?? 0) + 1;
      }
    }

    _distributionCompletionRate = totalScheduled > 0 ? totalCompleted / totalScheduled : 0;

    // Compute completion rate per FPS
    final allFpsIds = {...fpsCompleted.keys, ...fpsScheduled.keys};
    for (var fpsId in allFpsIds) {
      final completed = fpsCompleted[fpsId] ?? 0;
      final scheduled = fpsScheduled[fpsId] ?? 0;
      _fpsCompletionRates[fpsId] = scheduled > 0 ? completed / scheduled : 0;
    }
  }
}