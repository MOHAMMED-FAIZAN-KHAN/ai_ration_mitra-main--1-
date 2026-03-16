import 'package:flutter/foundation.dart';
import '../services/chat_history_service.dart';
import '../models/user.dart';

class ChatHistoryProvider extends ChangeNotifier {
  final ChatHistoryService _historyService = ChatHistoryService();

  String? _currentSessionId;
  ChatSession? _currentSession;
  List<ChatSession> _userSessions = [];
  Map<String, dynamic> _userAnalytics = {};
  bool _isLoading = false;

  String? get currentSessionId => _currentSessionId;
  ChatSession? get currentSession => _currentSession;
  List<ChatSession> get userSessions => _userSessions;
  Map<String, dynamic> get userAnalytics => _userAnalytics;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    try {
      await _historyService.initialize();
    } catch (e) {
      debugPrint('Error initializing ChatHistoryProvider: $e');
    }
  }

  /// Start a new chat session
  Future<String> startNewSession(String userId, UserType? userType) async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = await _historyService.createSession(userId, userType);
      _currentSessionId = session.id;
      _currentSession = session;

      await _loadUserSessions(userId);
      await _logActivity(userId, 'session_started', 'New chat session started');

      _isLoading = false;
      notifyListeners();
      return session.id;
    } catch (e) {
      _isLoading = false;
      debugPrint('Error starting new session: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Load existing session
  Future<void> loadSession(String sessionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = await _historyService.getSession(sessionId);
      if (session != null) {
        _currentSessionId = sessionId;
        _currentSession = session;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint('Error loading session: $e');
      notifyListeners();
    }
  }

  /// Add message to current session
  Future<void> addMessageToSession(ChatMessage message) async {
    if (_currentSessionId == null) return;

    try {
      await _historyService.saveMessage(_currentSessionId!, message);
      await loadSession(_currentSessionId!); // Reload to update UI
    } catch (e) {
      debugPrint('Error adding message to session: $e');
    }
  }

  /// End current session
  Future<void> endCurrentSession(String userId) async {
    if (_currentSessionId == null) return;

    try {
      await _historyService.endSession(_currentSessionId!);
      await _logActivity(userId, 'session_ended', 'Chat session ended');
      _currentSessionId = null;
      _currentSession = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error ending session: $e');
    }
  }

  /// Load all sessions for user
  Future<void> _loadUserSessions(String userId) async {
    try {
      _userSessions = await _historyService.getUserSessions(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user sessions: $e');
    }
  }

  /// Load user analytics
  Future<void> loadUserAnalytics(String userId) async {
    try {
      _userAnalytics = await _historyService.getUserAnalytics(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user analytics: $e');
    }
  }

  /// Mark message as helpful
  Future<void> markMessageAsHelpful(String messageId, bool helpful) async {
    if (_currentSession == null) return;

    try {
      // This would update the current session
      // Implementation depends on your persistence layer
      await _logActivity(
        _currentSession!.userId,
        'message_feedback',
        'User marked message as ${helpful ? "helpful" : "not helpful"}',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking message as helpful: $e');
    }
  }

  /// Clear old sessions
  Future<void> clearOldSessions(int daysOld) async {
    try {
      await _historyService.clearOldSessions(daysOld);
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing old sessions: $e');
    }
  }

  /// Export session as JSON
  String exportCurrentSessionAsJson() {
    if (_currentSession == null) return '';
    return _historyService.exportSession(_currentSession!);
  }

  /// Export session as text
  String exportCurrentSessionAsText() {
    if (_currentSession == null) return '';
    return _historyService.exportSessionAsText(_currentSession!);
  }

  /// Log activity for analytics
  Future<void> _logActivity(
      String userId, String action, String details) async {
    try {
      await _historyService.logActivity(
        userId: userId,
        action: action,
        details: details,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error logging activity: $e');
    }
  }
}
