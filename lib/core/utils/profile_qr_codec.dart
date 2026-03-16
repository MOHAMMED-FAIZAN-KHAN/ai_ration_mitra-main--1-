import 'dart:convert';

import '../../models/user.dart';

class ScannedProfileData {
  final String role;
  final String userId;
  final String name;
  final String? mobileNumber;
  final String? aadhaarNumber;
  final String? fpsId;
  final String? email;
  final String uniqueKey;

  const ScannedProfileData({
    required this.role,
    required this.userId,
    required this.name,
    required this.uniqueKey,
    this.mobileNumber,
    this.aadhaarNumber,
    this.fpsId,
    this.email,
  });
}

class ProfileQrCodec {
  static const String _schema = 'airation.profile.v1';

  static Map<String, dynamic> buildPayload(User user) {
    return <String, dynamic>{
      'schema': _schema,
      'role': user.type.name,
      'userId': user.id,
      'name': user.name,
      'mobileNumber': user.mobileNumber,
      'aadhaarNumber': user.aadhaarNumber,
      'fpsId': user.fpsId,
      'email': user.email,
      'uniqueKey': _uniqueKey(user),
    };
  }

  static ScannedProfileData? parse(String rawValue) {
    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final schema = decoded['schema'] as String? ?? '';
      if (schema != _schema) {
        return null;
      }

      final role = (decoded['role'] as String? ?? '').trim();
      final userId = (decoded['userId'] as String? ?? '').trim();
      final name = (decoded['name'] as String? ?? '').trim();
      final uniqueKey = (decoded['uniqueKey'] as String? ?? '').trim();
      if (role.isEmpty || userId.isEmpty || name.isEmpty || uniqueKey.isEmpty) {
        return null;
      }

      return ScannedProfileData(
        role: role,
        userId: userId,
        name: name,
        uniqueKey: uniqueKey,
        mobileNumber: (decoded['mobileNumber'] as String?)?.trim(),
        aadhaarNumber: (decoded['aadhaarNumber'] as String?)?.trim(),
        fpsId: (decoded['fpsId'] as String?)?.trim(),
        email: (decoded['email'] as String?)?.trim(),
      );
    } catch (_) {
      return null;
    }
  }

  static String _uniqueKey(User user) {
    final seed = <String>[
      user.type.name,
      user.id,
      user.uid ?? '',
      user.fpsId ?? '',
      user.mobileNumber ?? '',
      user.aadhaarNumber ?? '',
      user.name,
    ].join('|');

    return base64UrlEncode(utf8.encode(seed));
  }
}
