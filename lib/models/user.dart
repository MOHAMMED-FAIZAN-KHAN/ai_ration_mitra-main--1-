enum UserType { citizen, fpsDealer, admin }

class User {
  final String id;
  final UserType type;
  final String name;
  final String? aadhaarNumber;
  final String? mobileNumber;
  final String? email;
  final String? uid;
  final String? category;
  final String? assignedShop;
  final String? fpsId;
  final String? address;
  final String? profileImage;

  User({
    required this.id,
    required this.type,
    required this.name,
    this.aadhaarNumber,
    this.mobileNumber,
    this.email,
    this.uid,
    this.category,
    this.assignedShop,
    this.fpsId,
    this.address,
    this.profileImage,
  });

  User copyWith({
    String? id,
    UserType? type,
    String? name,
    String? aadhaarNumber,
    String? mobileNumber,
    String? email,
    String? uid,
    String? category,
    String? assignedShop,
    String? fpsId,
    String? address,
    String? profileImage,
  }) {
    return User(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      uid: uid ?? this.uid,
      category: category ?? this.category,
      assignedShop: assignedShop ?? this.assignedShop,
      fpsId: fpsId ?? this.fpsId,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      type: _parseUserType(json['type']),
      name: json['name'],
      aadhaarNumber: json['aadhaarNumber'],
      mobileNumber: json['mobileNumber'],
      email: json['email'],
      uid: json['uid'],
      category: json['category'],
      assignedShop: json['assignedShop'],
      fpsId: json['fpsId'],
      address: json['address'],
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'name': name,
      'aadhaarNumber': aadhaarNumber,
      'mobileNumber': mobileNumber,
      'email': email,
      'uid': uid,
      'category': category,
      'assignedShop': assignedShop,
      'fpsId': fpsId,
      'address': address,
      'profileImage': profileImage,
    };
  }

  static UserType _parseUserType(String type) {
    switch (type) {
      case 'citizen':
        return UserType.citizen;
      case 'fpsDealer':
        return UserType.fpsDealer;
      case 'admin':
        return UserType.admin;
      default:
        return UserType.citizen;
    }
  }
}
