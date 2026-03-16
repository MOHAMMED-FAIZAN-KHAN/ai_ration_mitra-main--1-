import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/fps_shop.dart';
import '../services/location_service.dart';

class FPSProvider extends ChangeNotifier {
  List<FPSShop> _fpsShops = [];
  List<FPSShop> _filteredShops = [];
  bool _isLoading = false;
  Position? _userLocation;
  String? _error;

  List<FPSShop> get fpsShops => _fpsShops;
  List<FPSShop> get filteredShops => _filteredShops;
  bool get isLoading => _isLoading;
  Position? get userLocation => _userLocation;
  String? get error => _error;

  FPSProvider() {
    _loadDummyFPSData();
  }

  void _loadDummyFPSData() {
    _fpsShops = [
      FPSShop(
        id: 'fps_001',
        name: 'New Delhi FPS',
        ownerName: 'Raj Kumar',
        address: 'Sector 12, New Delhi',
        latitude: 28.5355,
        longitude: 77.3910,
        phone: '+91-98765-43210',
        openingTime: '08:00 AM',
        closingTime: '06:00 PM',
        type: 'Regular',
        isActive: true,
      ),
      FPSShop(
        id: 'fps_002',
        name: 'South Delhi FPS',
        ownerName: 'Priya Singh',
        address: 'DDA Market, South Delhi',
        latitude: 28.5244,
        longitude: 77.2068,
        phone: '+91-98765-43211',
        openingTime: '07:30 AM',
        closingTime: '07:00 PM',
        type: 'Specialized',
        isActive: true,
      ),
      FPSShop(
        id: 'fps_003',
        name: 'East Delhi FPS',
        ownerName: 'Amit Verma',
        address: 'Gandhi Nagar, East Delhi',
        latitude: 28.6069,
        longitude: 77.2705,
        phone: '+91-98765-43212',
        openingTime: '08:00 AM',
        closingTime: '05:30 PM',
        type: 'Regular',
        isActive: true,
      ),
      FPSShop(
        id: 'fps_004',
        name: 'West Delhi FPS',
        ownerName: 'Suresh Gupta',
        address: 'Sector 3, Dwarka',
        latitude: 28.5866,
        longitude: 77.0426,
        phone: '+91-98765-43213',
        openingTime: '08:30 AM',
        closingTime: '06:30 PM',
        type: 'Regular',
        isActive: true,
      ),
      FPSShop(
        id: 'fps_005',
        name: 'Greater Noida FPS',
        ownerName: 'Manisha Sharma',
        address: 'Block C, Greater Noida',
        latitude: 28.4744,
        longitude: 77.5714,
        phone: '+91-98765-43214',
        openingTime: '09:00 AM',
        closingTime: '07:00 PM',
        type: 'Specialized',
        isActive: true,
      ),
      FPSShop(
        id: 'fps_006',
        name: 'Gurgaon FPS',
        ownerName: 'Vikram Patel',
        address: 'DLF City, Sector 28',
        latitude: 28.4595,
        longitude: 77.0758,
        phone: '+91-98765-43215',
        openingTime: '08:00 AM',
        closingTime: '06:00 PM',
        type: 'Regular',
        isActive: true,
      ),
    ];
    _filteredShops = List.from(_fpsShops);
    notifyListeners();
  }

  Future<void> getCurrentUserLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        _userLocation = position;
        _error = null;
        // Filter shops near user location (within 30 km)
        _filterShopsByDistance(30);
      } else {
        _error = 'Unable to get location. Please enable location services.';
      }
    } catch (e) {
      _error = 'Error getting location: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void _filterShopsByDistance(double maxDistanceKm) {
    if (_userLocation == null) {
      _filteredShops = List.from(_fpsShops);
      return;
    }

    final shopsWithDistance = _fpsShops
        .map((shop) {
          final distance = LocationService.calculateDistance(
            _userLocation!.latitude,
            _userLocation!.longitude,
            shop.latitude,
            shop.longitude,
          );
          return {'shop': shop, 'distance': distance};
        })
        .where((item) => item['distance'] as double <= maxDistanceKm)
        .cast<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

    _filteredShops =
        shopsWithDistance.map((item) => item['shop'] as FPSShop).toList();
  }

  void searchByName(String query) {
    if (query.isEmpty) {
      _filteredShops = List.from(_fpsShops);
    } else {
      _filteredShops = _fpsShops
          .where((shop) =>
              shop.name.toLowerCase().contains(query.toLowerCase()) ||
              shop.address.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  double getDistanceToShop(FPSShop shop) {
    if (_userLocation == null) return 0;
    return LocationService.calculateDistance(
      _userLocation!.latitude,
      _userLocation!.longitude,
      shop.latitude,
      shop.longitude,
    );
  }

  FPSShop? getShopById(String id) {
    try {
      return _fpsShops.firstWhere((shop) => shop.id == id);
    } catch (e) {
      return null;
    }
  }
}
