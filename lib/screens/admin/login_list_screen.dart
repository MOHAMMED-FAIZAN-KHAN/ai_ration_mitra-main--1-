import 'package:flutter/material.dart';

import '../../models/login_record.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/section_header.dart';

class LoginListScreen extends StatefulWidget {
  const LoginListScreen({super.key});

  @override
  State<LoginListScreen> createState() => _LoginListScreenState();
}

class _LoginListScreenState extends State<LoginListScreen> {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Lists'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search by name or UID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionHeader(
                  title: 'Citizen Logins',
                  icon: Icons.person_outline,
                ),
                _buildRecordsSection(userType: 'citizen'),
                const SizedBox(height: 16),
                const SectionHeader(
                  title: 'Dealer Logins',
                  icon: Icons.storefront_outlined,
                ),
                _buildRecordsSection(userType: 'fpsDealer'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsSection({required String userType}) {
    return StreamBuilder<List<LoginRecord>>(
      stream: _firestore.streamLoginRecords(userType: userType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? const <LoginRecord>[];
        final filtered = _filterRecords(records, _query);
        if (filtered.isEmpty) {
          return AppEmptyState(
            icon: userType == 'citizen'
                ? Icons.person_outline
                : Icons.storefront_outlined,
            title: 'No records',
            message: _query.isEmpty
                ? 'New logins will appear here.'
                : 'No results for "$_query".',
          );
        }
        return Column(
          children: filtered.map(_buildRecordCard).toList(),
        );
      },
    );
  }

  List<LoginRecord> _filterRecords(List<LoginRecord> records, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return records;
    }
    return records.where((record) {
      return record.name.toLowerCase().contains(q) ||
          record.uid.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildRecordCard(LoginRecord record) {
    final createdAt = record.createdAt;
    final createdLabel =
        createdAt == null ? 'Unknown date' : _formatDateTime(createdAt);
    final emailLabel =
        (record.email ?? '').trim().isEmpty ? 'No email' : record.email!;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(
                alpha: 0.12,
              ),
          child: Icon(
            record.userType == 'fpsDealer'
                ? Icons.storefront_outlined
                : Icons.person_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          record.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'UID: ${record.uid}\n$emailLabel\nFirst login: $createdLabel',
        ),
        isThreeLine: true,
        trailing: Chip(
          label: Text(
            record.loginType.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}
