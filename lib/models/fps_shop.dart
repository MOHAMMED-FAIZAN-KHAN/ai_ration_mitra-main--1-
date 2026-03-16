class FPSShop {
  final String id;
  final String name;
  final String ownerName;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String openingTime;
  final String closingTime;
  final String type; // 'Regular', 'Specialized', etc.
  final bool isActive;

  FPSShop({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.openingTime,
    required this.closingTime,
    this.type = 'Regular',
    this.isActive = true,
  });

  factory FPSShop.fromJson(Map<String, dynamic> json) {
    return FPSShop(
      id: json['id'],
      name: json['name'],
      ownerName: json['ownerName'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      phone: json['phone'],
      openingTime: json['openingTime'],
      closingTime: json['closingTime'],
      type: json['type'] ?? 'Regular',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerName': ownerName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'type': type,
      'isActive': isActive,
    };
  }
}
