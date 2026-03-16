import 'package:flutter/material.dart';
import '../models/grievance.dart';

class AdminProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  List<Grievance> _allGrievances = [];
  List<Grievance> get allGrievances => _allGrievances;

  // Load admin dashboard data
  Future<bool> loadDashboardData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));

      // In production, load from backend
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to load dashboard data: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get statistics
  Map<String, int> getStatistics(List<Grievance> grievances) {
    return {
      'pending':
          grievances.where((g) => g.status == GrievanceStatus.pending).length,
      'in_progress': grievances
          .where((g) => g.status == GrievanceStatus.inProgress)
          .length,
      'resolved':
          grievances.where((g) => g.status == GrievanceStatus.resolved).length,
      'rejected':
          grievances.where((g) => g.status == GrievanceStatus.rejected).length,
      'total': grievances.length,
    };
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
