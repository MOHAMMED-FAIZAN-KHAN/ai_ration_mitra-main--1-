import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiAIService {
  late GenerativeModel _model;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the Gemini Developer API backend service
      // Create a GenerativeModel instance with a model that supports your use case
      _model = FirebaseAI.googleAI()
          .generativeModel(model: 'gemini-3-flash-preview');
      _isInitialized = true;
      debugPrint('Gemini AI Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Gemini AI Service: $e');
      rethrow;
    }
  }

  bool get isInitialized => _isInitialized;
  GenerativeModel get model => _model;

  /// Generate text content from a text prompt
  Future<String?> generateText(String prompt) async {
    if (!_isInitialized) {
      throw Exception(
          'Gemini AI Service is not initialized. Call initialize() first.');
    }

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text;
      }
      return null;
    } catch (e) {
      debugPrint('Error generating text: $e');
      rethrow;
    }
  }

  /// Stream text content generation for faster interactions
  Future<Stream<String>> generateTextStream(String prompt) async {
    if (!_isInitialized) {
      throw Exception(
          'Gemini AI Service is not initialized. Call initialize() first.');
    }

    try {
      final content = [Content.text(prompt)];
      final responseStream = await _model.generateContentStream(content);

      // Transform the response stream to extract text
      return responseStream
          .map((response) => response.text ?? '')
          .where((text) => text.isNotEmpty);
    } catch (e) {
      debugPrint('Error generating text stream: $e');
      rethrow;
    }
  }

  /// Generate content with multimodal input (text + images/files)
  /// Note: Multimodal implementation depends on the firebase_ai package's
  /// specific API for handling different data types (images, files, etc.)
  Future<String?> generateMultimodalContent(
    String prompt, {
    List<String>? imageFilePaths,
  }) async {
    if (!_isInitialized) {
      throw Exception(
          'Gemini AI Service is not initialized. Call initialize() first.');
    }

    try {
      // For now, process text only
      // To add image support, refer to firebase_ai documentation
      final content = [Content.text(prompt)];

      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text;
      }
      return null;
    } catch (e) {
      debugPrint('Error generating multimodal content: $e');
      rethrow;
    }
  }

  /// Count tokens in a prompt (useful for cost estimation)
  Future<int?> countTokens(String prompt) async {
    if (!_isInitialized) {
      throw Exception(
          'Gemini AI Service is not initialized. Call initialize() first.');
    }

    try {
      final content = [Content.text(prompt)];
      final countResponse = await _model.countTokens(content);
      return countResponse.totalTokens;
    } catch (e) {
      debugPrint('Error counting tokens: $e');
      return null;
    }
  }
}
