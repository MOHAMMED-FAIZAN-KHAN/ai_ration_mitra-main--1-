import 'package:flutter/foundation.dart';
import '../services/gemini_ai_assistant_service.dart';
import '../models/user.dart';

class GeminiAssistantProvider extends ChangeNotifier {
  final GeminiAIAssistantService _assistantService = GeminiAIAssistantService();

  bool _isInitializing = false;
  bool _isInitialized = false;
  String? _error;
  bool _isLoadingResponse = false;

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  bool get isLoadingResponse => _isLoadingResponse;
  GeminiAIAssistantService get service => _assistantService;

  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      await _assistantService.initialize();
      _isInitialized = true;
      _error = null;
      debugPrint('GeminiAssistantProvider: Initialization successful');
    } catch (e) {
      _error = e.toString();
      debugPrint('GeminiAssistantProvider: Initialization failed - $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Get AI response for user message
  Future<GeminiAssistantReply?> getResponse(
    String message, {
    UserType? userType,
    String? userName,
    String? userId,
  }) async {
    if (!_isInitialized) {
      _error = 'Assistant not initialized';
      notifyListeners();
      return null;
    }

    _isLoadingResponse = true;
    _error = null;
    notifyListeners();

    try {
      final reply = await _assistantService.getAssistantResponse(
        message,
        userType: userType,
        userName: userName,
        userId: userId,
      );
      _isLoadingResponse = false;
      notifyListeners();
      return reply;
    } catch (e) {
      _error = e.toString();
      _isLoadingResponse = false;
      notifyListeners();
      return null;
    }
  }

  /// Stream response for real-time display
  Future<Stream<String>?> getResponseStream(
    String message, {
    UserType? userType,
    String? userName,
  }) async {
    if (!_isInitialized) {
      _error = 'Assistant not initialized';
      notifyListeners();
      return null;
    }

    _isLoadingResponse = true;
    _error = null;
    notifyListeners();

    try {
      final stream = await _assistantService.getAssistantResponseStream(
        message,
        userType: userType,
        userName: userName,
      );
      // Don't change isLoadingResponse here as the stream is still running
      return stream;
    } catch (e) {
      _error = e.toString();
      _isLoadingResponse = false;
      notifyListeners();
      return null;
    }
  }

  /// Troubleshoot specific issue
  Future<String?> troubleshootIssue(
    String issue, {
    String? featureName,
    UserType? userType,
  }) async {
    if (!_isInitialized) {
      _error = 'Assistant not initialized';
      notifyListeners();
      return null;
    }

    _isLoadingResponse = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _assistantService.troubleshootIssue(
        issue,
        featureName: featureName,
        userType: userType,
      );
      _isLoadingResponse = false;
      notifyListeners();
      return response;
    } catch (e) {
      _error = e.toString();
      _isLoadingResponse = false;
      notifyListeners();
      return null;
    }
  }

  /// Generate FAQ
  Future<String?> generateFAQ(String topic) async {
    if (!_isInitialized) {
      _error = 'Assistant not initialized';
      notifyListeners();
      return null;
    }

    _isLoadingResponse = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _assistantService.generateFAQ(topic);
      _isLoadingResponse = false;
      notifyListeners();
      return response;
    } catch (e) {
      _error = e.toString();
      _isLoadingResponse = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
