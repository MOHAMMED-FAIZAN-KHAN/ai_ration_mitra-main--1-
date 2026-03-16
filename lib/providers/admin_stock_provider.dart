import 'dart:async';

import 'package:flutter/material.dart';

import '../models/stock.dart';
import '../services/firestore_service.dart';

class AdminStockProvider extends ChangeNotifier {
  List<StockItem> _stockItems = [];
  List<StockMovement> _movements = [];
  bool _isLoading = false;
  String? _error;
  final FirestoreService _firestore;
  StreamSubscription<List<StockItem>>? _stockSubscription;
  StreamSubscription<List<StockMovement>>? _movementSubscription;

  List<StockItem> get stockItems => _stockItems;
  List<StockMovement> get movements => _movements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AdminStockProvider({FirestoreService? firestoreService})
      : _firestore = firestoreService ?? FirestoreService() {
    _listen();
  }

  // Load all stock items (aggregated from all FPS)
  Future<void> loadAllStock() async {
    _listen();
  }

  void _listen() {
    _stockSubscription?.cancel();
    _movementSubscription?.cancel();

    _isLoading = true;
    _error = null;
    notifyListeners();

    _stockSubscription = _firestore.streamStockItems().listen((items) {
      _stockItems = items;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load stock items: $e';
      _isLoading = false;
      notifyListeners();
    });

    _movementSubscription = _firestore.streamStockMovements().listen((items) {
      _movements = items;
      notifyListeners();
    }, onError: (e) {
      _error = 'Failed to load stock movements: $e';
      notifyListeners();
    });
  }

  // Get stock summary by item
  List<StockSummary> getStockSummary() {
    Map<String, List<StockItem>> grouped = {};
    for (var item in _stockItems) {
      grouped.putIfAbsent(item.itemName, () => []).add(item);
    }

    List<StockSummary> summaries = [];
    grouped.forEach((itemName, items) {
      double totalStock = items.fold(0, (sum, i) => sum + i.currentStock);
      double totalCapacity = items.fold(0, (sum, i) => sum + i.maxCapacity);
      // For demo, cleared today is random; in real app would come from movements
      double clearedToday = _movements
          .where((m) => m.itemName == itemName && m.type == MovementType.distributed && m.timestamp.day == DateTime.now().day)
          .fold(0, (sum, m) => sum + m.quantity);
      double incoming = _movements
          .where((m) => m.itemName == itemName && m.type == MovementType.incoming)
          .fold(0, (sum, m) => sum + m.quantity);
      double missing = _movements
          .where((m) => m.itemName == itemName && m.type == MovementType.missing)
          .fold(0, (sum, m) => sum + m.quantity);
      double remaining = totalStock - clearedToday; // simple logic
      summaries.add(StockSummary(
        itemName: itemName,
        totalStock: totalStock,
        totalCapacity: totalCapacity,
        clearedToday: clearedToday,
        incoming: incoming,
        missing: missing,
        remaining: remaining,
      ));
    });
    return summaries;
  }

  // Get movements for a specific item across all stores
  List<StockMovement> getMovementsForItem(String itemName) {
    return _movements.where((m) => m.itemName == itemName).toList();
  }

  // Get stock items for a specific item (by store)
  List<StockItem> getStockForItem(String itemName) {
    return _stockItems.where((s) => s.itemName == itemName).toList();
  }

  @override
  void dispose() {
    _stockSubscription?.cancel();
    _movementSubscription?.cancel();
    super.dispose();
  }
}
