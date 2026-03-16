import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/utils/profile_qr_codec.dart';
import '../../models/user.dart';

class DealerProfileQrScreen extends StatelessWidget {
  final User user;

  const DealerProfileQrScreen({super.key, required this.user});

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
        title: const Text('Dealer Profile QR'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Show this QR for FPS dealer profile verification.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              Text(
                user.name.trim().isEmpty ? 'FPS Dealer' : user.name.trim(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Shop ID: ${user.fpsId?.isNotEmpty == true ? user.fpsId : user.id}',
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
