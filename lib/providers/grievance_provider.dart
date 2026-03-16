import 'dart:async';

import 'package:flutter/material.dart';

import '../models/grievance.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

class GrievanceProvider extends ChangeNotifier {
  List<Grievance> _grievances = [];
  bool _isLoading = false;
  String? _error;
  Set<String> _viewedGrievanceIds =
      {}; // Track which grievances admin has viewed
  final FirestoreService _firestore;
  StreamSubscription<List<Grievance>>? _subscription;

  List<Grievance> get grievances => _grievances;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  GrievanceProvider({FirestoreService? firestoreService})
      : _firestore = firestoreService ?? FirestoreService() {
    _listen();
  }

  void _listen({String? userId}) {
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = _firestore
        .streamGrievances(userId: userId)
        .listen((items) {
      _grievances = items;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load grievances: $e';
      _isLoading = false;
      notifyListeners();
    });
  }

  // Get count of new/unresolved grievances for admin notification
  int get pendingGrievanceCount =>
      _grievances.where((g) => g.status == GrievanceStatus.pending).length;

  List<Grievance> get newGrievances =>
      _grievances.where((g) => !_viewedGrievanceIds.contains(g.id)).toList();

  int get newGrievanceCount => newGrievances.length;

  // Load grievances for a specific user (citizen or fps)
  Future<void> loadUserGrievances(String userId) async {
    _listen(userId: userId);
  }

  // Load all grievances (admin only)
  Future<void> loadAllGrievances() async {
    _listen();
  }

  // Submit new grievance
  Future<bool> submitGrievance({
    required String userId,
    required String userName,
    required String userType,
    required GrievanceCategory category,
    required String title,
    required String description,
    String? attachmentUrl,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Validate inputs
      if (title.trim().isEmpty || description.trim().isEmpty) {
        _error = 'Title and description are required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final newGrievance = Grievance(
        id: '',
        userId: userId,
        userName: userName,
        userType: userType,
        category: category,
        title: title.trim(),
        description: description.trim(),
        attachmentUrl: attachmentUrl,
        status: GrievanceStatus.pending,
        createdAt: DateTime.now(),
        remarks: [],
      );

      await _firestore.createGrievance(newGrievance);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error submitting grievance: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Admin updates status and adds remark
  Future<void> updateGrievanceStatus(String grievanceId,
      GrievanceStatus newStatus, String remark, User admin) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (remark.trim().isEmpty) {
        _error = 'Remark cannot be empty';
        _isLoading = false;
        notifyListeners();
        return;
      }
      final newRemark = GrievanceRemark(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: admin.id,
        userName: admin.name,
        userType: 'admin',
        remark: remark.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore.updateGrievanceStatus(
        grievanceId: grievanceId,
        status: newStatus,
        remark: newRemark,
      );
      _error = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error updating grievance: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark grievance as viewed by admin
  void markGrievanceAsViewed(String grievanceId) {
    _viewedGrievanceIds.add(grievanceId);
    notifyListeners();
  }

  List<Grievance> getUserGrievances(String userId) {
    return _grievances.where((grievance) => grievance.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Get unresolved grievances for admin dashboard
  List<Grievance> getUnresolvedGrievances() {
    return _grievances
        .where((g) =>
            g.status == GrievanceStatus.pending ||
            g.status == GrievanceStatus.inProgress)
        .toList();
  }

  // Get grievances by status
  List<Grievance> getGrievancesByStatus(GrievanceStatus status) {
    return _grievances.where((g) => g.status == status).toList();
  }

  // Search grievances
  List<Grievance> searchGrievances(String query) {
    if (query.trim().isEmpty) return _grievances;

    final lowerQuery = query.toLowerCase();
    return _grievances
        .where((g) =>
            g.title.toLowerCase().contains(lowerQuery) ||
            g.description.toLowerCase().contains(lowerQuery) ||
            g.userName.toLowerCase().contains(lowerQuery) ||
            g.id.contains(lowerQuery))
        .toList();
  }

  // Get grievance by ID
  Grievance? getGrievanceById(String grievanceId) {
    try {
      return _grievances.firstWhere((g) => g.id == grievanceId);
    } catch (e) {
      return null;
    }
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _grievances.clear();
    _viewedGrievanceIds.clear();
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
