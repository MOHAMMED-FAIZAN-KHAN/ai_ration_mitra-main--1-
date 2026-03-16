import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/family_member.dart';

class FamilyMemberProvider extends ChangeNotifier {
  List<FamilyMember> _familyMembers = [];
  bool _isLoading = false;
  String? _error;

  List<FamilyMember> get familyMembers => _familyMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  FamilyMemberProvider() {
    _loadFamilyMembers();
  }

  /// Load family members from local storage
  Future<void> _loadFamilyMembers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final familyData = prefs.getString('family_members');

      if (familyData != null && familyData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(familyData);
        _familyMembers = decoded
            .map((item) => FamilyMember.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _familyMembers = [];
      }
    } catch (e) {
      _error = 'Error loading family members: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save family members to local storage
  Future<void> _saveFamilyMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData =
          jsonEncode(_familyMembers.map((member) => member.toJson()).toList());
      await prefs.setString('family_members', jsonData);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error saving family members: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Add a new family member
  Future<void> addFamilyMember({
    required String name,
    required int age,
    required String relation,
    String? uid,
  }) async {
    try {
      _error = null;

      // Validation
      if (name.trim().isEmpty) {
        _error = 'Please enter a name';
        notifyListeners();
        return;
      }

      if (age <= 0 || age > 150) {
        _error = 'Please enter a valid age';
        notifyListeners();
        return;
      }

      if (relation.trim().isEmpty) {
        _error = 'Please select a relation';
        notifyListeners();
        return;
      }

      // Create new member
      final newMember = FamilyMember(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        age: age,
        relation: relation.trim(),
        uid: uid?.trim(),
      );

      _familyMembers.add(newMember);
      await _saveFamilyMembers();
    } catch (e) {
      _error = 'Error adding family member: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Update an existing family member
  Future<void> updateFamilyMember({
    required String id,
    required String name,
    required int age,
    required String relation,
    String? uid,
  }) async {
    try {
      _error = null;

      // Validation
      if (name.trim().isEmpty) {
        _error = 'Please enter a name';
        notifyListeners();
        return;
      }

      if (age <= 0 || age > 150) {
        _error = 'Please enter a valid age';
        notifyListeners();
        return;
      }

      if (relation.trim().isEmpty) {
        _error = 'Please select a relation';
        notifyListeners();
        return;
      }

      final index = _familyMembers.indexWhere((member) => member.id == id);
      if (index != -1) {
        _familyMembers[index] = _familyMembers[index].copyWith(
          name: name.trim(),
          age: age,
          relation: relation.trim(),
          uid: uid?.trim(),
        );
        await _saveFamilyMembers();
      } else {
        _error = 'Family member not found';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error updating family member: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Delete a family member
  Future<void> deleteFamilyMember(String id) async {
    try {
      _error = null;
      _familyMembers.removeWhere((member) => member.id == id);
      await _saveFamilyMembers();
    } catch (e) {
      _error = 'Error deleting family member: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get family member by ID
  FamilyMember? getFamilyMemberById(String id) {
    try {
      return _familyMembers.firstWhere((member) => member.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get count of family members
  int get familyMemberCount => _familyMembers.length;
}
