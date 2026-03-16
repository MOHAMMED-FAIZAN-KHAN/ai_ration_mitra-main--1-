import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';

class SupportMessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submit({
    required String message,
    User? user,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _firestore.collection('support_messages').add(<String, dynamic>{
      'message': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': user?.id,
      'userName': user?.name,
      'userType': user?.type.name,
      'email': user?.email,
    });
  }
}
