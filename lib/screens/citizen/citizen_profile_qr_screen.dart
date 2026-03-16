import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/utils/profile_qr_codec.dart';
import '../../models/user.dart';

class CitizenProfileQrScreen extends StatelessWidget {
  final User user;

  const CitizenProfileQrScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final payload = ProfileQrCodec.buildPayload(user);
    final qrData = jsonEncode(payload);
    final uniqueKey = (payload['uniqueKey'] as String?) ?? '';
    final shortKey = uniqueKey.length > 16
        ? uniqueKey.substring(uniqueKey.length - 16)
        : uniqueKey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile QR'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Show this QR at ration shop for profile verification.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                user.name.trim().isEmpty ? 'Citizen' : user.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                'UID: ${user.uid?.isNotEmpty == true ? user.uid : user.id}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                'Profile Key: $shortKey',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
