import 'package:cloud_firestore/cloud_firestore.dart';

class LoginRecord {
  final String id;
  final String name;
  final String uid;
  final String? email;
  final String loginType;
  final String userType;
  final DateTime? createdAt;

  const LoginRecord({
    required this.id,
    required this.name,
    required this.uid,
    required this.email,
    required this.loginType,
    required this.userType,
    required this.createdAt,
  });

  factory LoginRecord.fromJson(Map<String, dynamic> json) {
    return LoginRecord(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      uid: (json['uid'] ?? '').toString(),
      email: (json['email'] ?? '')?.toString(),
      loginType: (json['loginType'] ?? '').toString(),
      userType: (json['userType'] ?? '').toString(),
      createdAt: _parseCreatedAt(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'uid': uid,
      'email': email,
      'loginType': loginType,
      'userType': userType,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static DateTime? _parseCreatedAt(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
