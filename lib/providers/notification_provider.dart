import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _readStateKey = 'notification_read_ids_v1';
  static const String _localCacheKey = 'notification_local_cache_v1';

  NotificationProvider({
    FirebaseFirestore? firestore,
    bool enableFirebase = true,
  })  : _enableFirebase = enableFirebase,
        _firestore =
            enableFirebase ? (firestore ?? FirebaseFirestore.instance) : null {
    _initialize();
  }

  final bool _enableFirebase;
  final FirebaseFirestore? _firestore;

  bool _isLoading = false;
  String? _error;
  final List<AppNotification> _notifications = <AppNotification>[];
  final List<AppNotification> _localFallbackNotifications = <AppNotification>[];
  final Set<String> _readNotificationIds = <String>{};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _notificationSubscription;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  Future<void> _initialize() async {
    await _loadReadState();
    await _loadLocalFallbackCache();
    _rebuildFromLocalFallback();
    if (_enableFirebase && _firestore != null) {
      _startRealtimeSync();
      await loadNotifications();
    } else {
      notifyListeners();
    }
  }

  Future<void> loadNotifications() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (!_enableFirebase || _firestore == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final snapshot = await _firestore!
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();

      _setNotificationsFromSnapshot(snapshot.docs);
    } catch (e) {
      _error = 'Failed to load notifications: $e';
      _rebuildFromLocalFallback();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createNotification({
    required String title,
    required String message,
    required NotificationAudience audience,
    String? createdBy,
  }) async {
    final normalizedTitle = title.trim();
    final normalizedMessage = message.trim();
    if (normalizedTitle.isEmpty || normalizedMessage.isEmpty) {
      _error = 'Title and message are required';
      notifyListeners();
      return false;
    }

    final now = DateTime.now();
    final fallbackNotification = AppNotification(
      id: 'local_${now.microsecondsSinceEpoch}',
      title: normalizedTitle,
      message: normalizedMessage,
      audience: audience,
      createdAt: now,
      createdBy: createdBy,
      isRead: false,
    );

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_enableFirebase && _firestore != null) {
        try {
          final ref = await _firestore!.collection('notifications').add({
            'title': normalizedTitle,
            'message': normalizedMessage,
            'audience': _audienceKey(audience),
            'createdBy': createdBy,
            'createdAt': FieldValue.serverTimestamp(),
            'createdAtClient': now.millisecondsSinceEpoch,
          });
          final cloudBackedNotification = fallbackNotification.copyWith(id: ref.id);
          _upsertLocalFallback(cloudBackedNotification);
          _upsertInMemory(cloudBackedNotification);
        } catch (e) {
          // Keep app functional even when cloud write fails.
          _upsertLocalFallback(fallbackNotification);
          _upsertInMemory(fallbackNotification);
          _error = 'Cloud sync unavailable. Notification sent locally.';
        }
      } else {
        _upsertLocalFallback(fallbackNotification);
        _upsertInMemory(fallbackNotification);
      }

      await _persistLocalFallbackCache();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create notification: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<AppNotification> notificationsForAudience(NotificationAudience audience) {
    return _notifications.where((item) {
      return item.audience == NotificationAudience.all || item.audience == audience;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  bool isRead(String id) {
    return _readNotificationIds.contains(id);
  }

  Future<void> markAsRead(String id) async {
    if (id.trim().isEmpty || _readNotificationIds.contains(id)) {
      return;
    }
    _readNotificationIds.add(id);
    _applyReadState();
    await _persistReadState();
    notifyListeners();
  }

  Future<void> markAllAsReadForAudience(NotificationAudience audience) async {
    var changed = false;
    for (final item in notificationsForAudience(audience)) {
      if (_readNotificationIds.add(item.id)) {
        changed = true;
      }
    }
    if (!changed) {
      return;
    }
    _applyReadState();
    await _persistReadState();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _audienceKey(NotificationAudience audience) {
    switch (audience) {
      case NotificationAudience.citizen:
        return 'citizen';
      case NotificationAudience.dealer:
        return 'dealer';
      case NotificationAudience.all:
        return 'all';
    }
  }

  void _startRealtimeSync() {
    if (_firestore == null) {
      return;
    }

    _notificationSubscription?.cancel();
    _notificationSubscription = _firestore!
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .listen(
      (snapshot) {
        _setNotificationsFromSnapshot(snapshot.docs);
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to sync notifications: $error';
        _rebuildFromLocalFallback();
        notifyListeners();
      },
    );
  }

  void _setNotificationsFromSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final remote = docs
        .map(_parseNotification)
        .where((item) => item.title.isNotEmpty && item.message.isNotEmpty)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final remoteIds = remote.map((item) => item.id).toSet();
    final fallbackOnly = _localFallbackNotifications
        .where((item) => !remoteIds.contains(item.id))
        .toList();
    final parsed = <AppNotification>[
      ...remote,
      ...fallbackOnly,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _notifications
      ..clear()
      ..addAll(parsed);
    _applyReadState();
  }

  AppNotification _parseNotification(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt = data['createdAt'];
    final createdAtClient = data['createdAtClient'];
    DateTime when = DateTime.now();
    if (createdAt is Timestamp) {
      when = createdAt.toDate();
    } else if (createdAtClient is int) {
      when = DateTime.fromMillisecondsSinceEpoch(createdAtClient);
    }
    return AppNotification(
      id: doc.id,
      title: (data['title'] as String?)?.trim() ?? '',
      message: (data['message'] as String?)?.trim() ?? '',
      audience: AppNotification.parseAudience(data['audience'] as String?),
      createdAt: when,
      createdBy: data['createdBy'] as String?,
      isRead: _readNotificationIds.contains(doc.id),
    );
  }

  void _applyReadState() {
    for (var i = 0; i < _notifications.length; i++) {
      final item = _notifications[i];
      final shouldBeRead = _readNotificationIds.contains(item.id);
      if (item.isRead != shouldBeRead) {
        _notifications[i] = item.copyWith(isRead: shouldBeRead);
      }
    }
  }

  void _upsertInMemory(AppNotification notification) {
    _notifications.removeWhere((item) => item.id == notification.id);
    _notifications.insert(0, notification.copyWith(
      isRead: _readNotificationIds.contains(notification.id),
    ));
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _upsertLocalFallback(AppNotification notification) {
    _localFallbackNotifications.removeWhere((item) => item.id == notification.id);
    _localFallbackNotifications.insert(0, notification.copyWith(isRead: false));
    _localFallbackNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _rebuildFromLocalFallback() {
    _notifications
      ..clear()
      ..addAll(_localFallbackNotifications);
    _applyReadState();
  }

  Future<void> _loadReadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_readStateKey) ?? const <String>[];
      _readNotificationIds
        ..clear()
        ..addAll(ids);
    } catch (_) {
      _readNotificationIds.clear();
    }
  }

  Future<void> _persistReadState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readStateKey, _readNotificationIds.toList());
  }

  Future<void> _loadLocalFallbackCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localCacheKey);
      if (raw == null || raw.trim().isEmpty) {
        _localFallbackNotifications.clear();
        return;
      }
      final decoded = jsonDecode(raw) as List<dynamic>;
      _localFallbackNotifications
        ..clear()
        ..addAll(
          decoded
              .whereType<Map<String, dynamic>>()
              .map(_fromLocalCache)
              .where((item) => item.title.isNotEmpty && item.message.isNotEmpty),
        );
      _localFallbackNotifications
          .sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      _localFallbackNotifications.clear();
    }
  }

  Future<void> _persistLocalFallbackCache() async {
    final prefs = await SharedPreferences.getInstance();
    final payload =
        _localFallbackNotifications.map(_toLocalCache).toList(growable: false);
    await prefs.setString(_localCacheKey, jsonEncode(payload));
  }

  Map<String, dynamic> _toLocalCache(AppNotification item) {
    return <String, dynamic>{
      'id': item.id,
      'title': item.title,
      'message': item.message,
      'audience': item.audienceKey,
      'createdAt': item.createdAt.toIso8601String(),
      'createdBy': item.createdBy,
    };
  }

  AppNotification _fromLocalCache(Map<String, dynamic> raw) {
    return AppNotification(
      id: (raw['id'] as String?) ?? '',
      title: (raw['title'] as String?)?.trim() ?? '',
      message: (raw['message'] as String?)?.trim() ?? '',
      audience: AppNotification.parseAudience(raw['audience'] as String?),
      createdAt: DateTime.tryParse((raw['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      createdBy: raw['createdBy'] as String?,
      isRead: false,
    );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
