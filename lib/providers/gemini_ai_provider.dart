import 'package:flutter/foundation.dart';
import '../services/gemini_ai_service.dart';

class GeminiAIProvider extends ChangeNotifier {
  final GeminiAIService _geminiAIService = GeminiAIService();

  bool _isInitializing = false;
  bool _isInitialized = false;
  String? _error;

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  GeminiAIService get service => _geminiAIService;

  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      await _geminiAIService.initialize();
      _isInitialized = true;
      _error = null;
      debugPrint('GeminiAIProvider: Initialization successful');
    } catch (e) {
      _error = e.toString();
      debugPrint('GeminiAIProvider: Initialization failed - $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Generate text response from a prompt
  Future<String?> generateText(String prompt) async {
    if (!_isInitialized) {
      _error = 'Gemini AI Service is not initialized';
      notifyListeners();
      return null;
    }

    try {
      _error = null;
      notifyListeners();
      return await _geminiAIService.generateText(prompt);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Stream text generation for real-time responses
  Future<Stream<String>?> generateTextStream(String prompt) async {
    if (!_isInitialized) {
      _error = 'Gemini AI Service is not initialized';
      notifyListeners();
      return null;
    }

    try {
      _error = null;
      notifyListeners();
      return await _geminiAIService.generateTextStream(prompt);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Generate multimodal content (text + images/files)
  Future<String?> generateMultimodalContent(
    String prompt, {
    List<String>? imageFilePaths,
  }) async {
    if (!_isInitialized) {
      _error = 'Gemini AI Service is not initialized';
      notifyListeners();
      return null;
    }

    try {
      _error = null;
      notifyListeners();
      return await _geminiAIService.generateMultimodalContent(
        prompt,
        imageFilePaths: imageFilePaths,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Count tokens in a prompt
  Future<int?> countTokens(String prompt) async {
    if (!_isInitialized) {
      _error = 'Gemini AI Service is not initialized';
      notifyListeners();
      return null;
    }

    try {
      _error = null;
      notifyListeners();
      return await _geminiAIService.countTokens(prompt);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
