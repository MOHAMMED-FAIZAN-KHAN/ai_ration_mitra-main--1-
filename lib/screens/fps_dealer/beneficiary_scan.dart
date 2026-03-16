import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/utils/profile_qr_codec.dart';
import '../../models/fps_operations.dart';
import '../../providers/fps_operations_provider.dart';
import '../../data/citizen_distribution_data.dart';
import '../../widgets/app_empty_state.dart';

class BeneficiaryScan extends StatefulWidget {
  const BeneficiaryScan({super.key});

  @override
  State<BeneficiaryScan> createState() => _BeneficiaryScanState();
}

class _BeneficiaryScanState extends State<BeneficiaryScan> {
  final TextEditingController _cardController = TextEditingController();
  BeneficiaryRecord? _beneficiary;
  ScannedProfileData? _scannedProfile;

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ops = context.watch<FPSOperationsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beneficiary Verification'),
      ),
      body: ops.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    'Use card number or scan citizen QR to identify user.',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _cardController,
                  decoration: InputDecoration(
                    hintText: 'Enter card number (e.g. RC1001)',
                    prefixIcon: const Icon(Icons.credit_card),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _verify(ops),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _verify(ops),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _scanQrCode(ops),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR Code'),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: ['RC1001', 'RC1002', 'RC1003'].map((card) {
                    return ActionChip(
                      label: Text(card),
                      onPressed: () {
                        _cardController.text = card;
                        _verify(ops);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                if (_scannedProfile != null) ...[
                  _scannedProfileCard(_scannedProfile!),
                  const SizedBox(height: 12),
                ],
                if (_beneficiary == null)
                  const AppEmptyState(
                    icon: Icons.person_search,
                    title: 'No beneficiary verified',
                    message: 'Search by card number or scan a QR to verify.',
                  )
                else
                  _beneficiaryCard(context, _beneficiary!, ops),
              ],
            ),
    );
  }

  void _verify(FPSOperationsProvider ops) {
    final match = ops.findBeneficiary(_cardController.text);
    setState(() {
      _beneficiary = match;
    });
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No beneficiary found for provided card/name'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _scanQrCode(FPSOperationsProvider ops) async {
    final raw = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _QrScannerScreen()),
    );

    if (!mounted || raw == null || raw.trim().isEmpty) {
      return;
    }

    final parsed = ProfileQrCodec.parse(raw);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR format'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    BeneficiaryRecord? beneficiary;
    if (parsed.role == 'citizen') {
      beneficiary = ops.findBeneficiary(parsed.name);
      if (beneficiary != null) {
        _cardController.text = beneficiary.cardNumber;
      }
    }

    setState(() {
      _scannedProfile = parsed;
      _beneficiary = beneficiary ?? _beneficiary;
    });

    final roleLabel = parsed.role == 'citizen'
        ? 'Citizen'
        : (parsed.role == 'fpsDealer' ? 'FPS Dealer' : parsed.role);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          beneficiary != null
              ? '$roleLabel identified: ${parsed.name}'
              : '$roleLabel identified from QR: ${parsed.name}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _scannedProfileCard(ScannedProfileData profile) {
    String mask(String? value) {
      final text = (value ?? '').trim();
      if (text.length <= 4) {
        return text;
      }
      return '****${text.substring(text.length - 4)}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'QR User Identified',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Name: ${profile.name}'),
            Text('Role: ${profile.role}'),
            Text('User ID: ${profile.userId}'),
            if ((profile.mobileNumber ?? '').isNotEmpty)
              Text('Mobile: ${mask(profile.mobileNumber)}'),
            if ((profile.aadhaarNumber ?? '').isNotEmpty)
              Text('Aadhaar: ${mask(profile.aadhaarNumber)}'),
          ],
        ),
      ),
    );
  }

  Widget _beneficiaryCard(
    BuildContext context,
    BeneficiaryRecord beneficiary,
    FPSOperationsProvider ops,
  ) {
    final eligible = beneficiary.isEligibleToday;
    final history = ops.distributionHistoryForCard(beneficiary.cardNumber);
    final lastRecord = history.isNotEmpty ? history.first : null;
    final previousMonthRecord = _previousMonthRecord(history);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: eligible
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  child: Icon(
                    eligible ? Icons.verified_user : Icons.schedule,
                    color: eligible ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        beneficiary.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Card: ${beneficiary.cardNumber} | ${beneficiary.category}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Family Members: ${beneficiary.familyMembers}'),
            if (_scannedProfile != null) ...[
              const SizedBox(height: 4),
              if ((_scannedProfile?.mobileNumber ?? '').isNotEmpty)
                Text('Mobile: ${_mask(_scannedProfile?.mobileNumber)}'),
              if ((_scannedProfile?.aadhaarNumber ?? '').isNotEmpty)
                Text('Aadhaar: ${_mask(_scannedProfile?.aadhaarNumber)}'),
            ],
            const SizedBox(height: 4),
            Text(
              eligible
                  ? 'Eligible for distribution now'
                  : 'Next eligible date: ${_formatDate(beneficiary.nextEligibleDate)}',
              style: TextStyle(
                color: eligible ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Last Distribution:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (lastRecord == null)
              const Text('No distribution record found')
            else
              Text(
                '${_formatDate(lastRecord.date)} • ${lastRecord.shopName}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            if (lastRecord != null)
              ...lastRecord.items.map(
                (item) => Text('- ${item.name}: ${item.quantity} ${item.unit}'),
              ),
            const SizedBox(height: 10),
            const Text('Previous Month:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (previousMonthRecord == null)
              const Text('No distribution recorded last month')
            else
              Text(
                '${_formatDate(previousMonthRecord.date)} • ${previousMonthRecord.shopName}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            const SizedBox(height: 10),
            const Text('Pending Items:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (beneficiary.pendingItems.isEmpty)
              const Text('No pending items')
            else
              ...beneficiary.pendingItems.map((item) => Text('- $item')),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: eligible
                    ? () async {
                        final success = await ops
                            .distributeToBeneficiary(beneficiary.cardNumber);
                        if (success) {
                          _verify(ops);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Distribution confirmed successfully'
                                  : (ops.error ?? 'Unable to distribute'),
                            ),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirm Distribution'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickNextDate(context, ops, beneficiary),
                icon: const Icon(Icons.event_available),
                label: const Text('Set Next Ration Date'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  DistributionRecord? _previousMonthRecord(List<DistributionRecord> records) {
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);
    for (final record in records) {
      if (record.date.year == prev.year && record.date.month == prev.month) {
        return record;
      }
    }
    return null;
  }

  String _mask(String? value) {
    final text = (value ?? '').trim();
    if (text.length <= 4) {
      return text;
    }
    return '****${text.substring(text.length - 4)}';
  }

  Future<void> _pickNextDate(
    BuildContext context,
    FPSOperationsProvider ops,
    BeneficiaryRecord beneficiary,
  ) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: beneficiary.nextEligibleDate,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 2, 12, 31),
    );
    if (picked == null) {
      return;
    }
    final success = await ops.updateUpcomingDistributionDate(
      cardNumber: beneficiary.cardNumber,
      nextDate: picked,
    );
    if (success) {
      _verify(ops);
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Upcoming ration date updated'
              : (ops.error ?? 'Unable to update date'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}

class _QrScannerScreen extends StatefulWidget {
  const _QrScannerScreen();

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Beneficiary QR')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_handled) {
                return;
              }
              final codes = capture.barcodes;
              if (codes.isEmpty) {
                return;
              }
              final value = codes.first.rawValue;
              if (value == null || value.trim().isEmpty) {
                return;
              }
              _handled = true;
              Navigator.pop(context, value);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Place QR inside camera frame',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
