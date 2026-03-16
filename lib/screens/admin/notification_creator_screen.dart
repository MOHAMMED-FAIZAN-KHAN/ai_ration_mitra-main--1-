import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class NotificationCreatorScreen extends StatefulWidget {
  const NotificationCreatorScreen({super.key});

  @override
  State<NotificationCreatorScreen> createState() =>
      _NotificationCreatorScreenState();
}

class _NotificationCreatorScreenState extends State<NotificationCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  NotificationAudience _selectedAudience = NotificationAudience.all;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Creator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Dynamic Notification',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                maxLength: 240,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Message is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<NotificationAudience>(
                initialValue: _selectedAudience,
                decoration: const InputDecoration(
                  labelText: 'Send To',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: NotificationAudience.all,
                    child: Text('Citizen + Dealer'),
                  ),
                  DropdownMenuItem(
                    value: NotificationAudience.citizen,
                    child: Text('Citizen Only'),
                  ),
                  DropdownMenuItem(
                    value: NotificationAudience.dealer,
                    child: Text('Dealer Only'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedAudience = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: notificationProvider.isLoading ? null : _submit,
                  icon: notificationProvider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Send Notification'),
                ),
              ),
              if (notificationProvider.error != null) ...[
                const SizedBox(height: 10),
                Text(
                  notificationProvider.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    notificationProvider.clearError();
    final ok = await notificationProvider.createNotification(
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      audience: _selectedAudience,
      createdBy: auth.currentUser?.name,
    );

    if (!mounted) {
      return;
    }

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notificationProvider.error ?? 'Failed to create'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final sentAudience = _selectedAudience;
    _titleController.clear();
    _messageController.clear();
    setState(() => _selectedAudience = NotificationAudience.all);
    final warning = notificationProvider.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          warning == null
              ? 'Notification sent to ${_audienceLabel(sentAudience)}'
              : 'Notification sent to ${_audienceLabel(sentAudience)} (local sync)',
        ),
        backgroundColor: warning == null ? Colors.green : Colors.orange,
      ),
    );
  }

  String _audienceLabel(NotificationAudience audience) {
    switch (audience) {
      case NotificationAudience.citizen:
        return 'Citizen';
      case NotificationAudience.dealer:
        return 'Dealer';
      case NotificationAudience.all:
        return 'Citizen + Dealer';
    }
  }
}
