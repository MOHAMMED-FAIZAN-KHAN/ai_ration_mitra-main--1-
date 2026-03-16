import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String text;
  final DateTime timestamp;
  final String? suggestedRoute;
  final List<String> steps;
  final bool isError;
  final bool helpful; // null = not rated, true = helpful, false = not helpful

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.suggestedRoute,
    this.steps = const [],
    this.isError = false,
    this.helpful = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'suggestedRoute': suggestedRoute,
        'steps': steps,
        'isError': isError,
        'helpful': helpful,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        role: json['role'],
        text: json['text'],
        timestamp: DateTime.parse(json['timestamp']),
        suggestedRoute: json['suggestedRoute'],
        steps: List<String>.from(json['steps'] ?? []),
        isError: json['isError'] ?? false,
        helpful: json['helpful'] ?? false,
      );
}

class ChatSession {
  final String id;
  final String userId;
  final UserType? userType;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<ChatMessage> messages;
  final String? topic; // automatic topic detection

  ChatSession({
    required this.id,
    required this.userId,
    this.userType,
    required this.startedAt,
    this.endedAt,
    this.messages = const [],
    this.topic,
  });

  bool get isActive => endedAt == null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userType': userType?.toString(),
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'topic': topic,
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'],
        userId: json['userId'],
        userType: json['userType'] != null
            ? UserType.values.byName(json['userType'].split('.').last)
            : null,
        startedAt: DateTime.parse(json['startedAt']),
        endedAt:
            json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
        messages: List<ChatMessage>.from(
            (json['messages'] ?? []).map((m) => ChatMessage.fromJson(m))),
        topic: json['topic'],
      );
}

class ChatHistoryService {
  static const String _sessionPrefix = 'chat_session_';
  static const String _sessionListKey = 'chat_sessions_list';
  static const String _logsKey = 'chat_logs';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save chat message to current session
  Future<void> saveMessage(
    String sessionId,
    ChatMessage message,
  ) async {
    final session = await getSession(sessionId);
    if (session == null) return;

    final updatedMessages = [...session.messages, message];
    final updatedSession = ChatSession(
      id: session.id,
      userId: session.userId,
      userType: session.userType,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      messages: updatedMessages,
      topic: session.topic,
    );

    await _saveSession(updatedSession);
  }

  /// Create new chat session
  Future<ChatSession> createSession(
    String userId,
    UserType? userType,
  ) async {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final session = ChatSession(
      id: sessionId,
      userId: userId,
      userType: userType,
      startedAt: DateTime.now(),
    );

    await _saveSession(session);

    // Update sessions list
    final sessionsList = await _getSessionsList();
    sessionsList.add(sessionId);
    await _prefs.setStringList(_sessionListKey, sessionsList);

    return session;
  }

  /// Get session by ID
  Future<ChatSession?> getSession(String sessionId) async {
    final json = _prefs.getString('$_sessionPrefix$sessionId');
    if (json == null) return null;
    return ChatSession.fromJson(jsonDecode(json));
  }

  /// Get all sessions for user
  Future<List<ChatSession>> getUserSessions(String userId) async {
    final sessionsList = await _getSessionsList();
    final sessions = <ChatSession>[];

    for (final sessionId in sessionsList) {
      final session = await getSession(sessionId);
      if (session != null && session.userId == userId) {
        sessions.add(session);
      }
    }

    // Sort by date descending
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions;
  }

  /// End current session
  Future<void> endSession(String sessionId) async {
    final session = await getSession(sessionId);
    if (session != null) {
      final endedSession = ChatSession(
        id: session.id,
        userId: session.userId,
        userType: session.userType,
        startedAt: session.startedAt,
        endedAt: DateTime.now(),
        messages: session.messages,
        topic: session.topic,
      );
      await _saveSession(endedSession);
    }
  }

  /// Log chat analytics
  Future<void> logActivity({
    required String userId,
    required String action,
    required String details,
    required DateTime timestamp,
  }) async {
    final logs = _getLogsFromPrefs();
    logs.add({
      'userId': userId,
      'action': action,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    });

    // Keep only last 1000 logs to prevent storage overflow
    if (logs.length > 1000) {
      logs.removeRange(0, logs.length - 1000);
    }

    await _prefs.setString(_logsKey, jsonEncode(logs));
  }

  /// Get user analytics summary
  Future<Map<String, dynamic>> getUserAnalytics(String userId) async {
    final sessions = await getUserSessions(userId);
    final activeSessions = sessions.where((s) => s.isActive).length;
    final totalMessages =
        sessions.fold<int>(0, (sum, s) => sum + s.messages.length);
    final helpfulResponses = sessions.fold<int>(
        0,
        (sum, s) =>
            sum +
            s.messages.where((m) => m.helpful && m.role == 'assistant').length);

    return {
      'totalSessions': sessions.length,
      'activeSessions': activeSessions,
      'totalMessages': totalMessages,
      'averageSessionLength':
          sessions.isNotEmpty ? totalMessages / sessions.length : 0,
      'helpfulResponses': helpfulResponses,
      'lastSession': sessions.isNotEmpty ? sessions.first.startedAt : null,
    };
  }

  /// Clear old sessions (older than specified days)
  Future<void> clearOldSessions(int daysOld) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final sessionsList = await _getSessionsList();
    final updatedList = <String>[];

    for (final sessionId in sessionsList) {
      final session = await getSession(sessionId);
      if (session != null && session.startedAt.isAfter(cutoffDate)) {
        updatedList.add(sessionId);
      } else if (session != null) {
        await _prefs.remove('$_sessionPrefix$sessionId');
      }
    }

    await _prefs.setStringList(_sessionListKey, updatedList);
  }

  /// Save session to preferences
  Future<void> _saveSession(ChatSession session) async {
    await _prefs.setString(
        '$_sessionPrefix${session.id}', jsonEncode(session.toJson()));
  }

  /// Get sessions list from preferences
  Future<List<String>> _getSessionsList() async {
    return _prefs.getStringList(_sessionListKey) ?? [];
  }

  /// Get logs from preferences
  List<Map<String, dynamic>> _getLogsFromPrefs() {
    final json = _prefs.getString(_logsKey);
    if (json == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(json));
  }

  /// Export chat session as JSON
  String exportSession(ChatSession session) {
    return jsonEncode(session.toJson());
  }

  /// Export session as readable text
  String exportSessionAsText(ChatSession session) {
    final buffer = StringBuffer();
    buffer.writeln('=== Chat Session ===');
    buffer.writeln('Session ID: ${session.id}');
    buffer.writeln('Started: ${session.startedAt}');
    if (session.endedAt != null) buffer.writeln('Ended: ${session.endedAt}');
    buffer.writeln(
        'User Type: ${session.userType?.toString().split('.').last ?? "Unknown"}');
    if (session.topic != null) buffer.writeln('Topic: ${session.topic}');
    buffer.writeln('\n=== Messages ===\n');

    for (final msg in session.messages) {
      buffer.writeln(
          '${msg.role.toUpperCase()} (${msg.timestamp.toIso8601String()})');
      buffer.writeln(msg.text);
      if (msg.steps.isNotEmpty) {
        buffer.writeln('Steps: ${msg.steps.join(", ")}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
