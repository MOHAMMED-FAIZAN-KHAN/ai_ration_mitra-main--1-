import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../../core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../widgets/app_empty_state.dart';

class FpsLocatorScreen extends StatefulWidget {
  final bool showAppBar;

  const FpsLocatorScreen({super.key, this.showAppBar = true});

  @override
  State<FpsLocatorScreen> createState() => _FpsLocatorScreenState();
}

class _FpsLocatorScreenState extends State<FpsLocatorScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _permissionDenied = false;
  bool _serviceDisabled = false;
  final TextEditingController _searchController = TextEditingController();
  
  Set<Marker> _markers = {};
  List<FpsShop> _allShops = [];
  List<FpsShop> _filteredShops = [];

  // FPS shops in Mumbai Malad area
  final List<FpsShop> shops = [
    FpsShop(
      id: '1',
      name: 'Malad Public Distribution Center',
      address: 'Near Malad Station, Mumbai',
      phone: '+91-9876543210',
      latitude: 19.1726,
      longitude: 72.8394,
      rating: 4.5,
      openTime: '10:00 AM',
      closeTime: '6:00 PM',
      ownerName: 'Shyam Kumar',
      type: 'BPL/APL',
    ),
    FpsShop(
      id: '2',
      name: 'Malad West Ration Shop',
      address: 'Malad West, Mumbai',
      phone: '+91-9876543211',
      latitude: 19.1764,
      longitude: 72.8289,
      rating: 4.2,
      openTime: '9:00 AM',
      closeTime: '5:00 PM',
      ownerName: 'Raj Patel',
      type: 'AAY',
    ),
    FpsShop(
      id: '3',
      name: 'Malad East Distribution Shop',
      address: 'Malad East, Near Lakhanpal',
      phone: '+91-9876543212',
      latitude: 19.1815,
      longitude: 72.8584,
      rating: 4.8,
      openTime: '8:00 AM',
      closeTime: '7:00 PM',
      ownerName: 'Priya Singh',
      type: 'BPL',
    ),
    FpsShop(
      id: '4',
      name: 'Malad Community Depot',
      address: 'Srinagar Nagar, Malad West',
      phone: '+91-9876543213',
      latitude: 19.1742,
      longitude: 72.8321,
      rating: 4.0,
      openTime: '10:30 AM',
      closeTime: '5:30 PM',
      ownerName: 'Amar Singh',
      type: 'BPL',
    ),
    FpsShop(
      id: '5',
      name: 'Marve Road Ration Center',
      address: 'Marve Road, Malad West',
      phone: '+91-9876543214',
      latitude: 19.1680,
      longitude: 72.8201,
      rating: 4.6,
      openTime: '9:30 AM',
      closeTime: '6:30 PM',
      ownerName: 'Neha Sharma',
      type: 'APL',
    ),
    FpsShop(
      id: '6',
      name: 'Orlem Public Distribution',
      address: 'Orlem, Malad West',
      phone: '+91-9876543215',
      latitude: 19.1652,
      longitude: 72.8273,
      rating: 4.3,
      openTime: '10:00 AM',
      closeTime: '6:00 PM',
      ownerName: 'Rajesh Nair',
      type: 'BPL/APL',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _allShops = shops;
    _filteredShops = shops;
    _initializeLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) {
          return;
        }
        setState(() {
          _serviceDisabled = true;
          _isLoading = false;
        });
        return;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        // Permission denied forever
        if (!mounted) {
          return;
        }
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Get current position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );

        if (!mounted) {
          return;
        }
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });

        // Add user location marker
        _addUserMarker();
        // Add FPS shop markers
        _addShopMarkers();
        // Move camera to user location
        _moveToUserLocation();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting location: $e');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addUserMarker() {
    if (_currentPosition == null) return;

    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'You are here',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        ),
      ),
    );
  }

  void _addShopMarkers() {
    for (var shop in _filteredShops) {
      final distance = _calculateDistance(
        _currentPosition?.latitude ?? 19.1726,
        _currentPosition?.longitude ?? 72.8394,
        shop.latitude,
        shop.longitude,
      );

      _markers.add(
        Marker(
          markerId: MarkerId(shop.id),
          position: LatLng(shop.latitude, shop.longitude),
          infoWindow: InfoWindow(
            title: shop.name,
            snippet: '${distance.toStringAsFixed(2)} km away',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          onTap: () => _showShopDetails(shop),
        ),
      );
    }
  }

  void _moveToUserLocation() {
    if (_mapController == null || _currentPosition == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 14,
        ),
      ),
    );
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371;

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * asin(sqrt(a));
    double distance = earthRadiusKm * c;

    return distance;
  }

  /// Convert degrees to radians
  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  void _searchShops(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredShops = _allShops;
      });
    } else {
      setState(() {
        _filteredShops = _allShops
            .where((shop) =>
                shop.name.toLowerCase().contains(query.toLowerCase()) ||
                shop.address.toLowerCase().contains(query.toLowerCase()) ||
                shop.ownerName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }

    // Update markers
    _markers.clear();
    _addUserMarker();
    _addShopMarkers();
  }

  void _showShopDetails(FpsShop shop) {
    final distance = _calculateDistance(
      _currentPosition?.latitude ?? 19.1726,
      _currentPosition?.longitude ?? 72.8394,
      shop.latitude,
      shop.longitude,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${shop.rating} Rating',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.saffron.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${distance.toStringAsFixed(2)} km',
                      style: const TextStyle(
                        color: AppColors.saffron,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Shop Details
              _buildDetailRow(
                Icons.person,
                'Owner',
                shop.ownerName,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.location_on,
                'Address',
                shop.address,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.phone,
                'Phone',
                shop.phone,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.access_time,
                'Hours',
                '${shop.openTime} - ${shop.closeTime}',
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.store,
                'Category',
                shop.type,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Opening directions to ${shop.name}...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        // In production: use url_launcher to open Google Maps
                        // launchUrl(Uri.parse('https://maps.google.com/maps?q=${shop.latitude},${shop.longitude}'));
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saffron,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Calling ${shop.phone}...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        // In production: use url_launcher to call
                        // launchUrl(Uri.parse('tel:${shop.phone}'));
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.saffron,
                        side: const BorderSide(color: AppColors.saffron),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.saffron.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.saffron),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (kIsWeb) {
      return _buildWebFallback(context, loc);
    }
    // Show permission denied screen
    if (_permissionDenied) {
      return Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                title: Text(loc.translate('fps_locator_title')),
                centerTitle: true,
              )
            : null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 20),
              Text(
                'Location Permission Denied',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Please enable location permission to find FPS shops in Malad',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Geolocator.openAppSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saffron,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show service disabled screen
    if (_serviceDisabled) {
      return Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                title: Text(loc.translate('fps_locator_title')),
                centerTitle: true,
              )
            : null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 20),
              Text(
                'Location Services Disabled',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Please enable location services on your device',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Geolocator.openLocationSettings();
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Enable Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saffron,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading screen
    if (_isLoading) {
      return Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                title: Text(loc.translate('fps_locator_title')),
                centerTitle: true,
              )
            : null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.saffron),
              const SizedBox(height: 20),
              Text(
                'Getting your location...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    // Main map screen
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(loc.translate('fps_locator_title')),
              centerTitle: true,
              elevation: 0,
            )
          : null,
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(19.1726, 72.8394), // Malad center
              zoom: 14,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
              });
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
          ),

          // Search Box
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _searchShops,
                decoration: InputDecoration(
                  hintText: 'Search FPS Shops in Malad...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchShops('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // My Location FAB
          Positioned(
            bottom: 240,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'location_fab',
              onPressed: _moveToUserLocation,
              backgroundColor: AppColors.saffron,
              child: const Icon(Icons.my_location),
            ),
          ),

          // Bottom Sheet - FPS Shops List
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.15,
            maxChildSize: 0.85,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: _filteredShops.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.search_off,
                      title: 'No shops found',
                      message: 'Try a different area or clear the search.',
                    )
                  : Column(
                      children: [
                        // Handle
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_filteredShops.length} Shops Found in Malad',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // List
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: _filteredShops.length,
                            itemBuilder: (context, index) {
                              final shop = _filteredShops[index];
                              final distance = _calculateDistance(
                                _currentPosition?.latitude ?? 19.1726,
                                _currentPosition?.longitude ?? 72.8394,
                                shop.latitude,
                                shop.longitude,
                              );

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () => _showShopDetails(shop),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Shop name and distance
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      shop.name,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      shop.ownerName,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.saffron
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  '${distance.toStringAsFixed(1)} km',
                                                  style: const TextStyle(
                                                    color: AppColors.saffron,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          // Address
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  shop.address,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          // Hours and Category
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${shop.openTime} - ${shop.closeTime}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Chip(
                                                label: Text(shop.type),
                                                labelStyle: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebFallback(BuildContext context, AppLocalizations loc) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(loc.translate('fps_locator_title')),
              centerTitle: true,
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.translate('map_unavailable'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  loc.translate('list_only_mode'),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _searchShops,
            decoration: InputDecoration(
              hintText: loc.translate('search_fps_depot'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchShops('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._filteredShops.map(_buildShopListCard),
        ],
      ),
    );
  }

  Widget _buildShopListCard(FpsShop shop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.storefront, color: AppColors.saffron),
        title: Text(shop.name),
        subtitle: Text(shop.address),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showShopDetails(shop),
      ),
    );
  }
}

// FPS Shop Model
class FpsShop {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final double rating;
  final String openTime;
  final String closeTime;
  final String ownerName;
  final String type;

  FpsShop({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.openTime,
    required this.closeTime,
    required this.ownerName,
    required this.type,
  });
}
